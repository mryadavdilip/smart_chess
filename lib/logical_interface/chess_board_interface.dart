import 'package:smart_chess/logical_interface/move_validation.dart';

import 'piece.dart';

class Position {
  final int row;
  final int col;

  Position({required this.row, required this.col});
}

class ChessBoardInterface {
  List<List<ChessPiece?>> board = List.generate(8, (_) => List.filled(8, null));
  final String? fen;
  final String initialState = 'RNBQKBNR/PPPPPPPP/8/8/8/8/pppppppp/rnbqkbnr w';

  PieceColor turn = PieceColor.white;

  List<String> history = []; // Stores previous FEN states for undo
  List<String> redoHistory = []; // Stores undone moves for redo

  Position? enPassantTarget;

  ChessBoardInterface({this.fen}) {
    initFEN(fen ?? initialState);
  }

  clearBoard() {
    board = List.generate(8, (_) => List.filled(8, null));
  }

  void initFEN(String fen) {
    clearBoard();
    // Split the FEN string into its components.
    List<String> parts = fen.split(" ");
    List<String> rows = parts[0].split("/");

    // Determine the turn (who plays next).
    turn = (parts[1] == "w") ? PieceColor.white : PieceColor.black;

    // Loop over each rank (row) from 8 to 1 (in FEN, ranks are ordered from 8 to 1).
    for (int row = 7; row >= 0; row--) {
      int col = 0;

      // Iterate over the characters in the row string (rank) for the specific row.
      for (int i = 0; i < rows[7 - row].length; i++) {
        String charAt = rows[7 - row][i];

        // If the character is a number (1-8), it indicates empty squares.
        if (RegExp(r'[1-8]').hasMatch(charAt)) {
          col += int.parse(charAt); // Skip that many columns.
        } else {
          // Otherwise, it's a piece, so set the corresponding square on the board.
          board[row][col] = _getPieceFromChar(charAt);
          col++; // Move to the next column.
        }
      }
    }
  }

  String toFEN() {
    StringBuffer fen = StringBuffer();

    // Add board rows to FEN
    for (int row = 0; row < 8; row++) {
      int emptyCount = 0;
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            fen.write(emptyCount);
            emptyCount = 0;
          }
          fen.write(_getPieceChar(piece));
        }
      }
      if (emptyCount > 0) {
        fen.write(emptyCount);
      }
      if (row < 7) fen.write("/"); // Separate rows with "/"
    }

    // Add turn
    fen.write(" ");
    fen.write(turn == PieceColor.white ? "w" : "b");

    return fen.toString();
  }

  ChessPiece? getPiece(Position position) {
    return board[position.row][position.col];
  }

  // Add En Passant logic in the move method
  bool movePiece(Position from, Position to, {bool? virtual}) {
    ChessPiece? piece = getPiece(from);
    if (piece == null) return false;

    // En Passant check
    if (piece.type == PieceType.pawn &&
        enPassantTarget != null &&
        (to.row == enPassantTarget!.row && to.col == enPassantTarget!.col)) {
      // Perform en-passant capture
      board[enPassantTarget!.row][enPassantTarget!.col] =
          null; // Remove the captured pawn
    }

    // Standard move
    board[to.row][to.col] = piece;
    board[from.row][from.col] = null;

    // Update en passant target if a pawn advances two squares
    if (piece.type == PieceType.pawn &&
        (from.col == to.col) &&
        (from.row - to.row).abs() == 2) {
      enPassantTarget = Position(row: (from.row + to.row) ~/ 2, col: to.col);
    } else {
      enPassantTarget = null; // Reset en passant target after other moves
    }

    return true;
  }

  static String _getPieceChar(ChessPiece piece) {
    Map<PieceType, String> whitePieces = {
      PieceType.pawn: "P",
      PieceType.knight: "N",
      PieceType.bishop: "B",
      PieceType.rook: "R",
      PieceType.queen: "Q",
      PieceType.king: "K",
    };
    Map<PieceType, String> blackPieces = {
      PieceType.pawn: "p",
      PieceType.knight: "n",
      PieceType.bishop: "b",
      PieceType.rook: "r",
      PieceType.queen: "q",
      PieceType.king: "k",
    };
    return (piece.color == PieceColor.white ? whitePieces : blackPieces)[piece
        .type]!;
  }

  static ChessPiece _getPieceFromChar(String char) {
    Map<String, ChessPiece> pieceMap = {
      "P": ChessPiece(type: PieceType.pawn, color: PieceColor.white),
      "N": ChessPiece(type: PieceType.knight, color: PieceColor.white),
      "B": ChessPiece(type: PieceType.bishop, color: PieceColor.white),
      "R": ChessPiece(type: PieceType.rook, color: PieceColor.white),
      "Q": ChessPiece(type: PieceType.queen, color: PieceColor.white),
      "K": ChessPiece(type: PieceType.king, color: PieceColor.white),
      "p": ChessPiece(type: PieceType.pawn, color: PieceColor.black),
      "n": ChessPiece(type: PieceType.knight, color: PieceColor.black),
      "b": ChessPiece(type: PieceType.bishop, color: PieceColor.black),
      "r": ChessPiece(type: PieceType.rook, color: PieceColor.black),
      "q": ChessPiece(type: PieceType.queen, color: PieceColor.black),
      "k": ChessPiece(type: PieceType.king, color: PieceColor.black),
    };
    return pieceMap[char]!;
  }

  bool move(Position from, Position to) {
    ChessPiece? piece = getPiece(from);
    if (piece == null || piece.color != turn) return false; // Invalid move
    if (!MoveValidator.isValidMove(this, from, to)) {
      return false; // Illegal move
    }

    history.add(toFEN()); // Save the current state

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
    movePiece(from, to, virtual: true);

    // Check if the king is in check (undo if necessary)
    if (isKingInCheck(turn)) {
      movePiece(to, from, virtual: true);
      board[to.row][to.col] = capturedPiece;
      return false;
    }

    // **Trigger Pawn Promotion (Handled in UI)**
    // if (piece.type == PieceType.pawn && (to.row == 0 || to.row == 7)) {
    //   // promotePawn(to, PieceType.queen); // Default to queen (UI should override)
    // }

    // Switch turn
    switchTurn();

    redoHistory.clear(); // Clear redo stack only after a successful move

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
    print(0);
    if (piece == null || piece.type != PieceType.pawn) return;
    print(1);
    if ((piece.color == PieceColor.white && position.row != 0) ||
        (piece.color == PieceColor.black && position.row != 7)) {
      print(2);
      return;
    }

    print(3);

    // Promote the pawn to the selected piece type
    board[position.row][position.col] = ChessPiece(
      type: type,
      color: piece.color,
    );

    print(getPiece(position)?.type);
  }

  bool canUndo() => history.isNotEmpty;
  bool canRedo() => redoHistory.isNotEmpty;

  void undo() {
    if (history.isNotEmpty) {
      redoHistory.add(toFEN()); // Save current state for redo
      switchTurn();
      initFEN(history.removeLast());
    }
  }

  void redo() {
    if (redoHistory.isNotEmpty) {
      history.add(toFEN()); // Save current state for undo
      switchTurn();
      initFEN(redoHistory.removeLast());
    }
  }

  void switchTurn() {
    turn = (turn == PieceColor.white) ? PieceColor.black : PieceColor.white;
  }
}
