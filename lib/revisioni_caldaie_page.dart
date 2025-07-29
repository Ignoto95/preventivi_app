import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_home_page.dart';
import 'home_page.dart';
import 'lista_richieste.dart';
import 'package:preventivi_app/services/email_service.dart';

class RevisioneCondizionatoriPage extends StatefulWidget {
  @override
  _RevisioneCondizionatoriPageState createState() => _RevisioneCondizionatoriPageState();
}

class _RevisioneCondizionatoriPageState extends State<RevisioneCondizionatoriPage> {
  List<dynamic> clientiConCondizionatori = [];
  bool isLoading = true;
  String? error;
  bool mostraFormAggiunta = false;
  int? idClienteSelezionato;
  String? tipoCondizionatoreSelezionato;
  final TextEditingController _potenzaController = TextEditingController();
  final TextEditingController _dataInstallazioneController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modelloController = TextEditingController();
  DateTime? _dataInstallazione;
  List<dynamic> clienti = [];
  int _selectedIndex = 0;
  User? currentUser;
  bool isSendingEmail = false;
  Map<int, bool> isSendingEmailMap = {}; // Per gestire più bottoni contemporaneamente
  TextEditingController _filtroNomeController = TextEditingController();
  String? _filtroAnno;
  List<dynamic> clientiFiltrati = [];

final Map<String, String> tipiCondizionatore = {
    'mono_split': 'Mono Split',
    'multi_split': 'Multi Split',
    'portatile': 'Portatile',
    'fisso': 'Fisso',
    'pompa_calore': 'Pompa di Calore',
};

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  @override
  void dispose() {
    _potenzaController.dispose();
    _dataInstallazioneController.dispose();
    _filtroNomeController.dispose();
    super.dispose();
  }

Future<void> _caricaDati() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    final [clientiRes, condizionatoriRes] = await Future.wait([
      http.get(Uri.parse('http://94.176.182.61:3000/api/clienti')),
     http.get(Uri.parse('http://94.176.182.61:3000/api/clienti-condizionatori')),
    ]);

    if (clientiRes.statusCode == 200 && condizionatoriRes.statusCode == 200) {
      setState(() {
        clienti = json.decode(clientiRes.body);
        clientiConCondizionatori = json.decode(condizionatoriRes.body);
        clientiFiltrati = clientiConCondizionatori; // Inizializza la lista filtrata
        isLoading = false;
      });
    } else {
      throw Exception('Errore nel caricamento dei dati');
    }
  } catch (e) {
    setState(() {
      isLoading = false;
      error = 'Errore nel recupero dei dati: ${e.toString()}';
    });
  }
}

