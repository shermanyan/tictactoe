// Sherman Yan

import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

class SocketState {
  final Socket? socket;
  final bool listening;
  SocketState(this.socket, this.listening);
}

class SocketCubit extends Cubit<SocketState> {
  bool _disposed = false;

  SocketCubit.server(ServerSocket ss) : super(SocketState(null, false)) {
    ss.listen((client) {
      if (!_disposed) emit(SocketState(client, false));
    });
  }

  SocketCubit.client(String ip) : super(SocketState(null, false)) {
    _attemptConnect(ip);
  }

  Future<void> _attemptConnect(String ip) async {
    if (_disposed) return;
    try {
      final s = await Socket.connect(ip, 9203);
      if (!_disposed) emit(SocketState(s, false));
    } catch (e) {
      if (_disposed) return;
      await Future.delayed(Duration(seconds: 2));
      return _attemptConnect(ip);
    }
  }

  void startListening(void Function(String) onMessage) {
    final sock = state.socket;
    if (sock != null && !state.listening) {
      sock.listen((data) {
        final msg = String.fromCharCodes(data).trim();
        onMessage(msg);
      });
      emit(SocketState(sock, true));
    }
  }

  void send(String msg) {
    state.socket?.writeln(msg);
  }

  void closeConnection() {
    state.socket?.destroy();
    emit(SocketState(null, false));
  }

  @override
  Future<void> close() async {
    _disposed = true;
    state.socket?.destroy();
    return super.close();
  }
}
