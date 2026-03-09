import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ItemDetailPage extends StatelessWidget {
  final String itemName;
  final String familiaId;
  const ItemDetailPage({super.key, required this.itemName, required this.familiaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(itemName.toUpperCase())),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('historico')
            .where('familiaId', isEqualTo: familiaId)
            .orderBy('dataCompra', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          List<FlSpot> spots = [];
          List<Map<String, dynamic>> registros = [];
          int i = 0;

          for (var doc in snapshot.data!.docs) {
            final itens = doc['itens'] as List;
            final data = (doc['dataCompra'] as Timestamp?)?.toDate() ?? DateTime.now();
            for (var item in itens) {
              if (item['nome'] == itemName.toLowerCase()) {
                double preco = (item['precoUnitario'] as num).toDouble();
                spots.add(FlSpot(i.toDouble(), preco));
                registros.add({'data': data, 'preco': preco});
                i++;
              }
            }
          }

          if (spots.isEmpty) return const Center(child: Text("Nenhum histórico encontrado."));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Evolução do Preço Unitário", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),
                SizedBox(height: 200, child: LineChart(LineChartData(
                  lineBarsData: [LineChartBarData(spots: spots, color: Colors.indigo, isCurved: true, barWidth: 4, dotData: const FlDotData(show: true))],
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ))),
                const SizedBox(height: 30),
                const Divider(),
                const Text("Registros Encontrados", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      final reg = registros[registros.length - 1 - index]; // Ordem inversa
                      return ListTile(
                        leading: const Icon(Icons.history, color: Colors.indigo),
                        title: Text("R\$ ${reg['preco'].toStringAsFixed(2)}"),
                        subtitle: Text("Data: ${reg['data'].day}/${reg['data'].month}/${reg['data'].year}"),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}