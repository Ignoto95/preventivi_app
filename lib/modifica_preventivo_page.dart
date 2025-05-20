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
  late TextEditingController dataPreventivoController;  // Controller per la data
  late TextEditingController emailController; //Nuovi campi chiesti da simone
  late TextEditingController telefonoController;
  late TextEditingController codiceFiscaleController;
  late TextEditingController accontoController;
  List<Map<String, TextEditingController>> rateControllers = [];

  List<Map<String, dynamic>> lavori = [];

  @override
  void initState() {
    super.initState();
  // Inizializza rateControllers con i dati presenti nel preventivo, se ci sono
  if (widget.preventivo["rate"] != null) {
    rateControllers = List<Map<String, TextEditingController>>.from(
      (widget.preventivo["rate"] as List).map((rata) => {
        'descrizione': TextEditingController(text: rata['descrizione']),
        'percentuale': TextEditingController(text: rata['percentuale'].toString()),
      })
    );
  } else {
    // Se non ci sono rate, almeno una riga vuota
    rateControllers = [{
      'descrizione': TextEditingController(),
      'percentuale': TextEditingController(),
    }];
  }

    nomeClienteController = TextEditingController(text: widget.preventivo["nome_cliente"]);
    cognomeClienteController = TextEditingController(text: widget.preventivo["cognome_cliente"]);
    viaController = TextEditingController(text: widget.preventivo["via"]);
    cittaController = TextEditingController(text: widget.preventivo["citta"]);
    //prezzoTotaleController = TextEditingController(text: widget.preventivo["prezzo_totale"].toString());
    
    // Inizializza la data (se è presente nel preventivo)
    dataPreventivoController = TextEditingController(text: widget.preventivo["data_preventivo"] ?? DateTime.now().toIso8601String().split('T')[0]);
    emailController = TextEditingController(text: widget.preventivo["email"] ?? '');
    telefonoController = TextEditingController(text: widget.preventivo["telefono"] ?? '');
    codiceFiscaleController = TextEditingController(text: widget.preventivo["codice_fiscale"] ?? '');
    accontoController = TextEditingController(text: widget.preventivo["acconto"]?.toString() ?? '0');


    lavori = List<Map<String, dynamic>>.from(widget.preventivo["lavori"] ?? []).map((lavoro) {
      lavoro['prezzo'] = double.tryParse(lavoro['prezzo'].toString()) ?? 0.0;
      return lavoro;
    }).toList();
  }
  // Funzione per calcolare il prezzo totale
  double calcolaPrezzoTotale() {
    double totale = 0.0;
    for (var lavoro in lavori) {
      totale += lavoro['prezzo'];
    }
    return totale;
  }


  // Funzione per selezionare la data
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(dataPreventivoController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.parse(dataPreventivoController.text)) {
      setState(() {
        dataPreventivoController.text = picked.toIso8601String().split('T')[0];  // Aggiorna la data nel controller
      });
    }
  }

