import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'pages/catalog_page.dart';
import 'pages/login_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/customer_provider.dart';
import 'providers/dress_provider.dart';
import 'providers/payment_provider.dart';

// Read Supabase config from --dart-define at launch
const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty,
    'Missing Supabase config. Pass --dart-define SUPABASE_URL and SUPABASE_ANON_KEY.',
  );

  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => DressProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSub;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _loggedIn = auth.currentSession != null;
    _authSub = auth.onAuthStateChange.listen((data) {
      // whenever user signs in/out, rebuild
      setState(() {
        _loggedIn = Supabase.instance.client.auth.currentSession != null;
      });
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Showroom',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF060B13),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: _loggedIn ? const CatalogPage() : const LoginPage(),
    );
  }
}
