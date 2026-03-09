import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Compras"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final familiaId = userSnapshot.data?['familiaId'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('historico')
                .where('familiaId', isEqualTo: familiaId)
                .orderBy('dataCompra', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("Nenhuma compra finalizada ainda."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  
                  // CORREÇÃO: Usamos o nome do campo da HomePage e garantimos que não seja null
                  final double total = (data['valorTotalCompra'] ?? data['valorTotal'] ?? 0.0).toDouble();
                  final DateTime dataCompra = (data['dataCompra'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final List itens = data['itens'] ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        DateFormat('dd/MM/yyyy - HH:mm').format(dataCompra),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Total: R\$ ${total.toStringAsFixed(2)}", // Aqui não dá mais erro!
                        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                      ),
                      children: itens.map((item) {
                        return ListTile(
                          dense: true,
                          title: Text(item['nome'].toString().toUpperCase()),
                          trailing: Text(
                            "${item['quantidade']}x R\$ ${(item['precoUnitario'] ?? 0.0).toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}