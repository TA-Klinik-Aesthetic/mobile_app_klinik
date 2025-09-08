import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:mobile_app_klinik/presentation/add_on_screen/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_export.dart';
import 'core/services/fcm_service.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load env (opsional)
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    // Firebase
    await Firebase.initializeApp();

    // Daftarkan background handler SEBELUM runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Prefs (jika dipakai di app)
    await PrefUtils().init();

    // FCM: izin + channel + listeners
    await FCMService.initialize();
    await FCMService.initializeNotificationListener();
    await FCMService.debugStatus();

    runApp(const MyApp());
  }, (error, stackTrace) {
    print('❌ Uncaught error: $error\n$stackTrace');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('id', 'ID');

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selected_language') ?? 'id';
      if (!mounted) return;
      setState(() {
        _locale = saved == 'en' ? const Locale('en', 'US') : const Locale('id', 'ID');
      });
    } catch (_) {}
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        // handle if needed
      }
    } catch (_) {}
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => print('Deep link: $uri'),
        onError: (err) => print('Deep link error: $err'),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'NAVYA HUB',
          theme: theme,
          locale: _locale,
          navigatorKey: FCMService.navigatorKey,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child ?? const SizedBox(),
            );
          },
        );
      },
    );
  }
}