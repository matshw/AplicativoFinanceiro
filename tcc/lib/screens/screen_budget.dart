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

  void _showActionSheet(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final String docID = document.id;
    final String nome = data['nome'];
    final double valor = (data['valor'] ?? 0.0).toDouble();
    final String imagem = data['imagem'] ?? '';
    final String formaPagamento = data['formaPagamento'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
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
              leading: Icon(Icons.delete),
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
              leading: Icon(Icons.cancel),
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
    final String nome = data['nome'];
    final double valor = (data['valor'] ?? 0.0).toDouble();
    final String formaPagamento = data['formaPagamento'] ?? 'N/A';
    final String imagem = data['imagem'] ?? '';

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
                    double.parse(valorController.text),
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
      'nome': nome,
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Erro: Usuário não autenticado.'));
    }

    return Scaffold(
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
              final String nome = data['nome'];
              final double valor = (data['valor'] ?? 0.0).toDouble();
              final String imagem = data['imagem'] ?? '';
              final String formaPagamento = data['formaPagamento'] ?? 'N/A';

              return ListTile(
                leading: imagem.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(imagem),
                        radius: 30,
                      )
                    : const Icon(Icons.subscriptions, size: 30),
                title: Text(
                  nome,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  '${currencyFormatter.format(valor)} - $formaPagamento',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showActionSheet(document);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
