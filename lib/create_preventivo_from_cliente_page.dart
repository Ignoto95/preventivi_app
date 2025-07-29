import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePreventivoFromClientePage extends StatefulWidget {
  final String nome;
  final String cognome;
  final String citta;
  final String via;
  final String email;
  final String telefono;
  final String codiceFiscale;
  final int idCliente;

  const CreatePreventivoFromClientePage({
    required this.nome,
    required this.cognome,
    required this.citta,
    required this.via,
    required this.email,
    required this.telefono,
    required this.codiceFiscale,
    required this.idCliente,
  });

  @override
  _CreatePreventivoFromClientePageState createState() => _CreatePreventivoFromClientePageState();
}

class _CreatePreventivoFromClientePageState extends State<CreatePreventivoFromClientePage> {
  final TextEditingController dataPreventivoController = TextEditingController();
  late final TextEditingController cittaController;
  late final TextEditingController viaController;
  late final TextEditingController emailController;
  late final TextEditingController telefonoController;
  late final TextEditingController codiceFiscaleController;
  final List<Map<String, dynamic>> lavori = [];
  List<Map<String, TextEditingController>> rateControllers = [];
  List<String> _tipiLavoro = [];
  bool _isLoadingTipiLavoro = false;
  List<String> _descrizioniLavoro = [];
  bool _isLoadingDescrizioni = false;

  @override
  void initState() {
    super.initState();
    cittaController = TextEditingController(text: widget.citta);
    viaController = TextEditingController(text: widget.via);
    emailController = TextEditingController(text: widget.email);
    telefonoController = TextEditingController(text: widget.telefono);
    codiceFiscaleController = TextEditingController(text: widget.codiceFiscale);
    _loadDescrizioniLavoro();
    
    rateControllers.add({
      'descrizione': TextEditingController(),
      'percentuale': TextEditingController(),
    });
    _loadTipiLavoro();
  }

  double calcolaPrezzoTotale() {
    double totale = 0.0;
    for (var lavoro in lavori) {
      totale += lavoro['prezzo'];
    }
    return totale;
  }

  Future<void> savePreventivo() async {
    final citta = cittaController.text.trim();
    final via = viaController.text.trim();
    final dataPreventivo = dataPreventivoController.text.trim();
    final email = emailController.text.trim();
    final telefono = telefonoController.text.trim();
    final codiceFiscale = codiceFiscaleController.text.trim();

    if (citta.isEmpty || via.isEmpty || lavori.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compila tutti i campi e aggiungi almeno un lavoro.')),
      );
      return;
    }

    if (!email.contains('@') || telefono.length == 11 ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inserisci un\'email e un numero di telefono validi.')),
      );
      return;
    }
    
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

    final preventivoData = {
      'cliente': {
        'id_cliente': widget.idCliente,
        'nome': widget.nome,
        'cognome': widget.cognome,
        'citta': citta,
        'via': via,
        'email': email,
        'telefono': telefono,
        'codice_fiscale': codiceFiscale,
      },
      'data_preventivo': dataPreventivo,
      'lavori': lavori,
      'rate': rate,
    };

    try {
      final response = await http.post(
        Uri.parse('http://94.176.182.61:3000/preventivo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(preventivoData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preventivo salvato con successo!'),
            backgroundColor: Colors.green,
          ),
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

    Future<void> _loadDescrizioniLavoro() async {
  setState(() {
    _isLoadingDescrizioni = true;
  });
  
  try {
    final response = await http.get(Uri.parse('http://94.176.182.61:3000/descrizioni-lavoro'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _descrizioniLavoro = List<String>.from(data);
      });
    }
  } catch (e) {
    print('Errore nel caricamento delle descrizioni: $e');
  } finally {
    setState(() {
      _isLoadingDescrizioni = false;
    });
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

Future<void> _loadTipiLavoro() async {
  setState(() {
    _isLoadingTipiLavoro = true;
  });
  
  try {
    final response = await http.get(Uri.parse('http://94.176.182.61:3000/tipi-lavoro'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Tipi lavoro ricevuti: $data');
      setState(() {
        _tipiLavoro = List<String>.from(data);
        _tipiLavoro.sort(); // Ordina alfabeticamente i tipi di lavoro
      });
    } else {
      print('Errore nella risposta: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento dei tipi di lavoro')),
      );
    }
  } catch (e) {
    print('Errore nel caricamento dei tipi di lavoro: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore di connessione')),
    );
  } finally {
    setState(() {
      _isLoadingTipiLavoro = false;
    });
  }
}

