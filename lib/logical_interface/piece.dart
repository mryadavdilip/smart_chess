import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_chess/models/board_theme_config.dart';
import 'package:smart_chess/storage_service.dart';

enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

extension PieceColorExtension on PieceColor {
  Color toColor() => switch (this) {
    PieceColor.white => Colors.white,
    PieceColor.black => Colors.black,
  };
}

class ChessPiece {
  final PieceType type;
  final PieceColor color;

  ChessPiece({required this.type, required this.color});
}

extension ChessPieceExtension on ChessPiece {
  Future<Image> get getResource async {
    BoardThemeConfig config = await StorageService.getBoardConfig();
    bool sameFolderForBothColors = Directory(
      'assets/materials/${config.materialVarity}',
    ).listSync().any((e) => !e.path.split('/').last.contains('.'));
    String path =
        'assets/materials/${config.materialVarity}/${sameFolderForBothColors ? '' : '${color.name}/${type.name}.png'}';

    return Image.asset(
      path,
      color: sameFolderForBothColors ? color.toColor() : null,
      fit: BoxFit.contain,
    );
  }
}
