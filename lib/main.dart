import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(const MyApp()); // Remova o 'const' se o VS Code reclamar novamente
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stride Shopping',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[50],
          centerTitle: true,
          titleTextStyle: const TextStyle(color: Colors.indigo, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      // O segredo de não pedir login toda vez:
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.hasData ? const HomePage() : LoginPage();
        },
      ),
    );
  }
}