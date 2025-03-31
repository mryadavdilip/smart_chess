import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String gameStateKey = "chess_game_state";

  static Future<void> saveGameState(String fen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(gameStateKey, fen);
  }

  static Future<String?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(gameStateKey);
  }
}
