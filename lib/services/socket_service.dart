import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends GetxService {
  late IO.Socket socket; 
  final String _url = "https://connecthub.dikshant-ahalawat.live";

  @override
  void onInit() {
    super.onInit();
    _initConnection(); // to auto restart the socket connection
  }

  void _initConnection() {
    socket = IO.io(_url, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    socket.onConnect((_) {
      debugPrint("SOCKET CONNECTED: ${socket.id}");
    });

    socket.connect();
  }

  void joinRoom(String roomId, String userId) {
    if (socket.connected) {
      socket.emit('join-room', [roomId, userId]);
    } else {
      debugPrint("Cannot join: Socket is not connected yet.");
    }
  }
}