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
  runApp(const MyApp());
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
          titleTextStyle: const TextStyle(
            color: Colors.indigo, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      // Definimos as rotas explicitamente para que o Navigator as encontre
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Widget auxiliar que gerencia o estado da sessão (O segredo do login persistente)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enquanto o Firebase checa a sessão, mostra o spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Se tem usuário logado, vai para Home. Se não, vai para Login.
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}