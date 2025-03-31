import 'chess_board.dart';
import 'move_validation.dart';
import 'piece.dart';

extension GameLogic on ChessBoardInterface {
  bool move(int fromRow, int fromCol, int toRow, int toCol) {
    ChessPiece? piece = getPiece(fromRow, fromCol);

    if (piece == null || piece.color != turn) {
      return false; // Wrong turn or empty square
    }
    if (!MoveValidator.isValidMove(this, fromRow, fromCol, toRow, toCol)) {
      return false; // Invalid move
    }

    // Simulate move and check if the king is in check
    ChessPiece? capturedPiece = getPiece(toRow, toCol);
    movePiece(fromRow, fromCol, toRow, toCol);
    if (isKingInCheck(turn)) {
      movePiece(toRow, toCol, fromRow, fromCol); // Undo move
      board[toRow][toCol] = capturedPiece; // Restore captured piece
      return false;
    }

    // Change turn
    turn = (turn == PieceColor.white) ? PieceColor.black : PieceColor.white;
    return true;
  }

  bool isKingInCheck(PieceColor kingColor) {
    int kingRow = -1, kingCol = -1;

    // Locate the king
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(row, col);
        if (piece != null &&
            piece.type == PieceType.king &&
            piece.color == kingColor) {
          kingRow = row;
          kingCol = col;
          break;
        }
      }
    }

    // Check if any opponent's piece can attack the king
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(row, col);
        if (piece != null && piece.color != kingColor) {
          if (MoveValidator.isValidMove(this, row, col, kingRow, kingCol)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool isCheckmate(PieceColor kingColor) {
    if (!isKingInCheck(kingColor)) return false;

    // Try all possible moves to escape check
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(row, col);
        if (piece != null && piece.color == kingColor) {
          for (int newRow = 0; newRow < 8; newRow++) {
            for (int newCol = 0; newCol < 8; newCol++) {
              if (MoveValidator.isValidMove(this, row, col, newRow, newCol)) {
                ChessPiece? capturedPiece = getPiece(newRow, newCol);
                movePiece(row, col, newRow, newCol);
                bool stillInCheck = isKingInCheck(kingColor);
                movePiece(newRow, newCol, row, col);
                board[newRow][newCol] = capturedPiece; // Restore captured piece
                if (!stillInCheck) return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  bool isStalemate() {
    for (int fromRow = 0; fromRow < 8; fromRow++) {
      for (int fromCol = 0; fromCol < 8; fromCol++) {
        ChessPiece? piece = getPiece(fromRow, fromCol);
        if (piece == null || piece.color != turn) {
          continue; // Skip opponent's pieces
        }

        for (int toRow = 0; toRow < 8; toRow++) {
          for (int toCol = 0; toCol < 8; toCol++) {
            if (MoveValidator.isValidMove(
              this,
              fromRow,
              fromCol,
              toRow,
              toCol,
            )) {
              return false; // Found a legal move, not stalemate
            }
          }
        }
      }
    }
    return !isKingInCheck(turn); // Stalemate if king is safe but no moves left
  }

  void makeMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (!MoveValidator.isValidMove(this, fromRow, fromCol, toRow, toCol)) {
      return; // Ignore invalid moves
    }

    String currentFEN = toFEN();
    history.add(currentFEN); // Save the current state

    movePiece(fromRow, fromCol, toRow, toCol);
    turn = (turn == PieceColor.white) ? PieceColor.black : PieceColor.white;

    redoHistory.clear(); // Clear redo stack only after a successful move
  }

  bool canUndo() => history.isNotEmpty;
  bool canRedo() => redoHistory.isNotEmpty;

  void undo() {
    if (history.isNotEmpty) {
      redoHistory.add(toFEN()); // Save current state for redo
      history.removeLast();
    }
  }

  void redo() {
    if (redoHistory.isNotEmpty) {
      history.add(toFEN()); // Save current state for undo
      redoHistory.removeLast();
    }
  }
}
