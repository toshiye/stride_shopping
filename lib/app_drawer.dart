import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history_page.dart'; // Vamos criar esta em seguida
import 'dashboard_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo[100]),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.indigo, size: 40),
            ),
            accountName: const Text(
              "Gabriel",
              style: TextStyle(color: Colors.black87),
            ),
            accountEmail: Text(
              user?.email ?? "",
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text("Lista de Compras"),
            onTap: () => Navigator.pop(context), // Já estamos nela
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Histórico de Gastos"),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.blue),
            title: const Text("Dashboard de Inteligência"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Sair", style: TextStyle(color: Colors.red)),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
