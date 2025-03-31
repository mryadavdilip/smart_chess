import 'piece.dart';

class ChessBoardInterface {
  List<List<ChessPiece?>> board = List.generate(8, (_) => List.filled(8, null));
  final String? fen;

  PieceColor turn = PieceColor.white;

  List<String> history = []; // Stores previous FEN states for undo
  List<String> redoHistory = []; // Stores undone moves for redo

  ChessBoardInterface({this.fen}) {
    fen == null ? _initializeBoard() : initFEN(fen!);
  }

  void _initializeBoard() {
    // Place pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[6][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    }

    // Place rooks
    board[0][0] =
        board[0][7] = ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[7][0] =
        board[7][7] = ChessPiece(type: PieceType.rook, color: PieceColor.black);

    // Place knights
    board[0][1] =
        board[0][6] = ChessPiece(
          type: PieceType.knight,
          color: PieceColor.white,
        );
    board[7][1] =
        board[7][6] = ChessPiece(
          type: PieceType.knight,
          color: PieceColor.black,
        );

    // Place bishops
    board[0][2] =
        board[0][5] = ChessPiece(
          type: PieceType.bishop,
          color: PieceColor.white,
        );
    board[7][2] =
        board[7][5] = ChessPiece(
          type: PieceType.bishop,
          color: PieceColor.black,
        );

    // Place queens
    board[0][3] = ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[7][3] = ChessPiece(type: PieceType.queen, color: PieceColor.black);

    // Place kings
    board[0][4] = ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[7][4] = ChessPiece(type: PieceType.king, color: PieceColor.black);
  }

  ChessPiece? getPiece(int row, int col) {
    return board[row][col];
  }

  void movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    board[toRow][toCol] = board[fromRow][fromCol];
    board[fromRow][fromCol] = null;
  }

  void initFEN(String fen) {
    List<String> parts = fen.split(" ");
    List<String> rows = parts[0].split("/");
    turn = (parts[1] == "w") ? PieceColor.white : PieceColor.black;

    for (int row = 7; row >= 0; row--) {
      int col = 0;
      for (int i = 0; i < rows[7 - row].length; i++) {
        String char = rows[7 - row][i];
        if (RegExp(r'[1-8]').hasMatch(char)) {
          col += int.parse(char);
        } else {
          board[row][col] = _getPieceFromChar(char);
          col++;
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
}
