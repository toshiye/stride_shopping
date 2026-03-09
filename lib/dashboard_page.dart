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
    if (mounted) {
      setState(() {
        _familiaId = userDoc.data()?['familiaId'];
        _metaMensal = (userDoc.data()?['metaMensal'] ?? 2000.0).toDouble();
      });
    }
  }

  void _definirOrcamento() {
    final controller = TextEditingController(text: _metaMensal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Definir Orçamento Mensal"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Valor (R\$)", prefixText: "R\$ "),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              double novoValor = double.tryParse(controller.text.replaceAll(',', '.')) ?? _metaMensal;
              await _db.collection('usuarios').doc(_auth.currentUser!.uid).update({'metaMensal': novoValor});
              setState(() => _metaMensal = novoValor);
              Navigator.pop(context);
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_familiaId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Indigo")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('estatisticas').doc(_familiaId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Sem dados."));

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
          bool alerta90 = gastoMes >= (_metaMensal * 0.9);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InkWell(
                  onTap: _definirOrcamento,
                  borderRadius: BorderRadius.circular(20),
                  child: _buildBudgetCard(gastoMes, progresso, alerta90),
                ),
                const SizedBox(height: 20),
                _buildSummaryCard(gastoMes),
                const SizedBox(height: 30),
                const Text("Evolução Mensal (R\$)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 10),
                _buildBarChart(gastosMensais),
                const SizedBox(height: 30),
                const Text("Top Consumo e Preço Médio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
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
              const Text("Orçamento Mensal", style: TextStyle(color: Colors.white70)),
              if (alerta) FadeTransition(opacity: _blinkController, child: const Icon(Icons.warning_amber, color: Colors.orangeAccent)),
            ]),
            const SizedBox(height: 10),
            Text("R\$ ${atual.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: progresso, color: alerta ? Colors.orangeAccent : Colors.blueAccent, backgroundColor: Colors.white10, minHeight: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Meta: R\$ ${_metaMensal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double gastoMes) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet, color: Colors.indigo),
        title: const Text("Gasto no Mês Atual", style: TextStyle(fontSize: 12)),
        subtitle: Text("R\$ ${gastoMes.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> gastos) {
    var keys = gastos.keys.toList()..sort();
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50, // Espaço ajustado para os números não "voarem"
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
          barGroups: List.generate(keys.length, (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: gastos[keys[i]]!, color: Colors.indigo, width: 18, borderRadius: BorderRadius.circular(4))
          ])),
        ),
      ),
    );
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
          subtitle: Text("Preço Médio: R\$ ${media.toStringAsFixed(2)}"),
          trailing: Text("${item.value} un", style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}