import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

class ScreenBudget extends StatefulWidget {
  @override
  _ScreenBudgetState createState() => _ScreenBudgetState();
}

class _ScreenBudgetState extends State<ScreenBudget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Erro: Usuário não autenticado.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Assinaturas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('assinaturas')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar assinaturas.'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma assinatura encontrada.'));
          }

          final assinaturas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: assinaturas.length,
            itemBuilder: (context, index) {
              final document = assinaturas[index];
              final data = document.data() as Map<String, dynamic>;
              final String nome = data['descricao'] ?? '';
              final double valor = (data['valor'] ?? 0.0).toDouble();
              final int periodo = data['periodo'] ?? 30;
              final DateTime dataCriacao = data['data'] != null
                  ? (data['data'] as Timestamp).toDate()
                  : DateTime.now();

              final String formattedDate = DateFormat('dd/MM/yyyy')
                  .format(dataCriacao.add(Duration(days: periodo)));

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 5,
                child: ListTile(
                  title: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Valor: ${currencyFormatter.format(valor)} - Vencimento: $formattedDate',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showActionSheet(document);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showActionSheet(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final String docID = document.id;
    final String nome = data['descricao'] ?? '';
    final double valor = (data['valor'] ?? 0.0).toDouble();
    final String imagem = data['imagem'] ?? '';
    final String formaPagamento = data['formaPagamento'] ?? 'N/A';
    final String categoria = data['categoria'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text(
                'Editar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text(
                'Marcar como Pago',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _markAsPaid(docID, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text(
                'Excluir',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeAssinatura(docID, valor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            if (imagem.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text(
                  'Ver imagem',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImageDialog(imagem);
                },
              ),
          ],
        );
      },
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Imagem da Assinatura"),
          content: Image.network(imageUrl),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final String nome = data['descricao'] ?? '';
    final double valor = (data['valor'] ?? 0.0).toDouble();
    final String formaPagamento = data['formaPagamento'] ?? 'N/A';

    TextEditingController nomeController = TextEditingController(text: nome);
    TextEditingController valorController =
        TextEditingController(text: valor.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Assinatura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _updateAssinatura(
                    document.id,
                    nomeController.text,
                    double.tryParse(valorController.text) ?? 0.0,
                    formaPagamento,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _updateAssinatura(
      String docID, String nome, double valor, String formaPagamento) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assinaturas')
        .doc(docID)
        .update({
      'descricao': nome,
      'valor': valor,
      'formaPagamento': formaPagamento,
    });
  }

  void _removeAssinatura(String docID, double valor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assinaturas')
        .doc(docID)
        .delete();
  }

  void _markAsPaid(String docID, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Calcular o novo vencimento baseado no período
    int periodo = data['periodo'] ?? 30; // Período atual da assinatura
    DateTime novoVencimento = DateTime.now().add(Duration(days: periodo));

    // Atualizar a data da assinatura e criar a transação
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assinaturas')
        .doc(docID)
        .update({
      'data': Timestamp.fromDate(novoVencimento), // Atualiza a data
    }).then((_) {
      // Adicionar a transação ao histórico com categoria e meio de pagamento
      _addTransaction(
        nome: data['descricao'],
        valor: data['valor'],
        tipo: 'gasto',
        vencimento: novoVencimento,
        formaPagamento: data['formaPagamento'] ?? 'N/A',
        categoria: data['categoria'] ?? 'N/A',
      );
      // Mostrar um feedback ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Assinatura marcada como paga e vencimento atualizado.')),
      );
    }).catchError((error) {
      print("Erro ao atualizar a assinatura: $error");
    });
  }

  void _addTransaction({
    required String nome,
    required double valor,
    required String tipo,
    required DateTime vencimento,
    required String formaPagamento,
    required String categoria,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore.collection('users').doc(user.uid).collection('transacao').add({
      'descricao': nome,
      'valor': valor,
      'data': Timestamp.fromDate(vencimento),
      'tipo': tipo,
      'meioPagamento': formaPagamento,
      'categoria': categoria,
    }).then((_) {
      print("Transação adicionada com sucesso!");
    }).catchError((error) {
      print("Erro ao adicionar transação: $error");
    });
  }
}
