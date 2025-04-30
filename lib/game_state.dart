// Sherman Yan

import 'package:flutter_bloc/flutter_bloc.dart';

class GameState {
  final bool iStart;
  final bool myTurn;
  final List<String> board;
  final bool resigned; // true if someone resigned
  GameState(this.iStart, this.myTurn, this.board, {this.resigned = false});
}

class GameCubit extends Cubit<GameState> {
  static const empty = '';

  GameCubit(bool start) : super(GameState(start, start, List.filled(9, empty)));

  void playLocal(int idx) {
    if (!_isGameOver && state.myTurn && state.board[idx] == empty) {
      _mark(idx);
    }
  }

  void playRemote(int idx) {
    if (!_isGameOver) _mark(idx);
  }

  void passLocal() {
    if (!_isGameOver && state.myTurn) {
      emit(GameState(
        state.iStart,
        !state.myTurn,
        state.board,
      ));
    }
  }

  void passRemote() {
    if (!_isGameOver) {
      emit(GameState(
        state.iStart,
        !state.myTurn,
        state.board,
      ));
    }
  }

  void resignLocal() {
    // you resigned, game over
    emit(GameState(
      state.iStart,
      state.myTurn,
      state.board,
      resigned: true,
    ));
  }

  void resignRemote() {
    // opponent resigned, game over
    emit(GameState(
      state.iStart,
      state.myTurn,
      state.board,
      resigned: true,
    ));
  }

  bool get _isGameOver {
    if (state.resigned) return true;
    final w = checkWinner();
    return w.isNotEmpty;
  }

  void _mark(int idx) {
    final mark = state.myTurn == state.iStart ? 'X' : 'O';
    final b = List<String>.from(state.board)..[idx] = mark;
    emit(GameState(state.iStart, !state.myTurn, b));
  }

  /// Returns 'X', 'O', 'Draw' or '' if no winner yet.
  String checkWinner() {
    const combos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var c in combos) {
      final a = state.board[c[0]];
      if (a != empty && a == state.board[c[1]] && a == state.board[c[2]]) {
        return a;
      }
    }
    return state.board.contains(empty) ? '' : 'Draw';
  }
}
