import 'package:flutter/material.dart';
import 'services/preventivo_service.dart';

class SearchPreventivoPage extends StatefulWidget {
  @override
  _SearchPreventivoPageState createState() => _SearchPreventivoPageState();
}

class _SearchPreventivoPageState extends State<SearchPreventivoPage> {
  final TextEditingController searchController = TextEditingController();
  final PreventivoService preventivoService = PreventivoService();
  List<Map<String, dynamic>> searchResults = [];

  Future<void> searchPreventivo() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    try {
      // Effettua la ricerca tramite il servizio
      //final results = await preventivoService.searchPreventivo(query);
      setState(() {
        //searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cerca Preventivo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(labelText: 'Cerca per nome'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: searchPreventivo,
              child: Text('Cerca'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final preventivo = searchResults[index];
                  return ListTile(
                    title: Text(preventivo['name']),
                    subtitle: Text(preventivo['description']),
                    trailing: Text('€${preventivo['amount']}'),
                    onTap: () {
                      // Azione opzionale per visualizzare i dettagli del preventivo
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selezionato: ${preventivo['name']}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
