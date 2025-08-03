import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/admob_service.dart';

import 'app.dart';

/// Entry point of the Sidekick application
///
/// This file handles:
/// - Flutter framework initialization
/// - Firebase initialization
/// - App startup
void main() async {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Google AdMob
  await AdMobService.initialize();

  // Start the app
  runApp(const MyApp());
}
