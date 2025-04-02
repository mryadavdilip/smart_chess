import 'package:flutter/material.dart';
import 'package:smart_chess/env.dart';

class BoardThemeConfig {
  Color boardColor;
  String materialVarity;
  BoardThemeConfig({required this.boardColor, required this.materialVarity});

  factory BoardThemeConfig.fromMap(Map<String, dynamic> map) =>
      BoardThemeConfig(
        boardColor: Color(map['boardColor'] ?? 0xAA000000),
        materialVarity:
            map['materialVarity'] ?? Environment.materialVarities.first,
      );

  Map<String, dynamic> toMap() => {
    'boardColor': boardColor.toARGB32(),
    'materialVarity': materialVarity,
  };
}
