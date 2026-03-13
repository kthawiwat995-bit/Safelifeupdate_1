import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'dart:io' show Platform;

import 'Allpage/home_page.dart';
import 'Allpage/signin_page.dart';
import 'Allpage/signup_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เตรียม Google Maps renderer บน Android (ไม่ต้องกำหนด useAndroidViewSurface เพราะ deprecated แล้ว)
  if (Platform.isAndroid) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      try {
        await mapsImplementation.initializeWithRenderer(
          AndroidMapRenderer.platformDefault,
        );
      } catch (e) {
        debugPrint('Failed to initialize Google Maps Renderer: $e');
      }
    }
  }

  runApp(const SafeLifeApp());
}

class SafeLifeApp extends StatelessWidget {
  const SafeLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppStartup(),
      routes: {
        '/signin': (_) => const SigninPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

/// เริ่มต้น Firebase แยกจาก main() เพื่อไม่ให้แอพค้าง
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  bool _loading = true;
  bool _loggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));

      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _loggedIn = user != null;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Firebase init error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text(
                'กำลังเชื่อมต่อ...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return const SigninPage();
    }

    return _loggedIn ? const HomePage() : const SigninPage();
  }
}
