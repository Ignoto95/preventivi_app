import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ModificaPreventivoPage extends StatefulWidget {
  final Map<String, dynamic> preventivo;

  ModificaPreventivoPage({required this.preventivo});

  @override
  _ModificaPreventivoPageState createState() => _ModificaPreventivoPageState();
}

class _ModificaPreventivoPageState extends State<ModificaPreventivoPage> {
  late TextEditingController nomeClienteController;
  late TextEditingController cognomeClienteController;
  late TextEditingController viaController;
  late TextEditingController cittaController;
  late TextEditingController prezzoTotaleController;

  List<Map<String, dynamic>> lavori = [];

  String tipoLavoro = '';
  String descrizioneLavoro = '';
  double prezzoLavoro = 0.0;

  @override
  void initState() {
    super.initState();

    // Inizializzo i controller con i valori esistenti del preventivo
    nomeClienteController = TextEditingController(text: widget.preventivo["nome_cliente"]);
    cognomeClienteController = TextEditingController(text: widget.preventivo["cognome_cliente"]);
    viaController = TextEditingController(text: widget.preventivo["via"]);
    cittaController = TextEditingController(text: widget.preventivo["citta"]);
    prezzoTotaleController = TextEditingController(text: widget.preventivo["prezzo_totale"].toString());

    // Popola i lavori esistenti dal preventivo in una lista di oggetti
    lavori = List<Map<String, dynamic>>.from(widget.preventivo["lavori"] ?? []);
  }

  Future<void> salvaPreventivo() async {
    try {
      final response = await http.put(
        Uri.parse('http://94.176.182.61:3000/preventivo/lavori/${widget.preventivo["id_preventivo"]}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "lavori": lavori,  // Invia l'array dei lavori aggiornati al server
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);  // Torna alla pagina precedente e aggiorna
      } else {
        throw Exception('Errore durante l\'aggiornamento del preventivo');
      }
    } catch (e) {
      print('Errore: $e');
    }
  }

  void aggiungiLavoro() {
    if (tipoLavoro.isNotEmpty && descrizioneLavoro.isNotEmpty && prezzoLavoro > 0) {
      setState(() {
        lavori.add({
          "tipo_lavoro": tipoLavoro,
          "descrizione_lavoro": descrizioneLavoro,
          "prezzo": prezzoLavoro
        });
        tipoLavoro = '';
        descrizioneLavoro = '';
        prezzoLavoro = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica Preventivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form per modificare i dettagli del cliente e del preventivo
            TextField(
              controller: nomeClienteController,
              decoration: InputDecoration(labelText: 'Nome Cliente'),
            ),
            TextField(
              controller: cognomeClienteController,
              decoration: InputDecoration(labelText: 'Cognome Cliente'),
            ),
            TextField(
              controller: viaController,
              decoration: InputDecoration(labelText: 'Via'),
            ),
            TextField(
              controller: cittaController,
              decoration: InputDecoration(labelText: 'Città'),
            ),
            TextField(
              controller: prezzoTotaleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Prezzo Totale'),
            ),
            SizedBox(height: 20),

            // Aggiungi nuovo lavoro
            TextField(
              onChanged: (value) => tipoLavoro = value,
              decoration: InputDecoration(labelText: 'Tipo Lavoro'),
            ),
            TextField(
              onChanged: (value) => descrizioneLavoro = value,
              decoration: InputDecoration(labelText: 'Descrizione Lavoro'),
            ),
            TextField(
              onChanged: (value) => prezzoLavoro = double.tryParse(value) ?? 0.0,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Prezzo Lavoro'),
            ),
            ElevatedButton(
              onPressed: aggiungiLavoro,
              child: Text('Aggiungi Lavoro'),
            ),
            SizedBox(height: 20),

            // Lista dei lavori esistenti con la possibilità di eliminarli
            Expanded(
              child: ListView.builder(
                itemCount: lavori.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo: ${lavori[index]["tipo_lavoro"]}'),
                        Text('Descrizione: ${lavori[index]["descrizione_lavoro"]}'),
                        Text('Prezzo: ${lavori[index]["prezzo"]} EUR'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          lavori.removeAt(index);  // Rimuove il lavoro dalla lista
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // Pulsante per salvare il preventivo
            ElevatedButton(
              onPressed: salvaPreventivo,
              child: Text('Salva Preventivo'),
            ),
          ],
        ),
      ),
    );
  }
}
