import 'dart:async';
import 'dart:convert';
import 'package:connect_hub/views/call/chat_view.dart';
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

  // video renders
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  late String roomId;
  late bool isHost;
  late String myUserId;
  String? remoteUserId;

  bool _joinedSocketRoom = false;

  final isRemoteConnected = false.obs;
  final isLocalReady = false.obs;
  
  // participants list
  final participants = <dynamic>[].obs;

  // button states
  final isMicOn = true.obs;
  final isVideoOn = true.obs;
  final isViewSwapped = false.obs;

  bool _isDisposed = false;
  final List<RTCIceCandidate> _candidateQueue = [];
  bool _isPcReady = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    roomId = args['roomId'];
    isHost = args['isHost'];
    myUserId = (box.read('userId')?.toString() ?? 'Unknown');

    if (_socketService.socket.disconnected) {
      print("🔌 Reconnecting socket...");
      _socketService.socket.connect();
    }

    _initRenderers();
    _setupSocketListeners();

    // If joining as participant, ensure backend join
    if (!isHost) {
      _ensureBackendJoin();
    }

    // Fetch participants immediately
    fetchParticipants();
  }

  Future<void> _ensureBackendJoin() async {
    try {
      await _api.joinMeeting(roomId);
    } catch (e) {
      print('⚠️ Failed to ensure backend join: $e');
    }
  }

  // Fetch participants from backend

  void fetchParticipants() async {
    print("🔍 Fetching participants for Room: $roomId...");
    try {
      final res = await _api.getParticipants(roomId);
      
      print("📥 API STATUS: ${res.statusCode}");
      print("📥 API BODY: ${res.body}");

      if (res.statusCode == 200) {
        // handle response body
        var data = res.body;
        if (data is String) {
          data = jsonDecode(data);
        }

        // update participants list
        if (data is Map && data['participants'] != null) {
          List<dynamic> list = data['participants'];
          participants.value = list; // Update UI
          participants.refresh();    // Force UI Refresh
          print("Success! Participants count: ${list.length}");
        } else {
          print("'participants' key missing in response");
        }
      } else {
        print("API Error: ${res.statusText}");
      }
    } catch (e) {
      print("CRASH fetching participants: $e");
    }
  }

  // socket event listeners

  void _setupSocketListeners() {
    if (_isDisposed) return;

    // webrtc signalling event
    _socketService.socket.on('user-connected', (userId) async {
      if (_isDisposed || userId == myUserId) return;
      print("👋 User Connected: $userId");

      if (remoteUserId != null) _softResetPeer();
      remoteUserId = userId;

      if (isHost) {
        await Future.delayed(const Duration(seconds: 1));
        if (_isDisposed) return;
        print("🚀 Host initiating call...");
        await _createPeerConnection();
        await _createOffer();
      }
        fetchParticipants();
    });

    // update participants on join/leave
    _socketService.socket.on('user-joined', (data) {
       print("➕ User joined event received");
       fetchParticipants(); // Refresh list
    });

    _socketService.socket.on('user-left', (data) {
       print("➖ User left event received");
       fetchParticipants(); // Refresh list
    });

    // clean up on user disconnect
    void handleUserLeft(data) {
       if (_isDisposed) return;
       print("❌ Remote user disconnected");
       _softResetPeer();
       // We also fetch participants here just in case 'user-left' missed
       fetchParticipants(); 
       Get.snackbar("Info", "Participant left the meeting");
    }

    _socketService.socket.on('user-disconnected', handleUserLeft);
    
    // meeting-ended event
    _socketService.socket.on('meeting-ended', (data) {
      if (_isDisposed) return;
      if (!isHost) {
        Get.snackbar("Meeting Ended", data['message'] ?? "Host ended the meeting");
      }
      _leaveAndNavigate();
    });

    // signaling event
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
        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
        await _createAnswer();
        _processCandidateQueue();
      } 
      else if (type == 'answer' && _peerConnection != null) {
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
        _processCandidateQueue();
      }
      else if (type == 'force-leave') {
        _leaveAndNavigate();
      }
    });

    // ice-candidate event
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

  // clean up peer connection

  void _softResetPeer() {
    if (_isDisposed) return;
    _peerConnection?.close();
    _peerConnection = null;
    _isPcReady = false;
    _candidateQueue.clear();
    remoteUserId = null;
    isRemoteConnected.value = false;
    try { remoteRenderer.srcObject = null; } catch (_) {}
  }

  void _leaveAndNavigate() {
    _socketService.socket.off('meeting-ended');
    _socketService.socket.off('user-connected');
    _socketService.socket.off('signal');
    _socketService.socket.off('ice-candidate');
    _socketService.socket.off('user-disconnected');
    _socketService.socket.disconnect();
    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    _isDisposed = true;
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.onClose();
  }

  // button actions
  void toggleMic() {
    if (_localStream != null) {
      bool newStatus = !isMicOn.value;
      isMicOn.value = newStatus;
      _localStream!.getAudioTracks().forEach((t) => t.enabled = newStatus);
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      bool newStatus = !isVideoOn.value;
      isVideoOn.value = newStatus;
      _localStream!.getVideoTracks().forEach((t) => t.enabled = newStatus);
    }
  }
  
  void toggleViewSwap() {
    isViewSwapped.toggle();
  }

  void onScreenSharePressed() {
    Get.snackbar("Feature", "Screen Sharing coming soon!");
  }

  void onChatPressed() {
    Get.bottomSheet(
      const ChatView(),
      isScrollControlled: true,
      enableDrag: true,
      ignoreSafeArea: false,
    );
  }

  // participants bottom sheet
  void onParticipantsPressed() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                    "Participants (${participants.length})", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  )),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))
                ],
              ),
            ),
            const Divider(),
            
            // participants list
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  final name = p['username'] ?? "Unknown";
                  final email = p['email'] ?? "";
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(initial, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  );
                },
              )),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows sheet to go taller
      ignoreSafeArea: false,
    );
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
  
  void _leaveMeeting() async {
    Get.back();
    // Use the backend API to leave, which emits 'user-left' to others
    try { await _api.post('/meetings/$roomId/leave', {}); } catch (_) {}
    _leaveAndNavigate();
  }

  void _endMeetingForAll() async {
    Get.back();
    if (remoteUserId != null) {
      // to send force signal via WebRTC as backup
      _socketService.socket.emit('signal', [
        remoteUserId,
        {'type': 'force-leave', 'message': 'Host ended the meeting'}
      ]);
    }
    try { await _api.endMeeting(roomId); } catch (_) {}
    _leaveAndNavigate();
  }

  // webrtc setup

  Future<void> _createPeerConnection() async {
    if (_isDisposed) return;
    if (_peerConnection != null) {
       if(_peerConnection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed) return;
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
    _socketService.socket.emit('signal', [remoteUserId, {'type': 'offer', 'sdp': offer.sdp}]);
  }

  Future<void> _createAnswer() async {
    if (_isDisposed || _peerConnection == null || remoteUserId == null) return;
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    _socketService.socket.emit('signal', [remoteUserId, {'type': 'answer', 'sdp': answer.sdp}]);
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

    // Join via Socket (wait until connected)
    _joinSocketRoomWhenConnected();
  }

  void _joinSocketRoomWhenConnected() {
    if (_isDisposed || _joinedSocketRoom) return;

    if (_socketService.socket.connected) {
      _joinedSocketRoom = true;
      _socketService.socket.emit('join-room', [roomId, myUserId]);
      fetchParticipants();
      return;
    }

    // Join once socket connects (avoids emit being dropped)
    _socketService.socket.on('connect', (_) {
      if (_isDisposed || _joinedSocketRoom) return;
      _joinedSocketRoom = true;
      _socketService.socket.emit('join-room', [roomId, myUserId]);
      fetchParticipants();
    });
  }
}