Future<void> _aggiungiCondizionatore() async {
  if (idClienteSelezionato == null || 
      tipoCondizionatoreSelezionato == null || 
      _potenzaController.text.isEmpty || 
      _dataInstallazione == null) {
    _mostraSnackBar('Compila tutti i campi obbligatori', Colors.red);
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://94.176.182.61:3000/api/condizionatori'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id_cliente': idClienteSelezionato,
        'tipo_condizionatore': tipoCondizionatoreSelezionato,
        'potenza': int.parse(_potenzaController.text),
        'data_installazione': _dataInstallazione!.toIso8601String().split('T')[0],
        'modello': _modelloController.text.isNotEmpty ? _modelloController.text : null,
        'marca': _marcaController.text.isNotEmpty ? _marcaController.text : null,
      }),
    );

    if (response.statusCode == 201) {
      _mostraSnackBar('Condizionatore aggiunto con successo', Colors.green);
      await _caricaDati();
      setState(() {
        mostraFormAggiunta = false;
        _resetForm();
      });
    } else {
      throw Exception('Errore nell\'aggiunta del Condizionatore: ${response.body}');
    }
  } catch (e) {
    _mostraSnackBar('Errore: ${e.toString()}', Colors.red);
  }
}

  void _resetForm() {
    idClienteSelezionato = null;
    tipoCondizionatoreSelezionato = null;
    _potenzaController.clear();
    _dataInstallazioneController.clear();
    _modelloController.clear();
    _marcaController.clear();
    _dataInstallazione = null;
  }

  void _mostraSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _selezionaData(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      setState(() {
        _dataInstallazione = pickedDate;
        _dataInstallazioneController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _apriFormAggiunta([int? idCliente]) {
    setState(() {
      mostraFormAggiunta = true;
      if (idCliente != null) {
        idClienteSelezionato = idCliente;
      }
    });
  }

  void _confermaEliminazioneCondizionatore(Map<String, dynamic> condizionatore) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Conferma eliminazione'),
      content: Text('Vuoi davvero eliminare questo Condizionatore?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annulla'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _eliminaCondizionatore(condizionatore['id_condizionatore']);
          },
          child: Text('Elimina', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _avvisaCliente(Map<String, dynamic> condizionatore) async {
  final condizionatoreId = condizionatore['id_condizionatore'];
  
  setState(() {
    isSendingEmailMap[condizionatoreId] = true;
  });

  try {
    final email = condizionatore['email']?.toString().trim();
    
    if (email == null || !email.contains('@')) {
      throw Exception('Email cliente non valida');
    }

    await EmailService.sendBoilerNotification(
      recipientEmail: email,
      boilerId: condizionatore['id_condizionatore']?.toString() ?? 'N/D',
      clientName: '${condizionatore['nome']} ${condizionatore['cognome']}',
    );

    _mostraSnackBar('Avviso inviato a $email', Colors.green);
  } catch (e) {
    final errorMessage = e.toString().replaceAll('Exception: ', '');
    _mostraSnackBar('Errore: $errorMessage', Colors.red);
    print('Errore completo: $e');
  } finally {
    setState(() {
      isSendingEmailMap[condizionatoreId] = false;
    });
  }
}

Future<void> _eliminaCondizionatore(int? idCondizionatore) async {
  if (idCondizionatore == null) return;

  try {
    final response = await http.delete(
      Uri.parse('http://94.176.182.61:3000/api/condizionatori/$idCondizionatore'),
    );

    if (response.statusCode == 200) {
      _mostraSnackBar('Condizionatore eliminata con successo', Colors.green);
      await _caricaDati(); // Ricarica i dati
    } else {
      throw Exception('Errore nell\'eliminazione');
    }
  } catch (e) {
    _mostraSnackBar('Errore: ${e.toString()}', Colors.red);
  }
}

void _applicaFiltri() {
  setState(() {
    if (_filtroNomeController.text.isEmpty && _filtroAnno == null) {
      clientiFiltrati = clientiConCondizionatori;
      return;
    }

    clientiFiltrati = clientiConCondizionatori.where((condizionatore) {
      final nomeCompleto = '${condizionatore['cognome']} ${condizionatore['nome']}'.toLowerCase();
      final cercaNome = _filtroNomeController.text.toLowerCase();
      
      bool matchesNome = nomeCompleto.contains(cercaNome) || _filtroNomeController.text.isEmpty;
      
      bool matchesAnno = true;
      if (_filtroAnno != null && condizionatore['data_scadenza'] != null) {
        try {
          final annoScadenza = DateTime.parse(condizionatore['data_scadenza']).year.toString();
          matchesAnno = annoScadenza == _filtroAnno;
        } catch (e) {
          matchesAnno = false;
        }
      }
      
      return matchesNome && matchesAnno;
    }).toList();
  });
}


  Widget _buildFormAggiunta() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aggiungi Nuovo Condizionatore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    mostraFormAggiunta = false;
                    _resetForm();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          if (idClienteSelezionato == null) ...[
            DropdownButtonFormField<int>(
              value: idClienteSelezionato,
              decoration: InputDecoration(
                labelText: 'Cliente *',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.person),
              ),
              items: clienti.map((cliente) {
                return DropdownMenuItem<int>(
                  value: cliente['id_cliente'],
                  child: Text(
                    '${cliente['cognome']} ${cliente['nome']}',
                    style: TextStyle(fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => idClienteSelezionato = value),
              validator: (value) => value == null ? 'Seleziona un cliente' : null,
            ),
            SizedBox(height: 16),
          ] else ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clienti.firstWhere((c) => c['id_cliente'] == idClienteSelezionato)['cognome'] + 
                      ' ' + 
                      clienti.firstWhere((c) => c['id_cliente'] == idClienteSelezionato)['nome'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            value: tipoCondizionatoreSelezionato,
            decoration: InputDecoration(
              labelText: 'Tipo Condizionatore *',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.ac_unit),
            ),
            items: tipiCondizionatore.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: TextStyle(fontSize: 15),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => tipoCondizionatoreSelezionato = value),
            validator: (value) => value == null ? 'Seleziona un tipo' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _potenzaController,
            decoration: InputDecoration(
              labelText: 'Potenza (BTU) *',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.bolt),
              suffixText: 'BTU',
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _dataInstallazioneController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Data Installazione *',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: Icon(Icons.calendar_today),
              suffixIcon: IconButton(
                icon: Icon(Icons.arrow_drop_down),
                onPressed: () => _selezionaData(context),
              ),
            ),
            onTap: () => _selezionaData(context),
            validator: (value) => value?.isEmpty ?? true ? 'Seleziona una data' : null,
          ),
                    TextFormField(
              decoration: InputDecoration(
                  labelText: 'Modello',
                  prefixIcon: Icon(Icons.info),
              ),
              controller: _modelloController,
          ),
          SizedBox(height: 16),
          TextFormField(
              decoration: InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Icons.branding_watermark),
              ),
              controller: _marcaController,
          ),
                    SizedBox(height: 24),
          ElevatedButton(
            onPressed: _aggiungiCondizionatore,
            child: Text('SALVA INSERIMENTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
                  ],
                ),
              );
            }

