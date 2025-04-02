import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_chess/env.dart';
import 'ui_board.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.loadMaterials();

  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: ChessBoardUI(),
        );
      },
    );
  }
}
