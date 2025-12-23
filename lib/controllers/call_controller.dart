import 'dart:async';
import 'dart:convert';
import 'package:connect_hub/controllers/screen_share_controller.dart';
import 'package:connect_hub/views/call/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:get/get.dart' hide navigator;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import 'package:permission_handler/permission_handler.dart'; 

class CallController extends GetxController {
  final SocketService _socketService = Get.find();
  final ApiService _api = Get.find();
  final box = GetStorage();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  // video renders
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  MediaStream? get localStream => _localStream;
  RTCPeerConnection? get peerConnection => _peerConnection;

  late String roomId;
  late bool isHost;
  late String myUserId;
  late String meetTitle;
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
  final isRemoteMicOn = true.obs; 

  bool _isDisposed = false;
  final List<RTCIceCandidate> _candidateQueue = [];
  bool _isPcReady = false;

  Future<void> _stopScreenShareIfNeeded() async {
    try {
      if (Get.isRegistered<ScreenShareController>()) {
        await Get.find<ScreenShareController>().stopScreenShare();
      }
    } catch (_) {
      // best-effort cleanup
    }
  }

  @override
  void onInit() async {
    super.onInit();
    final args = Get.arguments;
    roomId = args['roomId'];
    isHost = args['isHost'];
    meetTitle = args['meetTitle'] ?? "New Meeting";
    myUserId = (box.read('userId')?.toString() ?? 'Unknown');

    if (_socketService.socket.disconnected) {
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
    await Permission.notification.request();
  }

  // meeting info dialog
  void showMeetingInfo() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Meeting Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              
              // Meeting Title
              const Text("Topic", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(meetTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              
              const SizedBox(height: 20),
              
              // Room ID Section
              const Text("Room ID", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SelectableText(
                      roomId, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.indigo, size: 20),
                      onPressed: () {
                        // Copy to clipboard
                        Clipboard.setData(ClipboardData(text: roomId));
                        Get.back(); // Close dialog
                        Get.snackbar(
                          "Copied", 
                          "Room ID copied to clipboard!", 
                          backgroundColor: Colors.green, 
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(10),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ensureBackendJoin() async {
    try {
      await _api.joinMeeting(roomId);
    } catch (e) {
      debugPrint('Failed to ensure backend join: $e');
    }
  }

  // Fetch participants from backend
  void fetchParticipants() async {
    try {
      final res = await _api.getParticipants(roomId);
      if (res.statusCode == 200) {
        var data = res.body;
        if (data is String) {
          data = jsonDecode(data);
        }

        if (data is Map && data['participants'] != null) {
          List<dynamic> list = data['participants'];
          participants.value = list; 
          participants.refresh();  
          debugPrint("Success! Participants count: ${list.length}");
        } else {
          debugPrint("'participants' key missing in response");
        }
      } else {
        debugPrint("API Error: ${res.statusText}");
      }
    } catch (e) {
      debugPrint("CRASH fetching participants: $e");
    }
  }

  // socket event listeners
  void _setupSocketListeners() {
    if (_isDisposed) return;

    // 1. User Connected Event
    _socketService.socket.on('user-connected', (userId) async {
      if (_isDisposed || userId == myUserId) return;

      if (remoteUserId != null) _softResetPeer();
      remoteUserId = userId;

      if (isHost) {
        await Future.delayed(const Duration(seconds: 1));
        if (_isDisposed) return;
        await _createPeerConnection();
        await _createOffer();
      }
      fetchParticipants();
    });

    // 2. Mic Toggled Event (Moved out of user-connected)
    _socketService.socket.on('mic-toggled', (data) {
      if (_isDisposed) return;
      String userId = data['userId'];
      bool status = data['isMicOn'];

      if (userId == remoteUserId) {
        isRemoteMicOn.value = status;
        print("🎤 Remote user mic changed to: $status");
      }
    });

    // 3. User Joined/Left Events
    _socketService.socket.on('user-joined', (data) {
       fetchParticipants();
    });

    _socketService.socket.on('user-left', (data) {
       fetchParticipants(); 
    });

    // 4. User Disconnected
    void handleUserLeft(data) {
       if (_isDisposed) return;
       debugPrint("Remote user disconnected");
       _softResetPeer();
       fetchParticipants(); 
       Get.snackbar("Info", "Participant left the meeting");
    }

    _socketService.socket.on('user-disconnected', handleUserLeft);
    
    // 5. Meeting Ended
    _socketService.socket.on('meeting-ended', (data) {
      if (_isDisposed) return;
      if (!isHost) {
        Get.snackbar("Meeting Ended", data['message'] ?? "Host ended the meeting");
      }
      unawaited(_leaveAndNavigate());
    });

    // 6. WebRTC Signal
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
        unawaited(_leaveAndNavigate());
      }
    });

    // 7. ICE Candidate
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

  // get local user's display name
  String getLocalName() {
    var user = participants.firstWhere(
      (p) => p['_id'] == myUserId, 
      orElse: () => {'username': 'Me'}
    );
    String name = user['username'] ?? 'Me';
    return isHost ? "$name (Host)" : name;
  }
  // get remote user's display name
  String getRemoteName() {
    if (remoteUserId == null) return "Waiting...";
    var user = participants.firstWhere(
      (p) => p['_id'] == remoteUserId, 
      orElse: () => {'username': 'Participant'}
    );
    String name = user['username'] ?? 'Participant';
    return !isHost ? "$name (Host)" : name; 
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

  Future<void> _leaveAndNavigate() async {
    await _stopScreenShareIfNeeded();
    _socketService.socket.off('meeting-ended');
    _socketService.socket.off('user-connected');
    _socketService.socket.off('signal');
    _socketService.socket.off('ice-candidate');
    _socketService.socket.off('user-disconnected');
    _socketService.socket.off('mic-toggled'); // Remove mic listener too
    _socketService.socket.disconnect();
    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    _isDisposed = true;
    unawaited(_stopScreenShareIfNeeded());
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

      // Emit event to server
      _socketService.socket.emit('mic-toggle', {
        'roomId': roomId,
        'userId': myUserId,
        'isMicOn': newStatus
      });
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
    try {
      Get.find<ScreenShareController>().toggleScreenShare();
    } catch (e) {
      debugPrint("Error finding ScreenShareController: $e");
    }
  }

  void onChatPressed() {
    Get.bottomSheet(
      const ChatView(),
      isScrollControlled: true,
      enableDrag: true,
      ignoreSafeArea: false,
    );
  }

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
      isScrollControlled: true,
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
    try { await _api.post('/meetings/$roomId/leave', {}); } catch (_) {}
    await _leaveAndNavigate();
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
    await _leaveAndNavigate();
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

    _socketService.socket.on('connect', (_) {
      if (_isDisposed || _joinedSocketRoom) return;
      _joinedSocketRoom = true;
      _socketService.socket.emit('join-room', [roomId, myUserId]);
      fetchParticipants();
    });
  }
}