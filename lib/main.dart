// Sherman Yan

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'server_state.dart';
import 'socket_state.dart';
import 'player.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      home: ServerOrClient(),
    ),
  );
}

class ServerOrClient extends StatelessWidget {
  const ServerOrClient({super.key});

  @override
  Widget build(BuildContext context) {
    final tec = TextEditingController(text: 'localhost');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tic Tac Toe',
                style: TextStyle(
                  shadows: [Shadow(blurRadius: 30, color: Colors.blue)],
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Select your role to start the game:',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: 'Server',
                    onPressed: () {
                      try {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => ServerBase()));
                      } catch (e) {
                        print('Error navigating to ServerBase: $e');
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  CustomButton(
                    text: 'Client',
                    onPressed: () {
                      try {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientBase(tec.text),
                          ),
                        );
                      } catch (e) {
                        print('Error navigating to ClientBase: $e');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: tec,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Server IP',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const CustomButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.blue, blurRadius: 6)],
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}

class ServerBase extends StatelessWidget {
  const ServerBase({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerCubit>(
      create: (_) {
        try {
          return ServerCubit();
        } catch (e) {
          print('Error creating ServerCubit: $e');
          rethrow;
        }
      },
      child: BlocBuilder<ServerCubit, ServerState>(
        builder: (context, serverState) {
          if (serverState.server == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.blue,
              ),
              body: Center(
                child: Text(
                  'Starting server...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              backgroundColor: Colors.black,
            );
          }
          return BlocProvider<SocketCubit>(
            create: (_) {
              try {
                return SocketCubit.server(serverState.server!);
              } catch (e) {
                print('Error creating SocketCubit for server: $e');
                rethrow;
              }
            },
            child: BlocBuilder<SocketCubit, SocketState>(
              builder: (context, socketState) {
                if (socketState.socket == null) {
                  return Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.blue,
                    ),
                    body: Center(
                      child: Text(
                        'Waiting for client...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    backgroundColor: Colors.black,
                  );
                }
                return PlayerScreen(isStartingPlayer: true);
              },
            ),
          );
        },
      ),
    );
  }
}

class ClientBase extends StatelessWidget {
  final String ip;
  const ClientBase(this.ip, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SocketCubit>(
      create: (_) {
        try {
          return SocketCubit.client(ip);
        } catch (e) {
          print('Error creating SocketCubit for client: $e');
          rethrow;
        }
      },
      child: BlocBuilder<SocketCubit, SocketState>(
        builder: (context, socketState) {
          if (socketState.socket == null) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.blue,
              ),
              body: Center(
                child: Text(
                  'Connecting to server...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              backgroundColor: Colors.black,
            );
          }
          return PlayerScreen(isStartingPlayer: false);
        },
      ),
    );
  }
}