Future<void> salvaPreventivo() async {
  final rate = rateControllers.map((rata) {
  final descrizione = rata['descrizione']!.text.trim();
  final percentualeText = rata['percentuale']!.text.trim();
  final percentuale = double.tryParse(percentualeText) ?? 0;
  return {
    'descrizione': descrizione,
    'percentuale': percentuale,
  };
}).toList();

final sommaPercentuali = rate.fold<double>(0, (sum, r) => sum + (r['percentuale'] as double));

if (sommaPercentuali > 100) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('La somma delle percentuali delle rate non può superare il 100%.')),
  );
  return;
}

  try {
    // Costruzione del payload da inviare al server
    final Map<String, dynamic> preventivoAggiornato = {
      "id_preventivo": widget.preventivo["id_preventivo"],
      "nome_cliente": nomeClienteController.text.trim(),
      "cognome_cliente": cognomeClienteController.text.trim(),
      "via": viaController.text.trim(),
      "citta": cittaController.text.trim(),
      "prezzo_totale": calcolaPrezzoTotale(),  // Prezzo totale calcolato dinamicamente
      "data_preventivo": dataPreventivoController.text,  // Invia la data
      "lavori": lavori,  // Invia l'array dei lavori aggiornati al server
        // Nuovi campi
      "telefono": telefonoController.text.trim(),
      "email": emailController.text.trim(),
      "codice_fiscale": codiceFiscaleController.text.trim(),
      "acconto": double.tryParse(accontoController.text.trim()) ?? 0.0,
      "rate": rate,
    };

    print('Dati inviati al server:');
    print(json.encode(preventivoAggiornato));

    final response = await http.put(
      Uri.parse('http://94.176.182.61:3000/preventivi/modifica'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(preventivoAggiornato),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // Torna alla pagina precedente e aggiorna
    } else {
      print('Errore durante l\'aggiornamento del preventivo. Codice: ${response.statusCode}');
      print('Risposta del server: ${response.body}');
      throw Exception('Errore durante l\'aggiornamento del preventivo');
    }
  } catch (e) {
    print('Errore: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore durante l\'aggiornamento del preventivo.')),
    );
  }
}

  void showLavoroDialog({Map<String, dynamic>? lavoro, int? index}) {
    final TextEditingController tipoController = TextEditingController(
        text: lavoro != null ? lavoro['tipo_lavoro'] : '');
    final TextEditingController descrizioneController = TextEditingController(
        text: lavoro != null ? lavoro['descrizione_lavoro'] : '');
    final TextEditingController prezzoController = TextEditingController(
        text: lavoro != null ? lavoro['prezzo'].toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lavoro != null ? 'Modifica Lavoro' : 'Aggiungi Lavoro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tipoController, decoration: InputDecoration(labelText: 'Tipo Lavoro')),
              TextField(controller: descrizioneController, decoration: InputDecoration(labelText: 'Descrizione Lavoro')),
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
                final prezzo = double.tryParse(prezzoController.text.trim()) ?? 0.0;

                if (tipoLavoro.isNotEmpty && prezzo != null) {
                  setState(() {
                    final nuovoLavoro = {
                      'tipo_lavoro': tipoLavoro,
                      'descrizione_lavoro': descrizione,
                      'prezzo': prezzo,
                    };
                    if (lavoro != null && index != null) {
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica Preventivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nomeClienteController, decoration: InputDecoration(labelText: 'Nome Cliente'),readOnly: true,),
              TextField(controller: cognomeClienteController, decoration: InputDecoration(labelText: 'Cognome Cliente'),readOnly: true,),
              TextField(controller: viaController, decoration: InputDecoration(labelText: 'Via')),
              TextField(controller: cittaController, decoration: InputDecoration(labelText: 'Città')),
              TextField(
                        controller: telefonoController,
                        decoration: InputDecoration(labelText: 'Telefono'),
                        keyboardType: TextInputType.phone,
                      ),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextField(
                        controller: codiceFiscaleController,
                        decoration: InputDecoration(labelText: 'Codice Fiscale'),
                      ),
                      TextField(
                        controller: accontoController,
                        decoration: InputDecoration(labelText: 'Acconto (€)'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),


              //TextField(controller: prezzoTotaleController, decoration: InputDecoration(labelText: 'Prezzo Totale (€)')),
              
              // Aggiungi il campo Data Preventivo
              TextField(
                controller: dataPreventivoController,
                decoration: InputDecoration(labelText: 'Data Preventivo'),
                readOnly: true,
                onTap: () => _selectDate(context),  // Seleziona la data
              ),
              
              SizedBox(height: 20),
              Text(
                'Lavori Aggiunti:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: lavori.length,
                itemBuilder: (context, index) {
                  final lavoro = lavori[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('${lavoro['tipo_lavoro']} - €${double.tryParse(lavoro['prezzo'].toString())?.toStringAsFixed(2) ?? '0.00'}'),
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
              Text(
                'Prezzo Totale: €${calcolaPrezzoTotale().toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: () => showLavoroDialog(), child: Text('Aggiungi Lavoro')),
              SizedBox(height: 16),
            Text('Rate di Pagamento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: rateControllers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: TextField(
                      controller: rateControllers[index]['descrizione'],
                      decoration: InputDecoration(labelText: 'Descrizione Rata ${index + 1}'),
                    ),
                    subtitle: TextField(
                      controller: rateControllers[index]['percentuale'],
                      decoration: InputDecoration(labelText: 'Percentuale (%)'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          rateControllers.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  rateControllers.add({
                    'descrizione': TextEditingController(),
                    'percentuale': TextEditingController(),
                  });
                });
              },
              child: Text('Aggiungi Rata'),
            ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: salvaPreventivo, child: Text('Salva Preventivo')),
            ],
          ),
        ),
      ),
    );
  }
}
