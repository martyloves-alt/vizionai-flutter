import 'package:flutter/material.dart';

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
      home: const VizionAISplash(),
    );
  }
}

class VizionAISplash extends StatelessWidget {
  const VizionAISplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VizionAI',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'STUDIO',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 11,
                letterSpacing: 8,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Initialisation du moteur...',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