Widget _buildListaCondizionatori() {
   final clientiUnici = clientiFiltrati.fold<Map<int, dynamic>>({}, (map, condizionatore) {
    final idCliente = condizionatore['id_cliente'];
    if (!map.containsKey(idCliente)) {
      map[idCliente] = {
        'cliente': condizionatore,
        'condizionatori': [],
      };
    }
    if (condizionatore['id_condizionatore'] != null) {
      map[idCliente]!['condizionatori'].add(condizionatore);
    }
    return map;
  }).values.toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
            Card(
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _filtroNomeController,
                decoration: InputDecoration(
                  labelText: 'Cerca per nome',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _filtroNomeController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _filtroNomeController.clear();
                            _applicaFiltri();
                          },
                        )
                      : null,
                ),
                onChanged: (value) => _applicaFiltri(),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _filtroAnno,
                decoration: InputDecoration(
                  labelText: 'Filtra per anno',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('Tutti gli anni')),
                  ...List.generate(10, (index) {
                    final year = DateTime.now().year + index - 5;
                    return DropdownMenuItem(
                      value: year.toString(),
                      child: Text(year.toString()),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filtroAnno = value;
                    _applicaFiltri();
                  });
                },
              ),
            ],
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lista Condizionatori',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue),
                onPressed: _caricaDati,
                tooltip: 'Aggiorna lista',
              ),
              SizedBox(width: 8),
              OutlinedButton.icon(
                icon: Icon(Icons.add, size: 18),
                label: Text('Aggiungi Condizionatori'),
                onPressed: _apriFormAggiunta,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  side: BorderSide(color: Colors.blue.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      SizedBox(height: 8),
      ...clientiUnici.map((clienteData) {
        final cliente = clienteData['cliente'];
        final condizionatori = clienteData['condizionatori'] as List<dynamic>;
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ExpansionTile(
            leading: Icon(Icons.person, color: Colors.blue.shade600),
            title: Text(
              '${cliente['cognome']} ${cliente['nome']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cliente['via']}, ${cliente['citta']}'),
                if (cliente['email'] != null && cliente['email'].toString().isNotEmpty)
                  Text(
                    cliente['email'],
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            children: [
              if (condizionatori.isNotEmpty) ...condizionatori.map((condizionatore) => _buildCondizionatoreTile(condizionatore)),
            ],
          ),
        );
      }),
    ],
  );
}

