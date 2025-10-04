import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/catalog_page.dart';


// Read Supabase config from --dart-define at launch
const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty,
    'Missing Supabase config. Pass --dart-define SUPABASE_URL and SUPABASE_ANON_KEY.',
  );

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Showroom',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF060B13),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const CatalogPage(),
    );
  }
}