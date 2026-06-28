import 'package:flutter/material.dart';
import 'screens/studio_screen.dart';

void main() {
  runApp(const VizionAIApp());
}

class VizionAIApp extends StatelessWidget {
  const VizionAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VizionAI Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          surface: Color(0xFF111111),
        ),
      ),
      home: const StudioScreen(),
    );
  }
}
