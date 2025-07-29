  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:preventivi_app/services/dati_cliente_byid.dart';

  class ModificaDocumentiPage extends StatefulWidget {
    final int idCliente;
    final Map<String, dynamic> documento;
    final String nome;
    final String cognome;

  const ModificaDocumentiPage({
    required this.documento,
    required this.idCliente,
    required this.nome,   
    required this.cognome,
    Key? key,
  }) : super(key: key);

    @override
    State<ModificaDocumentiPage> createState() => _ModificaDocumentiPage();
  }

  class _ModificaDocumentiPage extends State<ModificaDocumentiPage> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _esecutriceController = TextEditingController();
    final TextEditingController _applicabileController = TextEditingController();
    TextEditingController _dataDocumentoController = TextEditingController();
    DateTime? _dataDocumento;  
    String tipoDocumento = 'Dichiarazione di Conformità';
    String? nome;
    String? cognome;
    bool isLoading = true;
    String? error;

    // Campi per "Dichiarazione di Conformità"
    bool normaTecnica = false;
    bool compatibilita = false;
    bool progettoArt57 = false;
    bool materiali = false;
    bool schemaImpianto = false;
    bool riferimentoDichiarazioni = false;
    bool certificatoRiconoscimento = false;
    bool attestazioneConformita = false;
    final TextEditingController _accertamentiController = TextEditingController();
    final TextEditingController _annoController = TextEditingController();
    final TextEditingController _comuneController = TextEditingController();
    final TextEditingController _provController = TextEditingController();
    final TextEditingController _viaController = TextEditingController();
    final TextEditingController _nController = TextEditingController();
    final TextEditingController _scalaController = TextEditingController();
    final TextEditingController _pianoController = TextEditingController();
    final TextEditingController _internoController = TextEditingController();
    final TextEditingController _seguitoRichiestaController = TextEditingController();
    final TextEditingController _relazioneAltroController = TextEditingController();
    String _usoEdificio = 'civile';
    bool _relazioneVerifica = false;
    bool _relazioneAltroCb = false;
    bool _copiaCertificato = false;

