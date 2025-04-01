import 'piece.dart';
import 'chess_board_interface.dart';

class MoveValidator {
  static bool isValidMove(
    ChessBoardInterface board,
    Position from,
    Position to,
  ) {
    ChessPiece? piece = board.getPiece(from);
    if (piece == null) return false; // No piece to move

    ChessPiece? targetPiece = board.getPiece(to);
    if (targetPiece != null && targetPiece.color == piece.color) {
      return false; // Cannot capture own piece
    }

    switch (piece.type) {
      case PieceType.pawn:
        return _validatePawnMove(piece, from, to, board);
      case PieceType.knight:
        return _validateKnightMove(from, to);
      case PieceType.bishop:
        return _validateBishopMove(from, to, board);
      case PieceType.rook:
        return _validateRookMove(from, to, board);
      case PieceType.queen:
        return _validateQueenMove(from, to, board);
      case PieceType.king:
        return _validateKingMove(from, to);
    }
  }

  static bool _validatePawnMove(
    ChessPiece piece,
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    int direction = (piece.color == PieceColor.white) ? 1 : -1;
    int startRow = (piece.color == PieceColor.white) ? 1 : 6;

    // Normal move forward
    if (from.col == to.col && board.getPiece(to) == null) {
      if (to.row == from.row + direction) return true; // Single move
      if (from.row == startRow &&
          to.row == from.row + (2 * direction) &&
          board.getPiece(to) == null) {
        return true; // Double move from starting position
      }
    }

    // Capturing diagonally
    if ((to.col - from.col).abs() == 1 && to.row == from.row + direction) {
      if (board.getPiece(to) != null) return true;
    }

    return false;
  }

  static bool _validateKnightMove(Position from, Position to) {
    int rowDiff = (to.row - from.row).abs();
    int colDiff = (to.col - from.col).abs();
    return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2);
  }

  static bool _validateBishopMove(
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    if ((to.row - from.row).abs() != (to.col - from.col).abs()) return false;

    int rowStep = (to.row > from.row) ? 1 : -1;
    int colStep = (to.col > from.col) ? 1 : -1;
    int steps = (to.row - from.row).abs();

    for (int i = 1; i < steps; i++) {
      if (board.getPiece(
            Position(row: from.row + i * rowStep, col: from.col + i * colStep),
          ) !=
          null) {
        return false;
      }
    }

    return true;
  }

  static bool _validateRookMove(
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    if (from.row != to.row && from.col != to.col) return false;

    int rowStep =
        (to.row > from.row)
            ? 1
            : (to.row < from.row)
            ? -1
            : 0;
    int colStep =
        (to.col > from.col)
            ? 1
            : (to.col < from.col)
            ? -1
            : 0;
    int steps =
        (from.row != to.row)
            ? (to.row - from.row).abs()
            : (to.col - from.col).abs();

    for (int i = 1; i < steps; i++) {
      if (board.getPiece(
            Position(row: from.row + i * rowStep, col: from.col + i * colStep),
          ) !=
          null) {
        return false;
      }
    }

    return true;
  }

  static bool _validateQueenMove(
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    return _validateBishopMove(from, to, board) ||
        _validateRookMove(from, to, board);
  }

  static bool _validateKingMove(Position from, Position to) {
    return (to.row - from.row).abs() <= 1 && (to.col - from.col).abs() <= 1;
  }
}
