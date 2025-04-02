import 'chess_board_interface.dart';
import 'move_validation.dart';
import 'piece.dart';

extension GameLogic on ChessBoardInterface {
  bool move(Position from, Position to) {
    ChessPiece? piece = getPiece(from);
    if (piece == null || piece.color != turn) return false; // Invalid move
    if (!MoveValidator.isValidMove(this, from, to)) {
      return false; // Illegal move
    }

    // Handle En Passant
    if (piece.type == PieceType.pawn &&
        enPassantTarget != null &&
        to == enPassantTarget) {
      board[from.row][to.col] = null; // Remove captured pawn
    }

    // Save En Passant target
    enPassantTarget =
        (piece.type == PieceType.pawn && (to.row - from.row).abs() == 2)
            ? Position(row: (from.row + to.row) ~/ 2, col: from.col)
            : null;

    // Capture and move piece
    ChessPiece? capturedPiece = getPiece(to);
    movePiece(from, to);

    // Check if the king is in check (undo if necessary)
    if (isKingInCheck(turn)) {
      movePiece(to, from);
      board[to.row][to.col] = capturedPiece;
      return false;
    }

    // **Trigger Pawn Promotion (Handled in UI)**
    if (piece.type == PieceType.pawn && (to.row == 0 || to.row == 7)) {
      promotePawn(to, PieceType.queen); // Default to queen (UI should override)
    }

    // Switch turn
    turn = (turn == PieceColor.white) ? PieceColor.black : PieceColor.white;
    return true;
  }

  bool isKingInCheck(PieceColor kingColor) {
    int kingRow = -1, kingCol = -1;

    // Locate the king
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(Position(row: row, col: col));
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
        ChessPiece? piece = getPiece(Position(row: row, col: col));
        if (piece != null && piece.color != kingColor) {
          if (MoveValidator.isValidMove(
            this,
            Position(row: row, col: col),
            Position(row: kingRow, col: kingCol),
          )) {
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
        ChessPiece? piece = getPiece(Position(row: row, col: col));
        if (piece != null && piece.color == kingColor) {
          for (int newRow = 0; newRow < 8; newRow++) {
            for (int newCol = 0; newCol < 8; newCol++) {
              if (MoveValidator.isValidMove(
                this,
                Position(row: row, col: col),
                Position(row: newRow, col: newCol),
              )) {
                ChessPiece? capturedPiece = getPiece(
                  Position(row: newRow, col: newCol),
                );
                movePiece(
                  Position(row: row, col: col),
                  Position(row: newRow, col: newCol),
                );
                bool stillInCheck = isKingInCheck(kingColor);
                movePiece(
                  Position(row: newRow, col: newCol),
                  Position(row: row, col: col),
                );
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
        ChessPiece? piece = getPiece(Position(row: fromRow, col: fromCol));
        if (piece == null || piece.color != turn) {
          continue; // Skip opponent's pieces
        }

        for (int toRow = 0; toRow < 8; toRow++) {
          for (int toCol = 0; toCol < 8; toCol++) {
            if (MoveValidator.isValidMove(
              this,
              Position(row: fromRow, col: fromCol),
              Position(row: toRow, col: toCol),
            )) {
              return false; // Found a legal move, not stalemate
            }
          }
        }
      }
    }
    return !isKingInCheck(turn); // Stalemate if king is safe but no moves left
  }

  List<Position> getValidMoves(Position position) {
    ChessPiece? piece = getPiece(position);
    if (piece == null || piece.color != turn) return [];

    List<Position> validMoves = [];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Position target = Position(row: row, col: col);
        if (MoveValidator.isValidMove(this, position, target)) {
          // Simulate the move to check if it doesn't put the king in check
          ChessPiece? capturedPiece = getPiece(target);
          movePiece(position, target);
          bool stillInCheck = isKingInCheck(turn);
          movePiece(target, position);
          board[target.row][target.col] =
              capturedPiece; // Restore captured piece

          if (!stillInCheck) {
            validMoves.add(target);
          }
        }
      }
    }

    return validMoves;
  }

  void promotePawn(Position position, PieceType type) {
    ChessPiece? piece = getPiece(position);

    // Ensure it's a pawn at the last rank
    if (piece == null || piece.type != PieceType.pawn) return;
    if ((piece.color == PieceColor.white && position.row != 0) ||
        (piece.color == PieceColor.black && position.row != 7)) {
      return;
    }

    // Promote the pawn to the selected piece type
    board[position.row][position.col] = ChessPiece(
      type: type,
      color: piece.color,
    );
  }

  void makeMove(Position from, Position to) {
    if (!MoveValidator.isValidMove(this, from, to)) {
      return; // Ignore invalid moves
    }

    String currentFEN = toFEN();
    history.add(currentFEN); // Save the current state

    movePiece(from, to);
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