String formatDataString(String? isoString) {
  if (isoString == null) return '';
  try {
    final date = DateTime.parse(isoString);
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  } catch (e) {
    return isoString; // fallback se il parsing fallisce
  }
}

    @override
    void dispose() {
      _esecutriceController.dispose();
      _applicabileController.dispose();
      _dataDocumentoController.dispose();
      super.dispose();
    }
  @override
  void initState() {
    super.initState();
     _loadClienteData();
    print(widget.documento);

    _dataDocumentoController.text = widget.documento['data_documento'] ?? '';
    tipoDocumento = widget.documento['tipo_documento'] ?? 'Dichiarazione di Conformità';


    _esecutriceController.text = (widget.documento['esecutrice_impianto'] as String?) ?? '';
    _applicabileController.text = (widget.documento['testo_norma_tecnica_impiego'] as String?) ?? '';
    final rawData = widget.documento['data_documento'] as String?;
    _dataDocumentoController.text = rawData != null ? formatDataString(rawData) : '';
    tipoDocumento = (widget.documento['tipo_documento'] as String?) ?? 'Dichiarazione di Conformità';

  normaTecnica = (widget.documento['norma_tecnica_applicabile'] ?? 0) == 1;
  compatibilita = (widget.documento['verificato_compatibilita'] ?? 0) == 1;
  progettoArt57 = (widget.documento['progetto_art_5_7'] ?? 0) == 1;
  materiali = (widget.documento['tipologia_materiali_utilizzati'] ?? 0) == 1;
  schemaImpianto = (widget.documento['schema_impianto'] ?? 0) == 1;
  riferimentoDichiarazioni = (widget.documento['riferimento_dichiarazioni'] ?? 0) == 1;
  certificatoRiconoscimento = (widget.documento['copia_certificato_riconoscimento'] ?? 0) == 1;
  attestazioneConformita = (widget.documento['attestazione_conformita'] ?? 0) == 1;

    if (tipoDocumento == 'Dichiarazione di Conformità') {
      _initConformita();
    } else {
      _initRispondenza();
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


  void _initConformita() {
  _esecutriceController.text = widget.documento['esecutrice_impianto'] ?? '';
  _applicabileController.text = widget.documento['testo_norma_tecnica_impiego'] ?? '';
  normaTecnica = (widget.documento['norma_tecnica_applicabile'] ?? 0) == 1;
  compatibilita = (widget.documento['verificato_compatibilita'] ?? 0) == 1;
  progettoArt57 = (widget.documento['progetto_art_5_7'] ?? 0) == 1;
  materiali = (widget.documento['tipologia_materiali_utilizzati'] ?? 0) == 1;
  schemaImpianto = (widget.documento['schema_impianto'] ?? 0) == 1;
  riferimentoDichiarazioni = (widget.documento['riferimento_dichiarazioni'] ?? 0) == 1;
  certificatoRiconoscimento = (widget.documento['copia_certificato_riconoscimento'] ?? 0) == 1;
  attestazioneConformita = (widget.documento['attestazione_conformita'] ?? 0) == 1;
  }

  void _initRispondenza() {

  _accertamentiController.text = widget.documento['accertamenti_impianto'] ?? '';
  _annoController.text = widget.documento['realizzato_impianto_anno'] ?? '';
  _comuneController.text = widget.documento['installato_comune'] ?? '';
  _provController.text = widget.documento['installato_prov'] ?? '';
  _viaController.text = widget.documento['installato_via'] ?? '';
  _nController.text = widget.documento['installato_n'] ?? '';
  _scalaController.text = widget.documento['installato_scala'] ?? '';
  _pianoController.text = widget.documento['installato_piano'] ?? '';
  _internoController.text = widget.documento['installato_interno'] ?? '';
  _seguitoRichiestaController.text = widget.documento['seguito_richiesta'] ?? '';
  _relazioneAltroController.text = widget.documento['relazione_altro_testo'] ?? '';
  _usoEdificio = widget.documento['in_edificio_uso'] ?? 'civile';
  _relazioneVerifica = (widget.documento['relazione_verifica_impianto'] ?? 0) == 1;
  _relazioneAltroCb = (widget.documento['relazione_altro_cb'] ?? 0) == 1;
  _copiaCertificato = (widget.documento['copia_certificato'] ?? 0) == 1;
  }

  void _aggiornaDocumento() async {
    if (_formKey.currentState!.validate()) {
  final documentoAggiornato = tipoDocumento == 'Dichiarazione di Conformità'
          ? {
            'id_documento': widget.documento['id_documento'],
            'data_documento': _dataDocumentoController.text,
            "esecutrice_impianto": _esecutriceController.text,
            "testo_norma_tecnica_impiego": _applicabileController.text,
            "norma_tecnica_applicabile": normaTecnica ? 1 : 0,
            "verificato_compatibilita": compatibilita ? 1 : 0,
            "progetto_art_5_7": progettoArt57 ? 1 : 0,
            "tipologia_materiali_utilizzati": materiali ? 1 : 0,
            "schema_impianto": schemaImpianto ? 1 : 0,
            "riferimento_dichiarazioni": riferimentoDichiarazioni ? 1 : 0,
            "copia_certificato_riconoscimento": certificatoRiconoscimento ? 1 : 0,
            "attestazione_conformita": attestazioneConformita ? 1 : 0,
            }
          : {
              'id_documento': widget.documento['id_documento'],
              'data_documento': _dataDocumentoController.text,
              'accertamenti_impianto': _accertamentiController.text,
              'realizzato_impianto_anno': _annoController.text,
              'installato_comune': _comuneController.text,
              'installato_prov': _provController.text,
              'installato_via': _viaController.text,
              'installato_n': _nController.text,
              'installato_scala': _scalaController.text,
              'installato_piano': _pianoController.text,
              'installato_interno': _internoController.text,
              'dati_proprietario_cliente': '${widget.nome},${widget.cognome}',
              'in_edificio_uso': _usoEdificio,
              'seguito_richiesta': _seguitoRichiestaController.text,
              "relazione_verifica_impianto": _relazioneVerifica ? 1 : 0,
              "relazione_altro_cb": _relazioneAltroCb ? 1 : 0,
              'relazione_altro_testo': _relazioneAltroController.text,
              "copia_certificato": _copiaCertificato ? 1 : 0,
            };

      try {
          final endpoint = tipoDocumento == 'Dichiarazione di Conformità'
            ? 'documenti-conformita'
            : 'documenti-rispondenza';
            
        final response = await http.put(
          Uri.parse('http://94.176.182.61:3000/$endpoint/${widget.documento['id_documento']}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(documentoAggiornato),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento aggiornato con successo!'),
            backgroundColor: Colors.green,
          ),
          );
         await Future.delayed(Duration(seconds: 1));
         Navigator.of(context).pop(true);
        } else {
          _showErrorDialog("Errore durante l'aggiornamento.");
        }
      } catch (e) {
        _showErrorDialog("Errore: $e");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Errore"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }



@override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
  
  if (error != null) {
    return Scaffold(
      body: Center(child: Text('Errore: $error')),
    );
  }

  return Scaffold(
    appBar: AppBar(title: Text('Modifica $tipoDocumento per $nome $cognome')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Campo Data Documento (comune a entrambi i tipi)
            TextFormField(
              controller: _dataDocumentoController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Data documento *',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dataDocumentoController.text.isNotEmpty 
                      ? DateTime.parse(_dataDocumentoController.text)
                      : DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dataDocumentoController.text = pickedDate.toIso8601String().split('T')[0];
                  });
                }
              },
              validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
            ),

            // Campo Tipo Documento (sola lettura)
            TextFormField(
              decoration: InputDecoration(labelText: 'Tipo documento'),
              initialValue: tipoDocumento,
              readOnly: true,
              enabled: false,
            ),

            const SizedBox(height: 16),

            // Sezione specifica per tipo documento
            if (tipoDocumento == 'Dichiarazione di Conformità') ...[
              _buildConformitaFields(),
            ] else ...[
              _buildRispondenzaFields(),
            ],

            const SizedBox(height: 20),

            // Pulsante di salvataggio
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Aggiorna Documento'),
              onPressed: _aggiornaDocumento,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRispondenzaFields() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Sezione Installazione Impianto
      Text('Installazione Impianto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      TextFormField(
        controller: _accertamentiController,
        decoration: InputDecoration(labelText: 'Accertamenti impianto *'),
        maxLines: 3,
        validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
      ),
      TextFormField(
        controller: _annoController,
        decoration: InputDecoration(labelText: 'Anno realizzazione impianto *'),
        keyboardType: TextInputType.number,
        validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
      ),
      
      // Dettagli Installazione
      SizedBox(height: 16),
      Text('Luogo Installazione', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Row(
        children: [
          Expanded(child: TextFormField(
            controller: _comuneController,
            decoration: InputDecoration(labelText: 'Comune *'),
            validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
          )),
          SizedBox(width: 10),
          Expanded(child: TextFormField(
            controller: _provController,
            decoration: InputDecoration(labelText: 'Provincia *'),
            validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
          )),
        ],
      ),
      // ... altri campi specifici per rispondenza ...
      
      // Tipo Edificio
      SizedBox(height: 16),
      Text('Tipo Edificio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Column(
        children: [
          RadioListTile(
            title: Text('Civile'),
            value: 'civile',
            groupValue: _usoEdificio,
            onChanged: (value) => setState(() => _usoEdificio = value.toString()),
          ),
          // ... altri RadioListTile ...
        ],
      ),
      
      // Documentazione
      SizedBox(height: 16),
      Text('Documentazione', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      TextFormField(
        controller: _seguitoRichiestaController,
        decoration: InputDecoration(labelText: 'Seguito alla richiesta *'),
        validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
      ),
      // ... altri CheckboxListTile ...
    ],
  );
}

