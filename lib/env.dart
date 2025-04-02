import 'package:smart_chess/logical_interface/piece.dart';

Map<String, dynamic> materialsResources = {
  'modern_minimalist': PieceType.values.map((e) => '${e.name}.png').toList(),
  'silhoutte_minimalist': {
    'black': PieceType.values.map((e) => '${e.name}.png').toList(),
    'white': PieceType.values.map((e) => '${e.name}.png').toList(),
  },
};
