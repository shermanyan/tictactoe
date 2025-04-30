// Sherman Yan

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'socket_state.dart';
import 'game_state.dart';
import 'message_state.dart';

class PlayerScreen extends StatelessWidget {
  final bool isStartingPlayer;
  const PlayerScreen({required this.isStartingPlayer, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GameCubit>(create: (_) => GameCubit(isStartingPlayer)),
        BlocProvider<MessageCubit>(create: (_) => MessageCubit()),
      ],
      child: BlocBuilder<GameCubit, GameState>(
        builder: (context, gameState) => PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            context
                .read<SocketCubit>()
                .closeConnection(); // Close socket on exit
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.blue,
            ),
            backgroundColor: Colors.black,
            body: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.black,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.read<GameCubit>().resignLocal();
                                context.read<SocketCubit>().send('resign');
                                context
                                    .read<MessageCubit>()
                                    .addChat('You resigned');
                                Navigator.of(context)
                                    .pop(); // Navigate back on resign
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: Text('Resign',
                                  style: TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                        Expanded(
                          child: _GameBoard(isStartingPlayer: isStartingPlayer),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(color: Colors.white54, width: 1),
                // Chat panel takes 1/3 width
                Expanded(
                  flex: 1,
                  child: ChatPanel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBoard extends StatelessWidget {
  final bool isStartingPlayer;
  const _GameBoard({required this.isStartingPlayer});

  @override
  Widget build(BuildContext context) {
    final gc = context.read<GameCubit>();
    final sc = context.read<SocketCubit>();
    final mc = context.read<MessageCubit>();

    if (sc.state.socket != null && !sc.state.listening) {
      sc.startListening((msg) {
        if (msg.startsWith('sq ')) {
          final idx = int.parse(msg.split(' ')[1]);
          gc.playRemote(idx); // Handle opponent's move
        } else if (msg == 'pass') {
          gc.passRemote();
          mc.addChat('Opponent passed');
        } else if (msg == 'resign') {
          gc.resignRemote();
          mc.addChat('Opponent resigned — you win!');
        } else if (msg.startsWith('chat ')) {
          final text = msg.substring(5);
          mc.addChat('Them: $text'); // Add opponent's chat message
        }
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var col = 0; col < 3; col++) _Square(index: row * 3 + col),
            ],
          ),
        const SizedBox(height: 20),
        BlocBuilder<GameCubit, GameState>(
          builder: (context, state) {
            if (state.resigned) {
              return Text(
                'Game Over',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              );
            }
            final winner = gc.checkWinner();
            if (winner.isNotEmpty) {
              final txt = winner == 'Draw' ? 'Draw!' : '$winner wins!';
              return Text(
                txt,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              );
            }
            if (!state.myTurn) {
              return Column(
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 8),
                  Text('Waiting for opponent…',
                      style: TextStyle(color: Colors.white)),
                ],
              );
            }
            return Column(
              children: [
                Text(
                  'Your turn',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: state.myTurn
                      ? () {
                          context.read<GameCubit>().passLocal();
                          context.read<SocketCubit>().send('pass');
                          context.read<MessageCubit>().addChat('You passed');
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: state.myTurn ? Colors.blue : Colors.grey,
                  ),
                  child: Text(
                    'Pass',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Square extends StatelessWidget {
  final int index;
  const _Square({required this.index});

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameCubit>();
    final sc = context.read<SocketCubit>();
    final mark = gc.state.board[index];

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: gc.state.myTurn && mark == GameCubit.empty
            ? () {
                gc.playLocal(index);
                sc.send('sq $index');
              }
            : null,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [BoxShadow(color: Colors.blue, blurRadius: 10)],
          ),
          alignment: Alignment.center,
          child: Text(
            mark,
            style: TextStyle(fontSize: 24, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}

/// Scrollable chat history + input.
class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  _ChatPanelState createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _chatTec = TextEditingController();
  final _scrollCtl = ScrollController();

  @override
  void dispose() {
    _chatTec.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _chatTec.text.trim();
    if (text.isEmpty) return;
    final sc = context.read<SocketCubit>();
    final mc = context.read<MessageCubit>();

    sc.send('chat $text');
    mc.addChat('You: $text');

    _chatTec.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.jumpTo(_scrollCtl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<MessageCubit>().state.history;

    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtl,
              itemCount: history.length,
              itemBuilder: (_, i) {
                final msg = history[i];
                final isStatus =
                    !(msg.startsWith('You:') || msg.startsWith('Them:'));
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: isStatus ? Colors.blue : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(color: Colors.white30),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatTec,
                  cursorColor: Colors.blue,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type chat…',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              IconButton(
                  icon: Icon(Icons.send, color: Colors.blue), onPressed: _send),
            ],
          ),
        ],
      ),
    );
  }
}