Widget _buildConformitaFields() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Esecutrice impianto
      TextFormField(
        controller: _esecutriceController,
        decoration: InputDecoration(
          labelText: "Esecutrice dell'impianto *",
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        style: TextStyle(fontSize: 16),
        validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
      ),
      
      const SizedBox(height: 20),
      
      // Norma tecnica applicabile
      _buildCheckbox(
        'Seguito la norma tecnica applicabile all\'impiego (S/N)', 
        (val) => setState(() => normaTecnica = val!), 
        normaTecnica,
      ),
      
      // Testo norma tecnica
      SizedBox(height: 12),
      TextFormField(
        controller: _applicabileController,
        decoration: InputDecoration(
          labelText: "La norma tecnica applicabile all'impiego *",
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        style: TextStyle(fontSize: 16),
        maxLines: 2,
        validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
      ),
      
      const SizedBox(height: 20),
      
      // Verifica compatibilità
      _buildCheckbox(
        'Verificato la compatibilità tecnica con l\'impianto preesistente (solo per rifacimenti parziali). (S/N)', 
        (val) => setState(() => compatibilita = val!), 
        compatibilita,
      ),
      
      // Progetto art. 5 e 7
      _buildCheckbox(
        'Progetto (ai sensi dell\'art. 5 e 7) (S/N)', 
        (val) => setState(() => progettoArt57 = val!), 
        progettoArt57,
      ),
      
      // Materiali utilizzati
      _buildCheckbox(
        'Relazione con tipologie dei materiali utilizzati (S/N)', 
        (val) => setState(() => materiali = val!), 
        materiali,
      ),
      
      // Schema impianto
      _buildCheckbox(
        'Schema di impianto realizzato (S/N)', 
        (val) => setState(() => schemaImpianto = val!), 
        schemaImpianto,
      ),
      
      // Riferimento dichiarazioni
      _buildCheckbox(
        'Riferimento a dichiarazioni di conformità precedenti o parziali già esistenti (S/N)', 
        (val) => setState(() => riferimentoDichiarazioni = val!), 
        riferimentoDichiarazioni,
      ),
      
      // Certificato riconoscimento
      _buildCheckbox(
        'Copia del certificato di riconoscimento dei requisiti tecnico-professionali (S/N)', 
        (val) => setState(() => certificatoRiconoscimento = val!), 
        certificatoRiconoscimento,
      ),
      
      // Attestazione conformità
      _buildCheckbox(
        'Attestazione di conformità per impianto realizzato con materiali o sistemi non normalizzati (S/N)', 
        (val) => setState(() => attestazioneConformita = val!), 
        attestazioneConformita,
      ),
    ],
  );
}

Widget _buildCheckbox(String label, ValueChanged<bool?> onChanged, bool value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CheckboxListTile(
        title: Text(
          label,
          style: TextStyle(fontSize: 15),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        dense: true,
      ),
    ),
  );
}

  }
