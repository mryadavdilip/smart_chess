import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_chess/storage_service.dart';
import 'chess_board.dart';
import 'game_logic.dart';
import 'piece.dart';

class ChessBoardUI extends StatefulWidget {
  const ChessBoardUI({super.key});

  @override
  State<ChessBoardUI> createState() => _ChessBoardUIState();
}

class _ChessBoardUIState extends State<ChessBoardUI> {
  ChessBoardInterface game = ChessBoardInterface();
  int? selectedRow, selectedCol;

  void onSquareTap(int row, int col) {
    setState(() {
      if (selectedRow == null) {
        // Select piece
        if (game.getPiece(row, col) != null &&
            game.getPiece(row, col)!.color == game.turn) {
          selectedRow = row;
          selectedCol = col;
        }
      } else {
        // Try to move the piece
        if (game.move(selectedRow!, selectedCol!, row, col)) {
          if (game.isCheckmate(game.turn)) {
            _showMessage(
              "${game.turn == PieceColor.white ? 'Black' : 'White'} wins by checkmate!",
            );
          }
        }
        selectedRow = null;
        selectedCol = null;
      }
    });
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Game Over", style: TextStyle(fontSize: 18.sp)),
            content: Text(message, style: TextStyle(fontSize: 16.sp)),
            actions: [
              TextButton(
                onPressed: () {
                  game = ChessBoardInterface();
                  game.turn = PieceColor.white;
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: Text("Restart", style: TextStyle(fontSize: 16.sp)),
              ),
            ],
          ),
    );
  }

  void _saveGame() async {
    String fen = game.toFEN();
    await StorageService.saveGameState(fen);
  }

  void _loadGame() async {
    String? fen = await StorageService.loadGameState();
    if (fen != null) {
      game = ChessBoardInterface(fen: fen);
      setState(() {});
    }
  }

  void _shareGame() {
    String fen = game.toFEN();
    Share.share("Check out my chess game:\n$fen");
  }

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chess Game"),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _saveGame),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadGame),
          IconButton(icon: Icon(Icons.share), onPressed: _shareGame),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: 64,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                ChessPiece? piece = game.getPiece(row, col);

                return GestureDetector(
                  onTap: () => onSquareTap(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          (row + col) % 2 == 0
                              ? Colors.brown[300]
                              : Colors.brown[700],
                      border:
                          (selectedRow == row && selectedCol == col)
                              ? Border.all(color: Colors.yellow, width: 3.w)
                              : null,
                    ),
                    child:
                        piece != null
                            ? Center(
                              child: Text(
                                getPieceSymbol(piece),
                                style: TextStyle(fontSize: 28.sp),
                              ),
                            )
                            : null,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Text(
              "${game.turn == PieceColor.white ? 'White' : 'Black'}'s turn",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String getPieceSymbol(ChessPiece piece) {
    Map<PieceType, Map<PieceColor, String>> symbols = {
      PieceType.pawn: {PieceColor.white: "♙", PieceColor.black: "♟"},
      PieceType.knight: {PieceColor.white: "♘", PieceColor.black: "♞"},
      PieceType.bishop: {PieceColor.white: "♗", PieceColor.black: "♝"},
      PieceType.rook: {PieceColor.white: "♖", PieceColor.black: "♜"},
      PieceType.queen: {PieceColor.white: "♕", PieceColor.black: "♛"},
      PieceType.king: {PieceColor.white: "♔", PieceColor.black: "♚"},
    };
    return symbols[piece.type]![piece.color]!;
  }
}
