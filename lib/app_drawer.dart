import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'history_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _exibirQRCode(BuildContext context, String familiaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Convidar Família"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Peça para o familiar escanear este código.",
                style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: familiaId,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.indigo),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(familiaId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.indigo),
            // Saza-chan Fix: Evita erro de 'null' se o usuário sair
            accountName: Text(user?.email?.split('@')[0].toUpperCase() ?? "USUÁRIO"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white, 
              child: Icon(Icons.person, color: Colors.indigo)
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.indigo),
            title: const Text("Lista de Compras"),
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage())),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.indigo),
            title: const Text("Dashboard"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DashboardPage())),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.indigo),
            title: const Text("Histórico"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryPage())),
          ),
          const Divider(),
          
          // Só busca os dados se o usuário ainda estiver logado
          if (user != null)
            FutureBuilder<DocumentSnapshot>(
              future: db.collection('usuarios').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  String familiaId = snapshot.data?['familiaId'] ?? "";
                  return ListTile(
                    leading: const Icon(Icons.qr_code_2, color: Colors.indigo),
                    title: const Text("Compartilhar Lista"),
                    onTap: () => _exibirQRCode(context, familiaId),
                  );
                }
                return const SizedBox();
              },
            ),
            
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Sair"),
            onTap: () async {
              await auth.signOut();
              if (context.mounted) {
                // Saza-chan Fix: Resetamos o app para a raiz (main.dart cuidará de mostrar o login)
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}