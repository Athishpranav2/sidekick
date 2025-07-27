import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidetalk_feed.dart';

void main() {
  runApp(const SidetalkApp());
}

class SidetalkApp extends StatelessWidget {
  const SidetalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for consistent dark theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Sidetalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primarySwatch: Colors.red,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SidetalkFeed(),
    );
  }
}