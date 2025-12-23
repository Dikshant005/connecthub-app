import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:get/get.dart' hide navigator;
import 'call_controller.dart';

class ScreenShareController extends GetxController {
  final CallController _callController = Get.find();

  var isScreenSharing = false.obs;
  MediaStream? _screenStream;

  void toggleScreenShare() async {
    if (isScreenSharing.value) {
      await stopScreenShare();
    } else {
      await startScreenShare();
    }
  }

  Future<void> startScreenShare() async {
    try {
      if (_callController.peerConnection == null) {
        return;
      }

      // manually starting background service for Android to prevent OS killing it
      if (Platform.isAndroid) {
         final androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "Screen Sharing",
          notificationText: "Your screen is being shared to the meeting",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'), 
         );

         // intiailize the background service
         bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
         
         if (success) {
           bool enabled = await FlutterBackground.enableBackgroundExecution();
           if (enabled) {
            //  print("[ScreenShare] Background Service STARTED manually!");
           } else {
            //  print("[ScreenShare] Warning: Could not enable background execution.");
           }
         } else {
          //  print("[ScreenShare] Failed to initialize background service.");
         }

        //  print("[ScreenShare] Requesting helper permission...");
         // This forces the "Start Recording?" popup
         final granted = await Helper.requestCapturePermission();
         
         if (!granted) {
           return;
         }
         await Future.delayed(const Duration(milliseconds: 1000));
      }

      // reduced frame rate and resolution to prevent freezing
      final mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'width': 1280,  
          'height': 720, 
          'frameRate': 15, 
        }
      };
      
      final stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      _screenStream = stream;
      var screenTrack = stream.getVideoTracks().first;
      var senders = await _callController.peerConnection!.getSenders();
      var videoSender = senders.firstWhere((s) => s.track?.kind == 'video');
      await videoSender.replaceTrack(screenTrack);

      //force restart of keyframes to prevent frozen video because of some OS optimizations
      screenTrack.enabled = false;
      await Future.delayed(const Duration(milliseconds: 100));
      screenTrack.enabled = true;

      isScreenSharing.value = true;

      screenTrack.onEnded = () {
        stopScreenShare();
      };

    } catch (e) {
      Get.snackbar("Error", "Could not start screen share: $e", 
        backgroundColor: Colors.red, colorText: Colors.white);
      
      // reset state if it failed 
      isScreenSharing.value = false;
      // stop the manual service if we failed to start because of permission denial
      if (Platform.isAndroid) FlutterBackground.disableBackgroundExecution();
    }
  }

  Future<void> stopScreenShare() async {
    try {
      if (_callController.localStream == null) {
        return;
      }

      var cameraTrack = _callController.localStream!.getVideoTracks().first;  
      // access the peer connection's senders to replace the track
      var senders = await _callController.peerConnection!.getSenders();
      var videoSender = senders.firstWhere((s) => s.track?.kind == 'video');
      // replace the screen share track with the camera track
      await videoSender.replaceTrack(cameraTrack);

      _screenStream?.getTracks().forEach((track) {
         debugPrint("[ScreenShare] Stopping track: ${track.id}");
         track.stop();
      });
      _screenStream = null;

      isScreenSharing.value = false;
      
      // disbale the manual background service for Android for efficiency because screen share is off
      if (Platform.isAndroid) {
        await FlutterBackground.disableBackgroundExecution();
      }
      
      debugPrint("[ScreenShare] Screen share stopped completely.");

    } catch (e) {
      debugPrint("[ScreenShare] Error stopping screen share: $e");
    }
  }
}