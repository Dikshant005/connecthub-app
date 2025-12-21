import 'package:get/get.dart' hide navigator; 
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart'; // Import API

class CallController extends GetxController {
  final SocketService _socketService = Get.find();
  final ApiService _api = Get.find(); // Find API Service
  final box = GetStorage();

  // Renderers
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  
  late String roomId;
  late bool isHost; 
  late String myUserId;
  String? remoteUserId;

  var isRemoteConnected = false.obs;
  var isLocalReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    var args = Get.arguments;
    roomId = args['roomId'];
    isHost = args['isHost'];
    myUserId = box.read('userId') ?? "Unknown";

    _initRenderers();
    _setupSocketListeners();
  }

  // --- INITIALIZATION ---
  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user', 'width': 640, 'height': 480}
    });

    localRenderer.srcObject = _localStream;
    isLocalReady.value = true;
    
    _socketService.joinRoom(roomId, myUserId);
  }

  // --- SOCKET LISTENERS ---
  void _setupSocketListeners() {
    void onUserJoined(userId) {
       print("👋 User Connected: $userId");
       remoteUserId = userId; 
       if(isHost) _createOffer(); 
    }

    _socketService.socket?.on('user-connected', onUserJoined);
    _socketService.socket?.on('user-joined', (data) {
       if (data is Map && data.containsKey('userId')) {
         if (data['userId'] != myUserId) onUserJoined(data['userId']);
       }
    });

    _socketService.socket?.on('signal', (args) async {
      String senderId;
      Map<String, dynamic> data;
      if (args is List) { senderId = args[0]; data = args[1]; } else { return; }

      remoteUserId = senderId;
      String type = data['type'];

      if (type == 'offer') {
        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(data['sdp'], type));
        await _createAnswer();
      } else if (type == 'answer') {
        if (_peerConnection != null) {
          await _peerConnection!.setRemoteDescription(RTCSessionDescription(data['sdp'], type));
        }
      }
    });

    _socketService.socket?.on('ice-candidate', (data) {
      if (_peerConnection != null) {
        _peerConnection!.addCandidate(RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        ));
      }
    });
    
    _socketService.socket?.on('user-disconnected', (userId) => _closePeerConnection());
    _socketService.socket?.on('user-left', (data) => _closePeerConnection());
  }

  // --- WEBRTC CORE ---
  Future<void> _createPeerConnection() async {
    Map<String, dynamic> config = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (remoteUserId != null) {
        _socketService.socket?.emit('ice-candidate', {
          'toUserId': remoteUserId,
          'fromUserId': myUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex
          }
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        isRemoteConnected.value = true;
      }
    };
  }

  Future<void> _createOffer() async {
    await _createPeerConnection();
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    if (remoteUserId != null) {
      _socketService.socket?.emit('signal', [remoteUserId, {'type': 'offer', 'sdp': offer.sdp}]);
    }
  }

  Future<void> _createAnswer() async {
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    if (remoteUserId != null) {
      _socketService.socket?.emit('signal', [remoteUserId, {'type': 'answer', 'sdp': answer.sdp}]);
    }
  }
  
  void _closePeerConnection() {
    _peerConnection?.close();
    _peerConnection = null;
    isRemoteConnected.value = false;
  }

  // --- LEAVE LOGIC (The New Part) ---
  void leaveCall() async {
    print("📞 Leaving call...");
    
    // 1. Clean up local media
    _closePeerConnection();
    localRenderer.srcObject = null;
    
    // 2. Notify Backend (Database)
    try {
      await _api.post('/meetings/$roomId/leave', {}); 
    } catch (e) {
      print("Error leaving room API: $e");
    }

    // 3. Go Back
    Get.back();
  }

  @override
  void onClose() {
    _socketService.socket?.off('user-connected');
    _socketService.socket?.off('signal');
    _socketService.socket?.off('ice-candidate');
    localRenderer.dispose();
    remoteRenderer.dispose();
    _localStream?.dispose();
    _closePeerConnection();
    super.onClose();
  }
}