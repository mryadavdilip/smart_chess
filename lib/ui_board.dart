import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_chess/storage_service.dart';
import 'logical_interface/chess_board_interface.dart';
import 'logical_interface/piece.dart';

class ChessBoardUI extends StatefulWidget {
  const ChessBoardUI({super.key});

  @override
  State<ChessBoardUI> createState() => _ChessBoardUIState();
}

class _ChessBoardUIState extends State<ChessBoardUI> {
  ChessBoardInterface game = ChessBoardInterface();
  Position? selectedPosition;
  List<Position> validMoves = [];

  Size boardSize = Size(360.w, 360.w);

  void onSquareTap(int row, int col) {
    Position tappedPosition = Position(row: row, col: col);
    if (selectedPosition == null) {
      // Select piece
      ChessPiece? piece = game.getPiece(tappedPosition);
      if (piece != null && piece.color == game.turn) {
        selectedPosition = tappedPosition;
        validMoves = game.getValidMoves(tappedPosition);
      }
    } else {
      // Try to move the piece
      if (game.move(selectedPosition!, tappedPosition)) {
        game.history.add(game.toFEN()); // Save the current state
        checkForPawnPromotion(tappedPosition);
        if (game.isCheckmate(game.turn)) {
          _showMessage(
            "${game.turn == PieceColor.white ? 'Black' : 'White'} wins by checkmate!",
          );
        }
      }
      selectedPosition = null;
      validMoves = [];
    }
    setState(() {});
  }

  void checkForPawnPromotion(Position position) {
    ChessPiece? piece = game.getPiece(position);
    if (piece?.type == PieceType.pawn) {
      if (position.row == 0 || position.row == 7) {
        _showPromotionDialog(position);
      }
    }
  }

  void _showPromotionDialog(Position position) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Promote Pawn"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var type in [
                  PieceType.queen,
                  PieceType.rook,
                  PieceType.bishop,
                  PieceType.knight,
                ])
                  ListTile(
                    title: Text(type.toString().split('.').last),
                    onTap: () {
                      game.promotePawn(position, type);
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Game Over"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  game = ChessBoardInterface();
                  game.turn = PieceColor.white;
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: Text("Restart"),
              ),
            ],
          ),
    );
  }

  void _saveGame() async {
    String fen = game.toFEN();
    await StorageService.saveGameState(fen);
  }

  void _resetGame() async {
    game = ChessBoardInterface();
    setState(() {});
  }

  void _shareGame() {
    String fen = game.toFEN();
    Share.share("Check out my chess game:\n$fen");
  }

  Object assetKey = Object();

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    assetKey = Object();

    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Chess"),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _saveGame),
          IconButton(icon: Icon(Icons.refresh), onPressed: _resetGame),
          IconButton(icon: Icon(Icons.share), onPressed: _shareGame),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: boardSize.height,
            width: boardSize.width,
            child: GridView.builder(
              itemCount: 64,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                mainAxisExtent: boardSize.height / 8,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                Position pos = Position(row: row, col: col);
                ChessPiece? piece = game.getPiece(pos);
                bool isHighlighted = validMoves.contains(pos);

                return GestureDetector(
                  onTap: () => onSquareTap(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isHighlighted
                              ? Colors.green.withValues(alpha: 0.5)
                              : (row + col) % 2 == 0
                              ? Colors.brown[300]
                              : Colors.brown[700],
                      border:
                          selectedPosition == pos
                              ? Border.all(color: Colors.yellow, width: 3.w)
                              : null,
                    ),
                    child: FutureBuilder(
                      key: ValueKey<Object>(assetKey),
                      future: piece?.getResource,
                      builder: (context, snapshot) {
                        return Padding(
                          padding: EdgeInsets.all(
                            piece?.type == PieceType.pawn ? 10 : 5.sp,
                          ),
                          child: snapshot.data ?? Center(),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              MaterialButton(
                onPressed:
                    game.canUndo()
                        ? () {
                          game.undo();
                          setState(() {});
                        }
                        : null,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              MaterialButton(
                onPressed:
                    game.canRedo()
                        ? () {
                          game.redo();
                          setState(() {});
                        }
                        : null,
                child: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // String getPieceSymbol(ChessPiece piece) {
  //   Map<PieceType, Map<PieceColor, String>> symbols = {
  //     PieceType.pawn: {PieceColor.white: "♙", PieceColor.black: "♟"},
  //     PieceType.knight: {PieceColor.white: "♘", PieceColor.black: "♞"},
  //     PieceType.bishop: {PieceColor.white: "♗", PieceColor.black: "♝"},
  //     PieceType.rook: {PieceColor.white: "♖", PieceColor.black: "♜"},
  //     PieceType.queen: {PieceColor.white: "♕", PieceColor.black: "♛"},
  //     PieceType.king: {PieceColor.white: "♔", PieceColor.black: "♚"},
  //   };
  //   return symbols[piece.type]![piece.color]!;
  // }
}
