import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      
      // Inicializa Notificações
      String? token = await NotificationService().getToken();
      if (token != null) {
        await _db.collection('usuarios').doc(_auth.currentUser!.uid).update({'fcmToken': token});
      }

      // Inicializa Motor de Voz
      await _voiceService.initVoice();
    }
  }

  Future<void> _finalizarCompra(List<QueryDocumentSnapshot> docs, double valorTotal) async {
    if (docs.isEmpty) return;
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compra finalizada e salva!")));
    }
  }

  void _editarItem(DocumentSnapshot doc) {
    final precoController = TextEditingController(text: doc['preco'].toString());
    final qtdController = TextEditingController(text: doc['quantidade'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar ${doc['nome']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: precoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Preço Unitário", prefixText: "R\$ "),
            ),
            TextField(
              controller: qtdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantidade"),
            ),
          ],
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

    // Função interna para processar comando natural e salvar (Usando RegEx para Nomes Compostos)
    void processarESalvar(String texto) {
      // Regex que procura a palavra 'adicionar' no início, seguida de um ou mais espaços, 
      // e captura TODO o restante da frase como o nome do item.
      final regExp = RegExp(r'^adicionar\s+(.+)$', caseSensitive: false);
      final match = regExp.firstMatch(texto.trim());
      
      if (match != null) {
        String nomeItem = match.group(1)!.trim(); // Captura o item completo (ex: "batata frita")
        
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
          Navigator.pop(context); // Fecha o diálogo sozinho após o sucesso
        }
      } else {
        // Caso você não diga "adicionar", ele apenas transcreve para o campo de texto
        controller.text = texto;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Comando de Voz Natural"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Diga 'Adicionar [item composto]'", 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: "Ouvindo..."),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.red : Colors.indigo,
                    ),
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