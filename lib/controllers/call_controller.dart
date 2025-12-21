import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide navigator;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class CallController extends GetxController {
  final SocketService _socketService = Get.find();
  final ApiService _api = Get.find();
  final box = GetStorage();

  // WebRTC Renderers
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  late String roomId;
  late bool isHost;
  late String myUserId;
  String? remoteUserId;

  final isRemoteConnected = false.obs;
  final isLocalReady = false.obs;

  // to prevent actions after disposal
  bool _isDisposed = false;

  // ICE Candidate Queue to hold candidates before peer connection is ready
  final List<RTCIceCandidate> _candidateQueue = [];
  bool _isPcReady = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    roomId = args['roomId'];
    isHost = args['isHost'];
    myUserId = box.read('userId') ?? "Unknown";

    // reconnect socket if disconnected
    if (_socketService.socket.disconnected) {
      print("Reconnecting socket...");
      _socketService.socket.connect();
    }

    _initRenderers();
    _setupSocketListeners();
  }

  // socket listener to handle signaling and room events
  void _setupSocketListeners() {
    if (_isDisposed) return;

    // user connected 
    _socketService.socket.on('user-connected', (userId) async {
      if (_isDisposed || userId == myUserId) return;
      print("👋 User Connected: $userId");

      if (remoteUserId != null) {
         _softResetPeer(); 
      }

      remoteUserId = userId;

      if (isHost) {
        await Future.delayed(const Duration(seconds: 1));
        if (_isDisposed) return;
        print("Host initiating call to $userId...");
        await _createPeerConnection();
        await _createOffer();
      }
    });

    // paricipant left (soft exit)
    void handleUserLeft(data) {
       if (_isDisposed) return;
       print("Remote user left");
       _softResetPeer();
       Get.snackbar("Info", "Participant left the meeting");
    }

    _socketService.socket.on('user-disconnected', handleUserLeft);
    _socketService.socket.on('user-left', handleUserLeft);

    // meeting ended (Hard Exit)
    _socketService.socket.on('meeting-ended', (data) {
      if (_isDisposed) return;
      final room = data['roomId'] ?? roomId;
      final endedBy = data['endedBy'] ?? 'host';

      print("🛑 Meeting ended by $endedBy, room: $room");

      if (!isHost) {
        Get.snackbar("Meeting Ended", data['message'] ?? "Host ended the meeting");
      }

      _leaveAndNavigate();
    });

    // signaling data
    _socketService.socket.on('signal', (args) async {
      if (_isDisposed) return;
      if (args is! List || args.length < 2) return;

      final senderId = args[0];
      final data = args[1];

      if (senderId == myUserId) return;
      remoteUserId = senderId;

      var type = data['type'];
      var sdp = data['sdp'];

      if (type == 'offer') {
        print("Received Offer");
        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
        await _createAnswer();
        _processCandidateQueue();
      } 
      else if (type == 'answer' && _peerConnection != null) {
        print("Received Answer");
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
        _processCandidateQueue();
      }
      else if (type == 'force-leave') {
        print("Force leave received from host");
        Get.snackbar("Meeting Ended", data['message'] ?? "Host ended the meeting");
        _leaveAndNavigate();
      }
    });

    // ice-candidate received
    _socketService.socket.on('ice-candidate', (data) {
      if (_isDisposed) return;

      var candidateMap = data['candidate']; 
      var candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );

      if (_peerConnection == null || !_isPcReady) {
        _candidateQueue.add(candidate);
      } else {
        _peerConnection!.addCandidate(candidate);
      }
    });
  }

  // clean up peer connection for new calls
  void _softResetPeer() {
    if (_isDisposed) return;
    print("Soft Resetting Connection...");

    _peerConnection?.close();
    _peerConnection = null;
    _isPcReady = false;
    _candidateQueue.clear();

    remoteUserId = null;
    isRemoteConnected.value = false;

    try {
      remoteRenderer.srcObject = null;
    } catch (_) {}
  }

  void _leaveAndNavigate() {
    _socketService.socket.off('meeting-ended');
    _socketService.socket.off('user-connected');
    _socketService.socket.off('signal');
    _socketService.socket.off('ice-candidate');
    _socketService.socket.off('user-disconnected');
    _socketService.socket.off('user-left');

    _socketService.socket.disconnect();

    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    _isDisposed = true;
    print("Destroying CallController...");

    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    localRenderer.dispose();
    remoteRenderer.dispose();

    super.onClose();
  }

  void _leaveMeeting() async {
    Get.back(); 
    try { await _api.leaveMeeting(roomId); } catch (_) {}
    _leaveAndNavigate();
  }

  void _endMeetingForAll() async {
    Get.back(); 

    if (remoteUserId != null) {
      _socketService.socket.emit('signal', [
        remoteUserId,
        {'type': 'force-leave', 'message': 'Host ended the meeting'}
      ]);
    }

    try { await _api.endMeeting(roomId); } catch (_) {}
    _leaveAndNavigate();
  }

  // create and configure peer connection
  Future<void> _createPeerConnection() async {
    if (_isDisposed) return;
    if (_peerConnection != null) {
      if (_peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed) return;
    }

    final config = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
        {
          "url": "turn:openrelay.metered.ca:80",
          "username": "openrelayproject",
          "credential": "openrelayproject"
        },
        {
          "url": "turn:openrelay.metered.ca:443",
          "username": "openrelayproject",
          "credential": "openrelayproject"
        },
        {
          "url": "turn:openrelay.metered.ca:443?transport=tcp",
          "username": "openrelayproject",
          "credential": "openrelayproject"
        }
      ]
    };

    _peerConnection = await createPeerConnection(config);
    _isPcReady = true;

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onIceCandidate = (candidate) {
      if (_isDisposed || remoteUserId == null) return;
      _socketService.socket.emit('ice-candidate', {
        'toUserId': remoteUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };

    _peerConnection!.onTrack = (event) {
      if (_isDisposed || event.streams.isEmpty) return;
      remoteRenderer.srcObject = event.streams[0];
      isRemoteConnected.value = true;
    };
  }

  void _processCandidateQueue() async {
    if (_isDisposed) return;
    for (var candidate in _candidateQueue) {
      await _peerConnection!.addCandidate(candidate);
    }
    _candidateQueue.clear();
  }

  Future<void> _createOffer() async {
    if (_isDisposed || _peerConnection == null || remoteUserId == null) return;
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socketService.socket.emit('signal', [
       remoteUserId, 
       {'type': 'offer', 'sdp': offer.sdp}
    ]);
  }

  Future<void> _createAnswer() async {
    if (_isDisposed || _peerConnection == null || remoteUserId == null) return;
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.socket.emit('signal', [
       remoteUserId, 
       {'type': 'answer', 'sdp': answer.sdp}
    ]);
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user', 'width': 640, 'height': 480}
    });

    if (_isDisposed) return;
    localRenderer.srcObject = _localStream;
    isLocalReady.value = true;

    _socketService.socket.emit('join-room', [roomId, myUserId]);
  }

  void onEndCallPressed() {
    Get.defaultDialog(
      title: isHost ? "End Meeting?" : "Leave Meeting?",
      middleText: isHost ? "End for everyone?" : "Leave call?",
      textConfirm: isHost ? "End" : "Leave",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => isHost ? _endMeetingForAll() : _leaveMeeting(),
    );
  }
}