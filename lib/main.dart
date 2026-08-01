import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/sign_in_screen.dart';

// Fill these in from your Supabase project's Settings -> API page,
// after creating a free project at https://supabase.com/dashboard.
// See README.md for step-by-step instructions.
const String supabaseUrl = 'https://ubuayuwnyrzoofusetsj.supabase.co';
const String supabaseAnonKey = 'sb_publishable_Kr3T2Cp3A85cfYyjDiIWRg_NTv35-YW';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: TeamSyncApp()));
}

class TeamSyncApp extends StatelessWidget {
  const TeamSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SignInScreen(),
    );
  }
}