void showLavoroDialog({Map<String, dynamic>? lavoro, int? index}) {
  final tipoController = TextEditingController(text: lavoro?['tipo_lavoro'] ?? '');
  final descrizioneController = TextEditingController(text: lavoro?['descrizione_lavoro'] ?? '');
  final prezzoController = TextEditingController(text: lavoro?['prezzo']?.toString() ?? '');
  String? selectedTipoLavoro = lavoro?['tipo_lavoro'];
  bool showNewTypeField = lavoro == null || !_tipiLavoro.contains(lavoro['tipo_lavoro']);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lavoro != null ? 'Modifica Lavoro' : 'Aggiungi Lavoro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_isLoadingTipiLavoro)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedTipoLavoro,
                          decoration: InputDecoration(
                            labelText: 'Tipo Lavoro',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Seleziona un tipo...', style: TextStyle(color: Colors.grey)),
                            ),
                            ..._tipiLavoro.map((tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            )).toList(),
                            DropdownMenuItem(
                              value: '_nuovo_tipo',
                              child: Text('Aggiungi nuovo tipo...', style: TextStyle(color: Theme.of(context).primaryColor)),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == '_nuovo_tipo') {
                              setStateDialog(() {
                                selectedTipoLavoro = null;
                                showNewTypeField = true;
                                tipoController.text = '';
                              });
                            } else {
                              setStateDialog(() {
                                selectedTipoLavoro = value;
                                showNewTypeField = false;
                                if (value != null) {
                                  tipoController.text = value;
                                }
                              });
                            }
                          },
                        ),
                        if (showNewTypeField)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              TextField(
                                controller: tipoController,
                                decoration: InputDecoration(
                                  labelText: 'Nuovo Tipo Lavoro',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onChanged: (value) {
                                  selectedTipoLavoro = value;
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  SizedBox(height: 16),
                  // Sezione descrizione con suggerimenti
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_descrizioniLavoro.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Descrizioni disponibili:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      if (_descrizioniLavoro.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: Card(
                            elevation: 2,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _descrizioniLavoro.length > 5 ? 5 : _descrizioniLavoro.length,
                              itemBuilder: (context, idx) {
                                final descrizione = _descrizioniLavoro[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    descrizione.length > 50 
                                      ? '${descrizione.substring(0, 50)}...' 
                                      : descrizione,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  onTap: () {
                                    descrizioneController.text = descrizione;
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      if (_descrizioniLavoro.length > 5)
                        TextButton(
                          child: Text('Mostra tutte le descrizioni'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Seleziona una descrizione'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _descrizioniLavoro.length,
                                    itemBuilder: (context, idx) {
                                      return ListTile(
                                        title: Text(_descrizioniLavoro[idx]),
                                        onTap: () {
                                          descrizioneController.text = _descrizioniLavoro[idx];
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      SizedBox(height: 8),
                      TextField(
                        controller: descrizioneController,
                        decoration: InputDecoration(
                          labelText: 'Descrizione *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: prezzoController,
                    decoration: InputDecoration(
                      labelText: 'Prezzo (€) *',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixText: '€ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('ANNULLA'),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          if ((selectedTipoLavoro == null || selectedTipoLavoro!.isEmpty) && 
                              (tipoController.text.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Seleziona o inserisci un tipo di lavoro')),
                            );
                            return;
                          }

                          if (descrizioneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('La descrizione è obbligatoria')),
                            );
                            return;
                          }

                          final tipo = selectedTipoLavoro ?? tipoController.text;
                          if (tipo.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Il tipo di lavoro è obbligatorio')),
                            );
                            return;
                          }

                          final nuovoLavoro = {
                            'tipo_lavoro': tipo,
                            'descrizione_lavoro': descrizioneController.text,
                            'prezzo': double.tryParse(prezzoController.text) ?? 0.0,
                          };
                          
                          setState(() {
                            if (index != null) {
                              lavori[index] = nuovoLavoro;
                            } else {
                              lavori.add(nuovoLavoro);
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 8),
                            Text(lavoro != null ? 'SALVA MODIFICHE' : 'AGGIUNGI LAVORO'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Crea Preventivo per ${widget.nome} ${widget.cognome}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: savePreventivo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Informazioni Cliente',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildReadOnlyField('Nome Cliente', TextEditingController(text: widget.nome)),
                      SizedBox(height: 12),
                      _buildReadOnlyField('Cognome Cliente', TextEditingController(text: widget.cognome)),
                      SizedBox(height: 12),
                      _buildTextField('Via', viaController),
                      SizedBox(height: 12),
                      _buildTextField('Città', cittaController),
                      SizedBox(height: 12),
                      _buildTextField('Telefono', telefonoController, keyboardType: TextInputType.phone),
                      SizedBox(height: 12),
                      _buildTextField('Email', emailController, keyboardType: TextInputType.emailAddress),
                      SizedBox(height: 12),
                      _buildTextField('Codice Fiscale', codiceFiscaleController),
                      SizedBox(height: 12),
                      TextField(
                        controller: dataPreventivoController,
                        decoration: InputDecoration(
                          labelText: 'Data Preventivo',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
              
              Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lavori',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.primaryColor,
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.add, color: theme.primaryColor),
                            label: Text(
                              'Aggiungi lavoro',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                            onPressed: () => showLavoroDialog(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (lavori.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Nessun lavoro aggiunto',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Column(
                          children: [
                            ...lavori.map((lavoro) => _buildLavoroCard(lavoro, lavori.indexOf(lavoro))).toList(),
                            SizedBox(height: 16),
                            _buildTotalCard(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rate di Pagamento',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.primaryColor,
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.add, color: theme.primaryColor),
                            label: Text(
                              'Aggiungi rata',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                            onPressed: () {
                              setState(() {
                                rateControllers.add({
                                  'descrizione': TextEditingController(),
                                  'percentuale': TextEditingController(),
                                });
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (rateControllers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Nessuna rata definita',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Column(
                          children: [
                            ...rateControllers.map((rata) => _buildRataCard(rata, rateControllers.indexOf(rata))).toList(),
                            SizedBox(height: 8),
                            _buildPercentSum(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: savePreventivo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'SALVA PREVENTIVO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      readOnly: true,
    );
  }

  Widget _buildLavoroCard(Map<String, dynamic> lavoro, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lavoro['tipo_lavoro'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '€${lavoro['prezzo'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              lavoro['descrizione_lavoro'].length > 100
                  ? '${lavoro['descrizione_lavoro'].substring(0, 100)}...'
                  : lavoro['descrizione_lavoro'],
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (lavoro['descrizione_lavoro'].length > 100)
              TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Descrizione completa'),
                    content: SingleChildScrollView(
                      child: Text(lavoro['descrizione_lavoro']),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Chiudi'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                child: Text('Mostra tutto'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PREZZO TOTALE:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '€${calcolaPrezzoTotale().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRataCard(Map<String, TextEditingController> rata, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: rata['descrizione'],
              decoration: InputDecoration(
                labelText: 'Descrizione Rata ${index + 1}',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: rata['percentuale'],
              decoration: InputDecoration(
                labelText: 'Percentuale (%)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
                suffixText: '%',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    rateControllers.removeAt(index);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentSum() {
    final somma = rateControllers.fold<double>(0, (sum, r) {
      final percentuale = double.tryParse(r['percentuale']!.text) ?? 0;
      return sum + percentuale;
    });

    return Card(
      color: somma > 100 ? Colors.red[50] : Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SOMMA PERCENTUALI:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: somma > 100 ? Colors.red : Colors.blue[800],
              ),
            ),
            Text(
              '${somma.toStringAsFixed(2)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: somma > 100 ? Colors.red : Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}