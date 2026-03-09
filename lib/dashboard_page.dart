import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'item_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _familiaId;
  double _metaMensal = 2000.0;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _getFamiliaId();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _getFamiliaId() async {
    final userDoc = await _db.collection('usuarios').doc(_auth.currentUser!.uid).get();
    if (mounted) setState(() => _familiaId = userDoc.data()?['familiaId']);
  }

  @override
  Widget build(BuildContext context) {
    if (_familiaId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Inteligência Financeira")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('estatisticas').doc(_familiaId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Sem dados registrados."));

          final rawData = snapshot.data!.data() as Map<String, dynamic>;
          final Map<String, double> gastosMensais = {};
          final Map<String, int> quantidades = {};
          final Map<String, double> gastoTotalPorItem = {};

          rawData.forEach((key, value) {
            if (key.startsWith('gastosMensais.')) gastosMensais[key.split('.').last] = (value as num).toDouble();
            if (key.startsWith('quantidadeAcumulada.')) quantidades[key.split('.').last] = (value as num).toInt();
            if (key.startsWith('gastoTotalPorItem.')) gastoTotalPorItem[key.split('.').last] = (value as num).toDouble();
          });

          double gastoMes = gastosMensais[DateFormat('yyyy_MM').format(DateTime.now())] ?? 0.0;
          double progresso = (gastoMes / _metaMensal).clamp(0.0, 1.0);
          bool alerta90 = gastoMes >= (_metaMensal * 0.9) && gastoMes <= _metaMensal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBudgetCard(gastoMes, progresso, alerta90),
                const SizedBox(height: 20),
                _buildSummaryCard(rawData),
                const SizedBox(height: 30),
                const Text("Evolução Mensal (R\$)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 10),
                _buildBarChart(gastosMensais),
                const SizedBox(height: 30),
                const Text("Top Consumo e Preço Médio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 10),
                _buildTopProducts(quantidades, gastoTotalPorItem),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(double atual, double progresso, bool alerta) {
    return Card(
      elevation: 4,
      color: Colors.indigo[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Orçamento de Março", style: TextStyle(color: Colors.white70)),
              if (alerta) FadeTransition(opacity: _blinkController, child: const Icon(Icons.warning_amber, color: Colors.orangeAccent)),
            ]),
            const SizedBox(height: 10),
            Text("R\$ ${atual.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: progresso, color: alerta ? Colors.orangeAccent : Colors.blueAccent, backgroundColor: Colors.white10, minHeight: 8),
            if (alerta) const Padding(padding: EdgeInsets.only(top: 8), child: Text("Cuidado! Você atingiu 90% da meta.", style: TextStyle(color: Colors.orangeAccent, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final total = (data['totalGastoGeral'] ?? 0.0).toDouble();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: Colors.indigo),
        title: const Text("Gasto Acumulado Total", style: TextStyle(fontSize: 12)),
        subtitle: Text("R\$ ${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> gastos) {
    var keys = gastos.keys.toList()..sort();
    return SizedBox(height: 180, child: BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(keys.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: gastos[keys[i]]!, color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(4))]))
    )));
  }

  Widget _buildTopProducts(Map<String, int> quantidades, Map<String, double> gastoFinanceiro) {
    var entries = quantidades.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    return Column(
      children: entries.take(5).map((item) {
        int index = entries.indexOf(item) + 1;
        final media = (gastoFinanceiro[item.key] ?? 0.0) / item.value;
        return ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(itemName: item.key, familiaId: _familiaId!))),
          leading: CircleAvatar(backgroundColor: Colors.indigo[50], child: Text("$index", style: const TextStyle(color: Colors.indigo))),
          title: Text(item.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Média: R\$ ${media.toStringAsFixed(2)}"),
          trailing: Text("${item.value} un", style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}