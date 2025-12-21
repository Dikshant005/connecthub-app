import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../controllers/call_controller.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // remote video (full screen)
          Positioned.fill(
            child: Obx(() {
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
            }),
          ),

          // 2. local video (small overlay)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Obx(() {
                  if (controller.isLocalReady.value) {
                    return RTCVideoView(
                      controller.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                    );
                  }
                }),
              ),
            ),
          ),

          // call controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // end call button 
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                  onPressed: () => controller.onEndCallPressed(), // Calls the API now
                ),
              ],
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
}