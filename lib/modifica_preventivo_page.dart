import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:preventivi_app/services/dati_cliente_byid.dart';

class ModificaPreventivoPage extends StatefulWidget {
  final Map<String, dynamic> preventivo;
  final String nome;
  final String cognome;
  final int idCliente;

  ModificaPreventivoPage({
    required this.preventivo,
    required this.nome,
    required this.cognome,
    required this.idCliente,
  });

  @override
  _ModificaPreventivoPageState createState() => _ModificaPreventivoPageState();
}

class _ModificaPreventivoPageState extends State<ModificaPreventivoPage> {
  late TextEditingController nomeClienteController;
  late TextEditingController cognomeClienteController;
  late TextEditingController viaController;
  late TextEditingController cittaController;
  late TextEditingController prezzoTotaleController;
  late TextEditingController dataPreventivoController;
  late TextEditingController emailController;
  late TextEditingController telefonoController;
  late TextEditingController codiceFiscaleController;
  String? nome;
  String? cognome;
  bool isLoading = true;
  String? error;
  
  List<Map<String, TextEditingController>> rateControllers = [];
  List<Map<String, dynamic>> lavori = [];
  List<String> _tipiLavoro = [];
  bool _isLoadingTipiLavoro = false;
  List<String> _descrizioniLavoro = [];
  bool _isLoadingDescrizioni = false;

  String formatDataString(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _loadClienteData() async {
    try {
      final clienteData = await fetchClienteById(widget.idCliente);
      setState(() {
        nome = clienteData['nome'] as String?;
        cognome = clienteData['cognome'] as String?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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

  @override
  void initState() {
    super.initState();
    _loadClienteData();
    _loadTipiLavoro();
    _loadDescrizioniLavoro();
    
    if (widget.preventivo["rate"] != null) {
      rateControllers = List<Map<String, TextEditingController>>.from(
        (widget.preventivo["rate"] as List).map((rata) => {
          'descrizione': TextEditingController(text: rata['descrizione']),
          'percentuale': TextEditingController(text: rata['percentuale'].toString()),
        })
      );
    } else {
      rateControllers = [{
        'descrizione': TextEditingController(),
        'percentuale': TextEditingController(),
      }];
    }

    nomeClienteController = TextEditingController(text: widget.preventivo["nome_cliente"]);
    cognomeClienteController = TextEditingController(text: widget.preventivo["cognome_cliente"]);
    viaController = TextEditingController(text: widget.preventivo["via"]);
    cittaController = TextEditingController(text: widget.preventivo["citta"]);
    dataPreventivoController = TextEditingController(
      text: formatDataString(widget.preventivo["data_preventivo"]),
    );
    emailController = TextEditingController(text: widget.preventivo["email"] ?? '');
    telefonoController = TextEditingController(text: widget.preventivo["telefono"] ?? '');
    codiceFiscaleController = TextEditingController(text: widget.preventivo["codice_fiscale"] ?? '');

    lavori = List<Map<String, dynamic>>.from(widget.preventivo["lavori"] ?? []).map((lavoro) {
      lavoro['prezzo'] = double.tryParse(lavoro['prezzo'].toString()) ?? 0.0;
      return lavoro;
    }).toList();
  }

  double calcolaPrezzoTotale() {
    double totale = 0.0;
    for (var lavoro in lavori) {
      totale += lavoro['prezzo'];
    }
    return totale;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(dataPreventivoController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.parse(dataPreventivoController.text)) {
      setState(() {
        dataPreventivoController.text = picked.toIso8601String().split('T')[0];
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
        _tipiLavoro.sort();
      });
    } else {
      print('Errore nella risposta: ${response.statusCode}');
    }
  } catch (e) {
    print('Errore nel caricamento dei tipi di lavoro: $e');
  } finally {
    setState(() {
      _isLoadingTipiLavoro = false;
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
      final Map<String, dynamic> preventivoAggiornato = {
        "id_preventivo": widget.preventivo["id_preventivo"],
        "nome_cliente": nomeClienteController.text.trim(),
        "cognome_cliente": cognomeClienteController.text.trim(),
        "via": viaController.text.trim(),
        "citta": cittaController.text.trim(),
        "prezzo_totale": calcolaPrezzoTotale(),
        "data_preventivo": dataPreventivoController.text,
        "lavori": lavori,
        "telefono": telefonoController.text.trim(),
        "email": emailController.text.trim(),
        "codice_fiscale": codiceFiscaleController.text.trim(),
        "rate": rate,
      };

      final response = await http.put(
        Uri.parse('http://94.176.182.61:3000/preventivi/modifica'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(preventivoAggiornato),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preventivo aggiornato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(Duration(seconds: 1));
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Errore durante l\'aggiornamento del preventivo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento del preventivo.')),
      );
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
                            } else if (value != null) {
                              setStateDialog(() {
                                selectedTipoLavoro = value;
                                showNewTypeField = false;
                                tipoController.text = value;
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
                  // Campo descrizione con autocompletamento
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
        title: Text('Modifica Preventivo per ${widget.nome} ${widget.cognome}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: salvaPreventivo,
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
                      _buildReadOnlyField('Nome Cliente', nomeClienteController),
                      SizedBox(height: 12),
                      _buildReadOnlyField('Cognome Cliente', cognomeClienteController),
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
                        )
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
                onPressed: salvaPreventivo,
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