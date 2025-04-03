import 'package:smart_chess/logical_interface/move_validation.dart';
import 'piece.dart';

class Position {
  final int row;
  final int col;

  Position({required this.row, required this.col});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class ChessBoardInterface {
  List<List<ChessPiece?>> board = List.generate(8, (_) => List.filled(8, null));
  final String? fen;
  // Adjust the initial state FEN so that the first rank (board[0]) corresponds
  // to the first row in the FEN and the last rank (board[7]) corresponds to the last row.
  // For example, if you want white pieces at the bottom (board[0]), then your FEN might look like:
  // 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w'
  final String initialState = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w';

  PieceColor turn = PieceColor.white;

  List<String> history = []; // Stores previous FEN states for undo
  List<String> redoHistory = []; // Stores undone moves for redo

  Position? enPassantTarget;

  ChessBoardInterface({this.fen}) {
    initFEN(fen ?? initialState);
  }

  void clearBoard() {
    board = List.generate(8, (_) => List.filled(8, null));
  }

  void initFEN(String fen) {
    clearBoard();
    List<String> parts = fen.split(" ");
    List<String> rows = parts[0].split("/");

    // Determine turn from FEN.
    turn = (parts[1] == "w") ? PieceColor.white : PieceColor.black;

    // Here we assume the FEN rows correspond directly to board rows (0 to 7).
    for (int row = 0; row < 8; row++) {
      int col = 0;
      String fenRow = rows[row]; // no reversal
      for (int i = 0; i < fenRow.length; i++) {
        String charAt = fenRow[i];
        if (RegExp(r'[1-8]').hasMatch(charAt)) {
          col += int.parse(charAt);
        } else {
          board[row][col] = _getPieceFromChar(charAt);
          col++;
        }
      }
    }
  }

  String toFEN() {
    StringBuffer fenBuffer = StringBuffer();
    // Generate FEN from board row 0 to row 7.
    for (int row = 0; row < 8; row++) {
      int emptyCount = 0;
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            fenBuffer.write(emptyCount);
            emptyCount = 0;
          }
          fenBuffer.write(_getPieceChar(piece));
        }
      }
      if (emptyCount > 0) fenBuffer.write(emptyCount);
      if (row < 7) fenBuffer.write("/");
    }
    fenBuffer.write(" ");
    fenBuffer.write(turn == PieceColor.white ? "w" : "b");
    return fenBuffer.toString();
  }

  ChessPiece? getPiece(Position position) {
    return board[position.row][position.col];
  }

  /// Moves a piece from [from] to [to] with en passant handling.
  bool _movePiece(Position from, Position to) {
    ChessPiece? piece = getPiece(from);
    if (piece == null) return false;

    // Check for En Passant Capture
    if (piece.type == PieceType.pawn &&
        enPassantTarget != null &&
        to == enPassantTarget &&
        from.col != to.col) {
      // Ensure it's a diagonal move
      int capturedPawnRow =
          (piece.color == PieceColor.white) ? to.row + 1 : to.row - 1;
      board[capturedPawnRow][to.col] = null; // Remove the captured pawn
    }

    // Move the piece to the new position
    board[to.row][to.col] = piece;
    board[from.row][from.col] = null;

    // Reset En Passant target (unless it's being set)
    enPassantTarget = null;

    // Set En Passant target if a pawn moves two squares forward
    if (piece.type == PieceType.pawn && (from.row - to.row).abs() == 2) {
      enPassantTarget = Position(row: (from.row + to.row) ~/ 2, col: to.col);
    }

    return true;
  }

  bool move(Position from, Position to) {
    ChessPiece? piece = getPiece(from);
    if (piece == null || piece.color != turn) {
      return false; // No piece or wrong turn
    }
    if (!MoveValidator.isValidMove(this, from, to)) {
      return false; // Illegal move as per validator
    }

    // Save current state for undo.
    history.add(toFEN());

    // Handle En Passant capture (if applicable).
    if (piece.type == PieceType.pawn &&
        enPassantTarget != null &&
        to == enPassantTarget) {
      int captureRow =
          piece.color == PieceColor.white ? to.row + 1 : to.row - 1;
      board[captureRow][to.col] = null;
    }

    // Set en passant target if pawn moves two squares.
    enPassantTarget =
        (piece.type == PieceType.pawn && (from.row - to.row).abs() == 2)
            ? Position(row: (from.row + to.row) ~/ 2, col: from.col)
            : null;

    // Capture any piece on the destination and move the piece.
    ChessPiece? capturedPiece = getPiece(to);
    _movePiece(from, to);

    // Validate that the move doesn't leave the king in check.
    if (isKingInCheck(turn)) {
      // Undo the move if it puts the king in check.
      _movePiece(to, from);
      board[to.row][to.col] = capturedPiece;
      return false;
    }

    // Switch turn after a successful move.
    switchTurn();
    // Clear redo history.
    redoHistory.clear();

    return true;
  }

  bool isKingInCheck(PieceColor kingColor) {
    int kingRow = -1, kingCol = -1;

    // Locate the king.
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

    // Check if any opponent's piece can attack the king.
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

    // Try all possible moves for the king's color to see if any escape check.
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
                _movePiece(
                  Position(row: row, col: col),
                  Position(row: newRow, col: newCol),
                );
                bool stillInCheck = isKingInCheck(kingColor);
                _movePiece(
                  Position(row: newRow, col: newCol),
                  Position(row: row, col: col),
                );
                board[newRow][newCol] = capturedPiece; // Restore piece
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
        if (piece == null || piece.color != turn) continue;
        for (int toRow = 0; toRow < 8; toRow++) {
          for (int toCol = 0; toCol < 8; toCol++) {
            if (MoveValidator.isValidMove(
              this,
              Position(row: fromRow, col: fromCol),
              Position(row: toRow, col: toCol),
            )) {
              return false;
            }
          }
        }
      }
    }
    return !isKingInCheck(turn);
  }

  List<Position> getValidMoves(Position position) {
    ChessPiece? piece = getPiece(position);
    if (piece == null || piece.color != turn) return [];

    List<Position> validMoves = [];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Position target = Position(row: row, col: col);
        if (MoveValidator.isValidMove(this, position, target)) {
          // Simulate move to see if king remains safe.
          ChessPiece? capturedPiece = getPiece(target);
          _movePiece(position, target);
          bool stillInCheck = isKingInCheck(turn);
          _movePiece(target, position);
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
    // Ensure the piece is a pawn on the final rank.
    if (piece == null || piece.type != PieceType.pawn) return;
    if ((piece.color == PieceColor.white && position.row != 0) ||
        (piece.color == PieceColor.black && position.row != 7)) {
      return;
    }

    // Promote the pawn.
    board[position.row][position.col] = ChessPiece(
      type: type,
      color: piece.color,
    );
  }

  bool canUndo() => history.isNotEmpty;
  bool canRedo() => redoHistory.isNotEmpty;

  void undo() {
    if (history.isNotEmpty) {
      String currentFEN = toFEN();
      // If the last state in history is identical to the current state,
      // remove it so that we actually restore a different state.
      if (history.last == currentFEN) {
        history.removeLast();
        return;
      }
      redoHistory.add(currentFEN);
      initFEN(history.removeLast());
    }
  }

  void redo() {
    if (redoHistory.isNotEmpty) {
      String currentFEN = toFEN();
      if (redoHistory.last == currentFEN) {
        redoHistory.removeLast();
        return;
      }
      history.add(currentFEN);
      initFEN(redoHistory.removeLast());
    }
  }

  // Switch turn to the opposite color.
  void switchTurn() {
    turn = (turn == PieceColor.white) ? PieceColor.black : PieceColor.white;
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
    return (piece.color == PieceColor.white
        ? whitePieces[piece.type]
        : blackPieces[piece.type])!;
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
}