Widget _buildCondizionatoreTile(Map<String, dynamic> condizionatore) {
  return ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(Icons.ac_unit, color: Colors.blue.shade600),
    title: Text(
      tipiCondizionatore[condizionatore['tipo_condizionatore']] ?? 'Tipo sconosciuto',
      style: TextStyle(fontWeight: FontWeight.w500),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        if (condizionatore['marca'] != null)
          Text('Marca: ${condizionatore['marca'] ?? 'N/D'}'),
        if (condizionatore['modello'] != null)
        Text('Modello: ${condizionatore['modello'] ?? 'N/D'}'),
        Text('Potenza: ${condizionatore['potenza']?.toString() ?? 'N/D'} BTU'),
        Text('Installazione: ${condizionatore['data_installazione']}'),
        SizedBox(height: 4),
        Text(
          'Scadenza revisione: ${condizionatore['data_scadenza']}',
          style: TextStyle(
            color: _verificaScadenza(condizionatore['data_scadenza']) ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              icon: isSendingEmailMap[condizionatore['id_condizionatore']] == true
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.email, size: 18),
              label: Text(
                isSendingEmailMap[condizionatore['id_condizionatore']] == true 
                    ? 'Invio in corso...' 
                    : 'Avvisa cliente',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isSendingEmailMap[condizionatore['id_condizionatore']] == true
                  ? null
                  : () => _avvisaCliente(condizionatore),
            ),     
            SizedBox(width: 8),
            OutlinedButton.icon(
              icon: Icon(Icons.delete, size: 18, color: Colors.red),
              label: Text('Elimina', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade400),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _confermaEliminazioneCondizionatore(condizionatore),
            ),
          ],
        ),
      ],
    ),
    onTap: () => _mostraDettagliCondizionatore(condizionatore),
  );
}

  bool _verificaScadenza(String? dataScadenza) {
    if (dataScadenza == null) return false;
    try {
      final scadenza = DateTime.parse(dataScadenza);
      return scadenza.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

void _mostraDettagliCondizionatore(Map<String, dynamic> condizionatore) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Dettagli Condizionatore', style: TextStyle(color: Colors.blue.shade800)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDettaglioCondizionatore('Tipo', tipiCondizionatore[condizionatore['tipo_condizionatore']]),
            if (condizionatore['marca'] != null)
              _buildDettaglioCondizionatore('Marca', condizionatore['marca']),
            if (condizionatore['modello'] != null)
              _buildDettaglioCondizionatore('Modello', condizionatore['modello']),
            _buildDettaglioCondizionatore('Potenza', '${condizionatore['potenza']} BTU'),
            _buildDettaglioCondizionatore('Data installazione', condizionatore['data_installazione']),
            _buildDettaglioCondizionatore('Data scadenza', condizionatore['data_scadenza']),
            if (_verificaScadenza(condizionatore['data_scadenza']))
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'REVISIONE SCADUTA',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Chiudi', style: TextStyle(color: Colors.blue.shade600)),
        ),
      ],
    ),
  );
}

  Widget _buildDettaglioCondizionatore(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Revisione Condizionatore'),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _apriFormAggiunta(),
          tooltip: 'Aggiungi Condizionatore',
        ),
      ],
    ),
    drawer: _buildDrawer(context), // Aggiungi questo metodo
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
            : Padding(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (mostraFormAggiunta) _buildFormAggiunta(),
                      _buildListaCondizionatori(),
                    ],
                  ),
                ),
              ),
  );
}

Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(currentUser?.displayName ?? 'Utente'),
          accountEmail: Text(currentUser?.email ?? ''),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40),
          ),
        ),
          ListTile(
          leading: Icon(Icons.home),
          title: Text('Home'),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainHomePage()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Rubrica Clienti'),
          onTap: () {
            setState(() => _selectedIndex = 1);
            Navigator.pop(context);
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
               );
          },
        ),
        ListTile(
          leading: Icon(Icons.engineering),
          title: Text('Revisioni Condizionatori'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RevisioneCondizionatoriPage()),
            );
          },
        ),
                ListTile(
          leading: Icon(Icons.person_add),
          title: Text('Richieste Clienti'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ListaRichiestePage()),
            );
          },
        ),
ListTile(
  leading: Icon(Icons.receipt_long),
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Fatturazione Elettronica'),
      Text(
        'Funzionalità in arrivo',
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange.shade800,
        ),
      ),
    ],
  ),
  onTap: () {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funzionalità in arrivo prossimamente!'),
        duration: Duration(seconds: 2),
      ),
    );
  },
),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Logout'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}
}