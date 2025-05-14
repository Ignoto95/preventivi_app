import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePreventivoFromClientePage extends StatefulWidget {
  final String nome;
  final String cognome;

  const CreatePreventivoFromClientePage({
    required this.nome,
    required this.cognome,
  });

  @override
  _CreatePreventivoFromClientePageState createState() => _CreatePreventivoFromClientePageState();
}

class _CreatePreventivoFromClientePageState extends State<CreatePreventivoFromClientePage> {
  final TextEditingController cittaController = TextEditingController();
  final TextEditingController viaController = TextEditingController();
  final TextEditingController dataPreventivoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController codiceFiscaleController = TextEditingController();
  final TextEditingController accontoController = TextEditingController();
  final List<Map<String, dynamic>> lavori = [];

  Future<void> savePreventivo() async {
    final citta = cittaController.text.trim();
    final via = viaController.text.trim();
    final dataPreventivo = dataPreventivoController.text.trim();
    final email = emailController.text.trim();
    final telefono = telefonoController.text.trim();
    final codiceFiscale = codiceFiscaleController.text.trim();
    final accontoText = accontoController.text.trim();
    final acconto = double.tryParse(accontoText) ?? 0;

    if (acconto < 0 || acconto > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('L\'acconto deve essere compreso tra 0 e 100%.')),
      );
      return;
    }

    if (citta.isEmpty || via.isEmpty || lavori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compila tutti i campi e aggiungi almeno un lavoro.')),
      );
      return;
    }

    if (!email.contains('@') || telefono.length < 8 || telefono.length == 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inserisci un\'email e un numero di telefono validi.')),
      );
      return;
    }

    final preventivoData = {
      'cliente': {
        'nome': widget.nome,
        'cognome': widget.cognome,
        'citta': citta,
        'via': via,
        'email': email,
        'telefono': telefono,
        'codice_fiscale': codiceFiscale,
      },
      'data_preventivo': dataPreventivo,
      'acconto': acconto,
      'lavori': lavori,
    };

    try {
      final response = await http.post(
        Uri.parse('http://94.176.182.61:3000/preventivo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(preventivoData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preventivo salvato con successo!')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Errore nel salvataggio: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dataPreventivoController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  void showLavoroDialog({Map<String, dynamic>? lavoro, int? index}) {
    final tipoController = TextEditingController(text: lavoro?['tipo_lavoro'] ?? '');
    final descrizioneController = TextEditingController(text: lavoro?['descrizione_lavoro'] ?? '');
    final prezzoController = TextEditingController(text: lavoro?['prezzo']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lavoro != null ? 'Modifica Lavoro' : 'Aggiungi Lavoro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tipoController, decoration: InputDecoration(labelText: 'Tipo Lavoro')),
            TextField(controller: descrizioneController, decoration: InputDecoration(labelText: 'Descrizione')),
            TextField(
              controller: prezzoController,
              decoration: InputDecoration(labelText: 'Prezzo (€)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final tipoLavoro = tipoController.text.trim();
              final descrizione = descrizioneController.text.trim();
              final prezzo = double.tryParse(prezzoController.text.trim());

              if (tipoLavoro.isNotEmpty && prezzo != null) {
                setState(() {
                  final nuovoLavoro = {
                    'tipo_lavoro': tipoLavoro,
                    'descrizione_lavoro': descrizione,
                    'prezzo': prezzo,
                  };
                  if (index != null) {
                    lavori[index] = nuovoLavoro;
                  } else {
                    lavori.add(nuovoLavoro);
                  }
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Compila correttamente i campi del lavoro.')),
                );
              }
            },
            child: Text(lavoro != null ? 'Modifica' : 'Aggiungi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crea Preventivo')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextField(
                  controller: TextEditingController(text: widget.nome),
                  decoration: InputDecoration(labelText: 'Nome Cliente'),
                  enabled: false,
                ),
                TextField(
                  controller: TextEditingController(text: widget.cognome),
                  decoration: InputDecoration(labelText: 'Cognome Cliente'),
                  enabled: false,
                ),
                TextField(controller: cittaController, decoration: InputDecoration(labelText: 'Città')),
                TextField(controller: viaController, decoration: InputDecoration(labelText: 'Via')),
                TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: telefonoController, decoration: InputDecoration(labelText: 'Telefono')),
                TextField(controller: codiceFiscaleController, decoration: InputDecoration(labelText: 'Codice Fiscale')),
                TextField(
                  controller: accontoController,
                  decoration: InputDecoration(labelText: 'Acconto (%)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: dataPreventivoController,
                  decoration: InputDecoration(labelText: 'Data Preventivo'),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                SizedBox(height: 16),
                Text('Lavori Aggiunti:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: lavori.length,
                  itemBuilder: (context, index) {
                    final lavoro = lavori[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('${lavoro['tipo_lavoro']} - €${lavoro['prezzo'].toStringAsFixed(2)}'),
                        subtitle: Text('Descrizione: ${lavoro['descrizione_lavoro']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showLavoroDialog(lavoro: lavoro, index: index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  lavori.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(onPressed: () => showLavoroDialog(), child: Text('Aggiungi Lavoro')),
                SizedBox(height: 16),
                ElevatedButton(onPressed: savePreventivo, child: Text('Salva Preventivo')),
                SizedBox(height: 16),
                Center(child: Text('Fine Form')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
