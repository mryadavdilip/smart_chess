import 'dart:convert';

import 'package:chess_interface/models/board_theme_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String boardConfigKey = "chess_board_config";
  static const String gameStateKey = "chess_game_state";

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<void> saveGameState(String fen) async {
    await (await _prefs).setString(gameStateKey, fen);
  }

  static Future<String?> loadGameState() async {
    return (await _prefs).getString(gameStateKey);
  }

  static Future<bool> setBoardConfig(BoardThemeConfig config) async {
    return await (await _prefs).setString(
      boardConfigKey,
      jsonEncode(config.toMap()),
    );
  }

  static Future<BoardThemeConfig> getBoardConfig() async {
    return BoardThemeConfig.fromMap(
      (await _prefs).containsKey(boardConfigKey)
          ? jsonDecode((await _prefs).getString(boardConfigKey) ?? '')
          : {},
    );
  }
}
