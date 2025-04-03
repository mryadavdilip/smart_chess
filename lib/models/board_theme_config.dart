import 'package:flutter/material.dart';
import 'package:smart_chess/env.dart';

class BoardThemeConfig {
  Color boardColor;
  String materialVarity;
  BoardThemeConfig({required this.boardColor, required this.materialVarity});

  factory BoardThemeConfig.fromMap(Map<String, dynamic> map) =>
      BoardThemeConfig(
        boardColor: Color(map['boardColor'] as int? ?? Colors.brown.toARGB32()),
        materialVarity: map['materialVarity'] ?? materialsResources.keys.last,
      );

  Map<String, dynamic> toMap() => {
    'boardColor': boardColor.toARGB32(),
    'materialVarity': materialVarity,
  };
}
