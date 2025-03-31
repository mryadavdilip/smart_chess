import 'piece.dart';
import 'chess_board.dart';

class MoveValidator {
  static bool isValidMove(
    ChessBoardInterface board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    ChessPiece? piece = board.getPiece(fromRow, fromCol);
    if (piece == null) return false; // No piece to move

    ChessPiece? targetPiece = board.getPiece(toRow, toCol);
    if (targetPiece != null && targetPiece.color == piece.color) {
      return false; // Cannot capture own piece
    }

    switch (piece.type) {
      case PieceType.pawn:
        return _validatePawnMove(piece, fromRow, fromCol, toRow, toCol, board);
      case PieceType.knight:
        return _validateKnightMove(fromRow, fromCol, toRow, toCol);
      case PieceType.bishop:
        return _validateBishopMove(fromRow, fromCol, toRow, toCol, board);
      case PieceType.rook:
        return _validateRookMove(fromRow, fromCol, toRow, toCol, board);
      case PieceType.queen:
        return _validateQueenMove(fromRow, fromCol, toRow, toCol, board);
      case PieceType.king:
        return _validateKingMove(fromRow, fromCol, toRow, toCol);
    }
  }

  static bool _validatePawnMove(
    ChessPiece piece,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    ChessBoardInterface board,
  ) {
    int direction = (piece.color == PieceColor.white) ? 1 : -1;
    int startRow = (piece.color == PieceColor.white) ? 1 : 6;

    // Normal move forward
    if (fromCol == toCol && board.getPiece(toRow, toCol) == null) {
      if (toRow == fromRow + direction) return true; // Single move
      if (fromRow == startRow &&
          toRow == fromRow + (2 * direction) &&
          board.getPiece(toRow, toCol) == null) {
        return true; // Double move from starting position
      }
    }

    // Capturing diagonally
    if ((toCol - fromCol).abs() == 1 && toRow == fromRow + direction) {
      if (board.getPiece(toRow, toCol) != null) return true;
    }

    return false;
  }

  static bool _validateKnightMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    int rowDiff = (toRow - fromRow).abs();
    int colDiff = (toCol - fromCol).abs();
    return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2);
  }

  static bool _validateBishopMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    ChessBoardInterface board,
  ) {
    if ((toRow - fromRow).abs() != (toCol - fromCol).abs()) return false;

    int rowStep = (toRow > fromRow) ? 1 : -1;
    int colStep = (toCol > fromCol) ? 1 : -1;
    int steps = (toRow - fromRow).abs();

    for (int i = 1; i < steps; i++) {
      if (board.getPiece(fromRow + i * rowStep, fromCol + i * colStep) !=
          null) {
        return false;
      }
    }

    return true;
  }

  static bool _validateRookMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    ChessBoardInterface board,
  ) {
    if (fromRow != toRow && fromCol != toCol) return false;

    int rowStep =
        (toRow > fromRow)
            ? 1
            : (toRow < fromRow)
            ? -1
            : 0;
    int colStep =
        (toCol > fromCol)
            ? 1
            : (toCol < fromCol)
            ? -1
            : 0;
    int steps =
        (fromRow != toRow) ? (toRow - fromRow).abs() : (toCol - fromCol).abs();

    for (int i = 1; i < steps; i++) {
      if (board.getPiece(fromRow + i * rowStep, fromCol + i * colStep) !=
          null) {
        return false;
      }
    }

    return true;
  }

  static bool _validateQueenMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    ChessBoardInterface board,
  ) {
    return _validateBishopMove(fromRow, fromCol, toRow, toCol, board) ||
        _validateRookMove(fromRow, fromCol, toRow, toCol, board);
  }

  static bool _validateKingMove(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    return (toRow - fromRow).abs() <= 1 && (toCol - fromCol).abs() <= 1;
  }
}
