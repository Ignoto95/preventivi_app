import 'package:flutter/material.dart';
import 'services/preventivo_service.dart';

class CreatePreventivoPage extends StatefulWidget {
  @override
  _CreatePreventivoPageState createState() => _CreatePreventivoPageState();
}

class _CreatePreventivoPageState extends State<CreatePreventivoPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cognomeController = TextEditingController();
  final TextEditingController cittaController = TextEditingController();
  final TextEditingController viaController = TextEditingController();
  final TextEditingController dataPreventivoController = TextEditingController();
  final List<Map<String, dynamic>> lavori = [];
  final PreventivoService preventivoService = PreventivoService();

  // Funzione per salvare il preventivo
  Future<void> savePreventivo() async {
    final nome = nomeController.text.trim();
    final cognome = cognomeController.text.trim();
    final citta = cittaController.text.trim();
    final via = viaController.text.trim();
    final dataPreventivo = dataPreventivoController.text.trim();

    if (nome.isEmpty || cognome.isEmpty || citta.isEmpty || via.isEmpty || lavori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compila tutti i campi e aggiungi almeno un lavoro.')),
      );
      return;
    }

    final preventivoData = {
      'data_preventivo': dataPreventivo,
      'id_cliente': 0,
      'prezzo_totale': lavori.fold<double>(0.0, (sum, lavoro) => sum + lavoro['prezzo']),
      'lavori': lavori,
      'cliente': {'nome': nome, 'cognome': cognome, 'citta': citta, 'via': via}
    };

    try {
      await preventivoService.savePreventivo(preventivoData);
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

  // Funzione per selezionare la data tramite DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataPreventivoController.text.isEmpty
          ? DateTime.now()
          : DateTime.parse(dataPreventivoController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        dataPreventivoController.text = picked.toLocal().toString().split(' ')[0];  // Formato YYYY-MM-DD
      });
    }
  }

  // Funzione per aggiungere o modificare un lavoro
  void showLavoroDialog({Map<String, dynamic>? lavoro, int? index}) {
    final TextEditingController tipoController =
        TextEditingController(text: lavoro != null ? lavoro['tipo_lavoro'] : '');
    final TextEditingController descrizioneController =
        TextEditingController(text: lavoro != null ? lavoro['descrizione_lavoro'] : '');
    final TextEditingController prezzoController =
        TextEditingController(text: lavoro != null ? lavoro['prezzo'].toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lavoro != null ? 'Modifica Lavoro' : 'Aggiungi Lavoro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tipoController, decoration: InputDecoration(labelText: 'Tipo Lavoro')),
              TextField(controller: descrizioneController, decoration: InputDecoration(labelText: 'Descrizione')),
              TextField(
                controller: prezzoController,
                decoration: InputDecoration(labelText: 'Prezzo (€)'),
                keyboardType: TextInputType.number,
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
      appBar: AppBar(title: Text('Crea Preventivo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nomeController, decoration: InputDecoration(labelText: 'Nome Cliente')),
              TextField(controller: cognomeController, decoration: InputDecoration(labelText: 'Cognome Cliente')),
              TextField(controller: cittaController, decoration: InputDecoration(labelText: 'Città')),
              TextField(controller: viaController, decoration: InputDecoration(labelText: 'Via')),
              TextField(
                controller: dataPreventivoController,
                decoration: InputDecoration(labelText: 'Data Preventivo'),
                readOnly: true,
                onTap: () => _selectDate(context), // Mostra il DatePicker
              ),
              SizedBox(height: 16),
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
                      title: Text('${lavoro['tipo_lavoro']} - €${lavoro['prezzo']}'),
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
            ],
          ),
        ),
      ),
    );
  }
}
