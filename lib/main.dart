import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gosshiping/core/theme/theme_provider.dart';
import 'package:gosshiping/ui/auth/login.dart';
import 'package:gosshiping/ui/home/home.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Zokua',
        themeMode: themeProvider.themeMode,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF38BDF8),
            brightness: Brightness.dark,
          ),
        ),
        home: FirebaseAuth.instance.currentUser == null
            ? const LoginPage()
            : const HomePage(),
      ),
    );
  }
}
