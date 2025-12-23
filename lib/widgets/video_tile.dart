import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoTile extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final String userName;
  final bool isMicOn;
  final bool isLocal; // To mirror local video

  const VideoTile({
    super.key,
    required this.renderer,
    required this.userName,
    required this.isMicOn,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black87,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. The Video
            RTCVideoView(
              renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: isLocal, // Mirror only local view
            ),

            // 2. The Name & Mic Tag (Bottom Left)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54, // Semi-transparent background
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic Icon Logic
                    Icon(
                      isMicOn ? Icons.mic : Icons.mic_off,
                      color: isMicOn ? Colors.white : Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    // Name Text
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}