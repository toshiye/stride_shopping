import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'home_page.dart'; // Import necessário para navegar após o cadastro

class RegisterPage extends StatefulWidget {
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

  Future<void> _cadastrar(bool criarNovaFamilia, {String? codigoExistente}) async {
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
        // Mostra o código e só navega quando o usuário clicar em "Ir para a Lista"
        showDialog(
          context: context,
          barrierDismissible: false, // Força o usuário a interagir com o botão
          builder: (context) => AlertDialog(
            title: Text(criarNovaFamilia ? "Família Criada!" : "Bem-vindo!"),
            content: Text("O código da sua família é: $familiaId\nCompartilhe com sua esposa!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha o Dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
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
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-mail")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Senha"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregando ? null : () => _cadastrar(true),
              child: _carregando ? const CircularProgressIndicator() : const Text("Criar Nova Família"),
            ),
            TextButton(
              onPressed: () => _mostrarDialogoEntrarFamilia(),
              child: const Text("Já tenho um código de família"),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEntrarFamilia() {
    final _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Entrar em Família"),
        content: TextField(controller: _codeController, decoration: const InputDecoration(hintText: "Código de 6 dígitos")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo de input
              _cadastrar(false, codigoExistente: _codeController.text);
            }, 
            child: const Text("Entrar")
          ),
        ],
      ),
    );
  }
}