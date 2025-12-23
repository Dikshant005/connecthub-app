import 'package:connect_hub/controllers/screen_share_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../controllers/call_controller.dart';
import 'screen_share_view.dart'; // 🟢 IMPORT THE VIEW

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScreenShareController screenCtrl = Get.find();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // remote video (full screen)
          Positioned.fill(
            child: Obx(() {
              // logic to swap views
              bool showLocal = controller.isViewSwapped.value;

              if (showLocal) {
                // 🟢 SCREEN SHARE LOGIC (Full Screen)
                if (screenCtrl.isScreenSharing.value) {
                  return const ScreenShareView();
                }
                
                if (controller.isLocalReady.value) {
                  return controller.isVideoOn.value 
                      ? RTCVideoView(
                          controller.localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : const Center(child: Icon(Icons.videocam_off, color: Colors.grey, size: 60));
                } else {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                }
              } else {
                if (controller.isRemoteConnected.value) {
                  return RTCVideoView(
                    controller.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  );
                } else {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text("Waiting for participant...", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }
              }
            }),
          ),

          // local video (small overlay)
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => controller.toggleViewSwap(),
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Obx(() {
                    // logic to swap views
                    bool showRemote = controller.isViewSwapped.value;

                    if (showRemote) {
                      if (controller.isRemoteConnected.value) {
                        return RTCVideoView(
                          controller.remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        );
                      } else {
                        return const Center(child: Icon(Icons.person_off, color: Colors.grey, size: 40));
                      }
                    } else {
                      // 🟢 SCREEN SHARE LOGIC (Small Overlay)
                      if (screenCtrl.isScreenSharing.value) {
                        // Use a simplified view for small overlay
                        return Container(
                          color: Colors.grey.shade900,
                          child: const Center(
                            child: Icon(Icons.mobile_screen_share, color: Colors.blue, size: 40),
                          ),
                        );
                      }

                      if (controller.isLocalReady.value) {
                        if (controller.isVideoOn.value) {
                          return RTCVideoView(
                            controller.localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          );
                        } else {
                          return const Center(child: Icon(Icons.videocam_off, color: Colors.grey, size: 40));
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                        );
                      }
                    }
                  }),
                ),
              ),
            ),
          ),

          // call controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() => _buildIconButton(
                            icon: controller.isMicOn.value ? Icons.mic : Icons.mic_off,
                            color: controller.isMicOn.value ? Colors.white : Colors.redAccent,
                            onTap: controller.toggleMic,
                          )),

                          Obx(() => _buildIconButton(
                            icon: controller.isVideoOn.value ? Icons.videocam : Icons.videocam_off,
                            color: controller.isVideoOn.value ? Colors.white : Colors.redAccent,
                            onTap: controller.toggleCamera,
                          )),

                          // screen share button
                          Obx(() => _buildIconButton(
                            icon: screenCtrl.isScreenSharing.value 
                                ? Icons.mobile_screen_share 
                                : Icons.screen_share_rounded,
                            color: screenCtrl.isScreenSharing.value ? Colors.blue : Colors.white,
                            onTap: screenCtrl.toggleScreenShare,
                          )),

                          _buildIconButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            onTap: controller.onChatPressed,
                          ),

                          _buildIconButton(
                            icon: Icons.people_outline_rounded,
                            onTap: controller.onParticipantsPressed,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // end call button 
                    GestureDetector(
                      onTap: () => controller.onEndCallPressed(),
                      child: Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10)
                          ]
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // room id display
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                "Room: ${controller.roomId}", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon, 
    required VoidCallback onTap, 
    Color color = Colors.white
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}