import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // <--- ADICIONADO: Essencial para o DateFormat

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
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          List<Map<String, dynamic>> registros = [];
          for (var doc in snapshot.data!.docs) {
            final itens = doc['itens'] as List;
            final data = (doc['dataCompra'] as Timestamp?)?.toDate() ?? DateTime.now();
            for (var item in itens) {
              if (item['nome'] == itemName.toLowerCase()) {
                registros.add({
                  'data': data,
                  'preco': (item['precoUnitario'] as num).toDouble(),
                });
              }
            }
          }

          // Ordenação manual por data (crescente para o gráfico)
          registros.sort((a, b) => a['data'].compareTo(b['data']));

          List<FlSpot> spots = [];
          for (int i = 0; i < registros.length; i++) {
            spots.add(FlSpot(i.toDouble(), registros[i]['preco']));
          }

          if (spots.isEmpty) return const Center(child: Text("Nenhum histórico encontrado para este item."));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Evolução do Preço Unitário", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200, 
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50, // Espaço ajustado para o preço não voar
                            getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots, 
                          color: Colors.indigo, 
                          isCurved: true, 
                          barWidth: 4, 
                          dotData: const FlDotData(show: true)
                        )
                      ],
                    )
                  )
                ),
                const SizedBox(height: 30),
                const Divider(),
                const Text("Registros Encontrados", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      // Mostramos do mais novo para o mais velho na lista
                      final reg = registros[registros.length - 1 - index];
                      return ListTile(
                        leading: const Icon(Icons.history, color: Colors.indigo),
                        title: Text("R\$ ${reg['preco'].toStringAsFixed(2)}"),
                        subtitle: Text("Data: ${DateFormat('dd/MM/yyyy').format(reg['data'])}"),
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