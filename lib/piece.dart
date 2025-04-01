import 'package:flutter/material.dart';

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
