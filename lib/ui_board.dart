import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_chess/models/board_theme_config.dart';
import 'package:smart_chess/storage_service.dart';
import 'package:smart_chess/color_extension.dart';
import 'package:gradient_circular_progress_indicator/gradient_circular_progress_indicator.dart';
import 'package:smart_chess/logical_interface/chess_board_interface.dart';
import 'package:smart_chess/logical_interface/piece.dart';

class ChessBoardUI extends StatefulWidget {
  const ChessBoardUI({super.key});

  @override
  State<ChessBoardUI> createState() => _ChessBoardUIState();
}

class _ChessBoardUIState extends State<ChessBoardUI> {
  ChessBoardInterface game = ChessBoardInterface();
  Position? selectedPosition;
  List<Position> validMoves = [];

  // Define board size using ScreenUtil for responsive design
  Size boardSize = Size(360.w, 360.w);

  void onSquareTap(int row, int col) {
    Position tappedPosition = Position(row: row, col: col);
    ChessPiece? piece = game.getPiece(tappedPosition);

    // If it's your turn and you tap on a pawn on the promotion rank, show the promotion dialog.
    if (piece != null &&
        piece.color == game.turn &&
        piece.type == PieceType.pawn &&
        (tappedPosition.row == 0 || tappedPosition.row == 7)) {
      _showPromotionDialog(tappedPosition);
      return; // Exit so that the normal selection/move logic isn't executed.
    }

    // Normal selection/move process:
    if (selectedPosition == null) {
      if (piece != null && piece.color == game.turn) {
        selectedPosition = tappedPosition;
        validMoves = game.getValidMoves(tappedPosition);
      }
    } else {
      // If a piece is already selected, attempt to move it.
      if (game.move(selectedPosition!, tappedPosition)) {
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
            title: const Text("Promote Pawn"),
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
            title: const Text("Game Over"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  game = ChessBoardInterface();
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text("Restart"),
              ),
            ],
          ),
    );
  }

  void _saveGame() async {
    String fen = game.toFEN();
    await StorageService.saveGameState(fen);
  }

  void _resetGame() {
    game = ChessBoardInterface();
    setState(() {});
  }

  void _shareGame() {
    String fen = game.toFEN();
    Share.share("Check out my chess game:\n$fen");
  }

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Chess"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveGame),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareGame),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: StorageService.getBoardConfig(),
            builder: (context, configSS) {
              BoardThemeConfig? config = configSS.data;

              return SizedBox(
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
                    bool isWhite = (row + col) % 2 == 0;

                    Position pos = Position(row: row, col: col);
                    ChessPiece? piece = game.getPiece(pos);

                    return GestureDetector(
                      onTap: () => onSquareTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isWhite
                                  ? config?.boardColor.toMaterialColor()[1]
                                  : config?.boardColor.toMaterialColor()[2],
                          border:
                              selectedPosition == pos
                                  ? Border.all(
                                    color: game.turn.toColor(),
                                    width: 3.w,
                                  )
                                  : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (validMoves.contains(pos))
                              GradientCircularProgressIndicator(
                                progress: 100,
                                stroke: 3.sp,
                                size:
                                    game.board[row][col] == null
                                        ? (boardSize.width / 8) - 5.sp
                                        : (boardSize.width / 8) - 20.sp,
                                gradient: SweepGradient(
                                  transform: GradientRotation(45),
                                  colors: [
                                    game.turn.toColor(),
                                    config?.boardColor.toMaterialColor()[1] ??
                                        Colors.white,
                                    config?.boardColor.toMaterialColor()[2] ??
                                        Colors.black,
                                  ],
                                ),
                              ),
                            // Container(
                            //   height: 20.w,
                            //   width: 20.w,
                            //   decoration: BoxDecoration(),
                            // ),
                            FutureBuilder(
                              key: ValueKey('$row-$col-${piece?.type}'),
                              future: piece?.getResource,
                              builder: (context, ss) {
                                return Padding(
                                  padding: EdgeInsets.all(
                                    piece?.type == PieceType.pawn ? 10 : 5.sp,
                                  ),
                                  child: ss.data ?? SizedBox.shrink(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                onPressed:
                    game.canUndo()
                        ? () {
                          game.undo();
                          setState(() {});
                        }
                        : null,
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              MaterialButton(
                onPressed:
                    game.canRedo()
                        ? () {
                          game.redo();
                          setState(() {});
                        }
                        : null,
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
