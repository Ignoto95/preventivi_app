import 'package:flutter/material.dart';
import 'services/preventivo_service.dart';

class CreatePreventivoPage extends StatefulWidget {
  @override
  _CreatePreventivoPageState createState() => _CreatePreventivoPageState();
}

class _CreatePreventivoPageState extends State<CreatePreventivoPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final PreventivoService preventivoService = PreventivoService();

  Future<void> savePreventivo() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

    if (name.isEmpty || description.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compila tutti i campi correttamente')),
      );
      return;
    }

    try {
      await preventivoService.savePreventivo({
        'name': name,
        'description': description,
        'amount': amount,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preventivo salvato con successo!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crea Preventivo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nome Cliente'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Descrizione'),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Importo (€)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: savePreventivo,
              child: Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
