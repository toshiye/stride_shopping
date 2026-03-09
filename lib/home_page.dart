import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart'; // Essencial para as datas
import 'app_drawer.dart';
import 'notification_service.dart';
import 'voice_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final VoiceService _voiceService = VoiceService();
  String? _familiaId;

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    final userDoc = await _db.collection('usuarios').doc(_auth.currentUser!.uid).get();
    if (mounted) {
      setState(() {
        _familiaId = userDoc.data()?['familiaId'];
      });
      
      String? token = await NotificationService().getToken();
      if (token != null) {
        await _db.collection('usuarios').doc(_auth.currentUser!.uid).update({'fcmToken': token});
      }

      await _voiceService.initVoice();
    }
  }

  // --- MOTOR DE INTELIGÊNCIA DE PREÇOS ---
  Future<double?> _obterPrecoMedio(String nomeItem) async {
    try {
      final doc = await _db.collection('estatisticas').doc(_familiaId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String item = nomeItem.toLowerCase().trim();

        final gastoTotal = data['gastoTotalPorItem.$item'];
        final qtdTotal = data['quantidadeAcumulada.$item'];

        if (gastoTotal != null && qtdTotal != null && (qtdTotal as num) > 0) {
          return (gastoTotal as num).toDouble() / (qtdTotal as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar média: $e");
    }
    return null;
  }

  // --- ATUALIZAÇÃO DE ESTATÍSTICAS (O CORAÇÃO DO DASHBOARD) ---
  Future<void> _atualizarEstatisticas(List<QueryDocumentSnapshot> docs, double totalCompra) async {
    final statsRef = _db.collection('estatisticas').doc(_familiaId);
    String mesAno = DateFormat('yyyy_MM').format(DateTime.now());
    
    Map<String, dynamic> updates = {
      'totalGastoGeral': FieldValue.increment(totalCompra),
      'gastosMensais.$mesAno': FieldValue.increment(totalCompra),
      'ultimaCompra': FieldValue.serverTimestamp(),
    };

    for (var doc in docs) {
      String nome = doc['nome'].toString().toLowerCase().trim();
      double preco = (doc['preco'] ?? 0.0).toDouble();
      int qtd = (doc['quantidade'] ?? 1).toInt();
      double totalItem = preco * qtd;

      updates['gastoTotalPorItem.$nome'] = FieldValue.increment(totalItem);
      updates['quantidadeAcumulada.$nome'] = FieldValue.increment(qtd);
      updates['frequencia.$nome'] = FieldValue.increment(1);
      updates['ultimoPreco.$nome'] = preco;
    }

    await statsRef.set(updates, SetOptions(merge: true));
  }

  Future<void> _finalizarCompra(List<QueryDocumentSnapshot> docs, double valorTotal) async {
    if (docs.isEmpty) return;
    
    // Feedback de carregamento
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      WriteBatch batch = _db.batch();
      DocumentReference histRef = _db.collection('historico').doc();
      
      batch.set(histRef, {
        'familiaId': _familiaId,
        'dataCompra': FieldValue.serverTimestamp(),
        'valorTotalCompra': valorTotal,
        'itens': docs.map((doc) => {
          'nome': doc['nome'].toString().trim().toLowerCase(),
          'quantidade': doc['quantidade'] ?? 1,
          'precoUnitario': (doc['preco'] ?? 0.0).toDouble(),
        }).toList(),
      });

      for (var doc in docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      // ATUALIZAÇÃO CRUCIAL: Dashboard volta a funcionar aqui
      await _atualizarEstatisticas(docs, valorTotal);

      if (mounted) {
        Navigator.pop(context); // Remove o loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compra finalizada e estatísticas atualizadas!"))
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Erro ao finalizar: $e");
    }
  }

  // --- EDIÇÃO COM AUTO-SELEÇÃO E INTELIGÊNCIA ---
  void _editarItem(DocumentSnapshot doc) {
    final precoController = TextEditingController(text: doc['preco'].toString());
    final qtdController = TextEditingController(text: doc['quantidade'].toString());
    
    // LOGICA SAZA-CHAN: Seleciona tudo para facilitar a troca de valores
    precoController.selection = TextSelection(baseOffset: 0, extentOffset: precoController.text.length);
    qtdController.selection = TextSelection(baseOffset: 0, extentOffset: qtdController.text.length);

    String nomeItem = doc['nome'].toString().toLowerCase();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar ${nomeItem.toUpperCase()}"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<double?>(
                future: _obterPrecoMedio(nomeItem),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                  
                  final media = snapshot.data;
                  if (media == null) return const Text("Sem histórico para este item.", style: TextStyle(fontSize: 10, color: Colors.grey));

                  double precoAtual = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0;
                  bool eBarato = precoAtual <= media;
                  double diff = media > 0 ? ((precoAtual - media) / media * 100).abs() : 0.0;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: eBarato ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(eBarato ? Icons.trending_down : Icons.trending_up, color: eBarato ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eBarato 
                              ? "Preço bom! ${diff.toStringAsFixed(0)}% abaixo da média (R\$ ${media.toStringAsFixed(2)})"
                              : "Está caro! ${diff.toStringAsFixed(0)}% acima da média (R\$ ${media.toStringAsFixed(2)})",
                            style: TextStyle(fontSize: 11, color: eBarato ? Colors.green[900] : Colors.red[900]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: precoController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Preço Unitário", prefixText: "R\$ "),
                onChanged: (val) => setDialogState(() {}),
                onTap: () => precoController.selection = TextSelection(baseOffset: 0, extentOffset: precoController.text.length),
              ),
              TextField(
                controller: qtdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantidade"),
                onTap: () => qtdController.selection = TextSelection(baseOffset: 0, extentOffset: qtdController.text.length),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              String precoTexto = precoController.text.replaceAll(',', '.');
              doc.reference.update({
                'preco': double.tryParse(precoTexto) ?? 0.0,
                'quantidade': int.tryParse(qtdController.text) ?? 1,
              });
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
      appBar: AppBar(
        title: Text("Lista: $_familiaId"),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('compras').where('familiaId', isEqualTo: _familiaId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final docs = snapshot.data!.docs;
              double total = docs.fold(0.0, (acum, doc) => acum + ((doc['preco'] ?? 0.0) * (doc['quantidade'] ?? 1)));
              
              return Row(
                children: [
                  Text("R\$ ${total.toStringAsFixed(2)}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.indigo),
                    onPressed: docs.isEmpty ? null : () => _finalizarCompra(docs, total),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _exibirDialogoAdicionar(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('compras')
            .where('familiaId', isEqualTo: _familiaId)
            .orderBy('finalizado', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index];
              bool finalizado = item['finalizado'] ?? false;
              double precoTotal = (item['preco'] ?? 0.0) * (item['quantidade'] ?? 1);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  onTap: () => _editarItem(item),
                  leading: Checkbox(
                    value: finalizado,
                    activeColor: Colors.indigo,
                    onChanged: (val) => item.reference.update({'finalizado': val}),
                  ),
                  title: Text(item['nome'].toString().toUpperCase(), 
                    style: TextStyle(
                      decoration: finalizado ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.bold,
                      color: finalizado ? Colors.grey : Colors.indigo[900]
                    )),
                  subtitle: Text("${item['quantidade']}x R\$ ${item['preco'].toStringAsFixed(2)} = R\$ ${precoTotal.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => item.reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _exibirDialogoAdicionar() {
    final controller = TextEditingController();
    bool isListening = false;

    void processarESalvar(String texto) {
      final regExp = RegExp(r'^adicionar\s+(.+)$', caseSensitive: false);
      final match = regExp.firstMatch(texto.trim());
      
      if (match != null) {
        String nomeItem = match.group(1)!.trim();
        if (nomeItem.isNotEmpty) {
          _db.collection('compras').add({
            'nome': nomeItem,
            'finalizado': false,
            'familiaId': _familiaId,
            'quantidade': 1,
            'preco': 0.0,
            'criadoEm': FieldValue.serverTimestamp(),
          });
          _voiceService.stopListening();
          Navigator.pop(context);
        }
      } else {
        controller.text = texto;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Novo Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: "Diga 'Adicionar [item]'"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.red : Colors.indigo),
                    onPressed: () {
                      if (!isListening) {
                        setDialogState(() => isListening = true);
                        _voiceService.startListening((text) {
                          setDialogState(() {
                            processarESalvar(text);
                            isListening = false;
                          });
                        });
                      } else {
                        _voiceService.stopListening();
                        setDialogState(() => isListening = false);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _db.collection('compras').add({
                    'nome': controller.text,
                    'finalizado': false,
                    'familiaId': _familiaId,
                    'quantidade': 1,
                    'preco': 0.0,
                    'criadoEm': FieldValue.serverTimestamp(),
                  });
                }
                Navigator.pop(context);
              }, 
              child: const Text("Adicionar", style: TextStyle(color: Colors.indigo))
            ),
          ],
        ),
      ),
    );
  }
}