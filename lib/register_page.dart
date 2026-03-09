import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'home_page.dart';
import 'scanner_page.dart'; // NOVO: Import do Scanner

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  bool _carregando = false;

  String _gerarCodigoFamilia() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  // Refatorado para aceitar o ID vindo do scanner ou do campo de texto
  Future<void> _cadastrar(bool criarNovaFamilia, {String? codigoExistente}) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha e-mail e senha primeiro!")));
      return;
    }

    setState(() => _carregando = true);
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String familiaId = criarNovaFamilia ? _gerarCodigoFamilia() : codigoExistente!;

      await _db.collection('usuarios').doc(userCred.user!.uid).set({
        'email': _emailController.text,
        'familiaId': familiaId,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(criarNovaFamilia ? "Família Criada!" : "Bem-vindo!"),
            content: Text("O código da sua família é: $familiaId\nCompartilhe com sua família!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha o Dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                }, 
                child: const Text("Ir para a Lista")
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Conta Stride")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Protege contra o teclado cobrindo campos
          child: Column(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-mail", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Senha", border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _carregando ? null : () => _cadastrar(true),
                  child: _carregando ? const CircularProgressIndicator(color: Colors.white) : const Text("Criar Nova Família"),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _mostrarDialogoEntrarFamilia(),
                child: const Text("Já tenho um código ou QR Code", style: TextStyle(color: Colors.indigo)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEntrarFamilia() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Entrar em Família"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Escaneie o QR Code ou digite o código de 6 dígitos:", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            
            // BOTÃO DO SCANNER (ESTRELA DA NOITE)
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Escanear QR Code"),
              onPressed: () async {
                Navigator.pop(context); // Fecha o diálogo atual
                // Abre a câmera
                final String? codigoEscaneado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ScannerPage()),
                );
                
                if (codigoEscaneado != null) {
                  _cadastrar(false, codigoExistente: codigoEscaneado);
                }
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("OU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            
            TextField(
              controller: codeController, 
              decoration: const InputDecoration(hintText: "Código manual", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (codeController.text.isNotEmpty) {
                _cadastrar(false, codigoExistente: codeController.text);
              }
            }, 
            child: const Text("Entrar Manualmente")
          ),
        ],
      ),
    );
  }
}