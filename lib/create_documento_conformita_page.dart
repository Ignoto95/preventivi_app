import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class CreateDocumentoFromClientePage extends StatefulWidget {
  final String nome;
  final String cognome;
  final int idCliente;

  const CreateDocumentoFromClientePage({
    required this.idCliente,
    required this.nome,
    required this.cognome,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateDocumentoFromClientePage> createState() => _CreateDocumentoFromClientePageState();
}

class _CreateDocumentoFromClientePageState extends State<CreateDocumentoFromClientePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _esecutriceController = TextEditingController();
  final TextEditingController _applicabileController = TextEditingController();
  TextEditingController _dataDocumentoController = TextEditingController();
  DateTime? _dataDocumento;  
  String tipoDocumento = 'Dichiarazione di Conformità';

  // Campi per "Dichiarazione di Conformità"
  bool normaTecnica = false;
  bool compatibilita = false;
  bool progettoArt57 = false;
  bool materiali = false;
  bool schemaImpianto = false;
  bool riferimentoDichiarazioni = false;
  bool certificatoRiconoscimento = false;
  bool attestazioneConformita = false;

  // Campi per "Dichiarazione di Rispondenza"
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

  @override
  void dispose() {
    _esecutriceController.dispose();
    _applicabileController.dispose();
    _dataDocumentoController.dispose();
    _accertamentiController.dispose();
    _annoController.dispose();
    _comuneController.dispose();
    _provController.dispose();
    _viaController.dispose();
    _nController.dispose();
    _scalaController.dispose();
    _pianoController.dispose();
    _internoController.dispose();
    _seguitoRichiestaController.dispose();
    _relazioneAltroController.dispose();
    super.dispose();
  }

Future<void> _salvaDocumento() async {
  if (_dataDocumentoController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inserire la data del documento è obbligatorio'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_formKey.currentState!.validate()) {
    final documento = tipoDocumento == 'Dichiarazione di Conformità'
        ? {
            'id_cliente': widget.idCliente,
            'tipo_documento': tipoDocumento,
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
            'id_cliente': widget.idCliente,
            'tipo_documento': tipoDocumento,
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
            'relazione_verifica_impianto': _relazioneVerifica ? 1 : 0,
            'relazione_altro_cb': _relazioneAltroCb ? 1 : 0,
            'relazione_altro_testo': _relazioneAltroController.text,
            'copia_certificato': _copiaCertificato ? 1 : 0,
          };

    try {
      final endpoint = tipoDocumento == 'Dichiarazione di Conformità'
          ? 'documenti-conformita'
          : 'documenti-rispondenza';
          
      final response = await http.post(
        Uri.parse('http://94.176.182.61:3000/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(documento),
      );
      final responseData = json.decode(response.body);
      debugPrint('Risposta backend: $responseData');
      if (response.statusCode == 201) {
        if (!mounted) return;
        
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(responseData['message'] ?? 'Documento salvato con successo!'),
      backgroundColor: Colors.green,
    ),
  );
        
        // Attendi che lo SnackBar sia visibile prima di navigare
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
         throw Exception(responseData['error'] ?? 'Errore sconosciuto');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il salvataggio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dataDocumento = picked;
        _dataDocumentoController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Crea Documento per ${widget.nome} ${widget.cognome}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _salvaDocumento,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                          'Informazioni Generali',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField (
                          controller: _dataDocumentoController,
                          decoration: InputDecoration(
                            labelText: 'Data documento *',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Tipo documento *',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          value: tipoDocumento,
                          items: [
                            DropdownMenuItem(
                              value: 'Dichiarazione di Conformità',
                              child: Text('Dichiarazione di Conformità'),
                            ),
                            DropdownMenuItem(
                              value: 'Dichiarazione di Rispondenza',
                              child: Text('Dichiarazione di Rispondenza'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                tipoDocumento = value;
                              });
                            }
                          },
                          validator: (value) => value == null ? 'Campo obbligatorio' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (tipoDocumento == 'Dichiarazione di Conformità') 
                  _buildConformitaFields()
                else 
                  _buildRispondenzaFields(),
                
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _salvaDocumento,
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
                        'SALVA DOCUMENTO',
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
      ),
    );
  }

  Widget _buildConformitaFields() {
    final theme = Theme.of(context);
    
    return Card(
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
            Text(
              'Dichiarazione di Conformità',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _esecutriceController,
              decoration: InputDecoration(
                labelText: "Esecutrice dell'impianto *",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
            ),
            SizedBox(height: 16),
            _buildCheckbox(
              'Seguito la norma tecnica applicabile all\'impiego (S/N)', 
              (val) => setState(() => normaTecnica = val!), 
              normaTecnica,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _applicabileController,
              decoration: InputDecoration(
                labelText: "La norma tecnica applicabile all'impiego *",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
            ),
            SizedBox(height: 12),
            _buildCheckbox(
              'Verificato la compatibilità tecnica con l\'impianto preesistente (solo per rifacimenti parziali). (S/N)', 
              (val) => setState(() => compatibilita = val!), 
              compatibilita,
            ),
            _buildCheckbox(
              'Progetto (ai sensi dell\'art. 5 e 7) (S/N)', 
              (val) => setState(() => progettoArt57 = val!), 
              progettoArt57,
            ),
            _buildCheckbox(
              'Relazione con tipologie dei materiali utilizzati (S/N)', 
              (val) => setState(() => materiali = val!), 
              materiali,
            ),
            _buildCheckbox(
              'Schema di impianto realizzato (S/N)', 
              (val) => setState(() => schemaImpianto = val!), 
              schemaImpianto,
            ),
            _buildCheckbox(
              'Riferimento a dichiarazioni di conformità precedenti o parziali già esistenti (S/N)', 
              (val) => setState(() => riferimentoDichiarazioni = val!), 
              riferimentoDichiarazioni,
            ),
            _buildCheckbox(
              'Copia del certificato di riconoscimento dei requisiti tecnico-professionali (S/N)', 
              (val) => setState(() => certificatoRiconoscimento = val!), 
              certificatoRiconoscimento,
            ),
            _buildCheckbox(
              'Attestazione di conformità per impianto realizzato con materiali o sistemi non normalizzati (S/N)', 
              (val) => setState(() => attestazioneConformita = val!), 
              attestazioneConformita,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRispondenzaFields() {
    final theme = Theme.of(context);
    
    return Column(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Installazione Impianto',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _accertamentiController,
                  decoration: InputDecoration(
                    labelText: 'In esito a sopralluogo ed accertamenti dell impianto.. (es Elettrico max 3kw) *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _annoController,
                  decoration: InputDecoration(
                    labelText: 'Realizzato indicativamente nell anno .... *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
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
                Text(
                  'Luogo Installazione',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _comuneController,
                        decoration: InputDecoration(
                          labelText: 'Comune *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _provController,
                        decoration: InputDecoration(
                          labelText: 'Provincia *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _viaController,
                  decoration: InputDecoration(
                    labelText: 'Via *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nController,
                        decoration: InputDecoration(
                          labelText: 'Numero Civico *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _scalaController,
                        decoration: InputDecoration(
                          labelText: 'Scala',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pianoController,
                        decoration: InputDecoration(
                          labelText: 'Piano',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _internoController,
                        decoration: InputDecoration(
                          labelText: 'Interno',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                  ],
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
                Text(
                  'Tipo Edificio',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Column(
                  children: [
                    RadioListTile(
                      title: Text('Civile'),
                      value: 'civile',
                      groupValue: _usoEdificio,
                      onChanged: (value) => setState(() => _usoEdificio = value.toString()),
                    ),
                    RadioListTile(
                      title: Text('Industriale'),
                      value: 'industriale',
                      groupValue: _usoEdificio,
                      onChanged: (value) => setState(() => _usoEdificio = value.toString()),
                    ),
                    RadioListTile(
                      title: Text('Commerciale'),
                      value: 'commercio',
                      groupValue: _usoEdificio,
                      onChanged: (value) => setState(() => _usoEdificio = value.toString()),
                    ),
                    RadioListTile(
                      title: Text('Altri usi'),
                      value: 'altri usi',
                      groupValue: _usoEdificio,
                      onChanged: (value) => setState(() => _usoEdificio = value.toString()),
                    ),
                  ],
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
                Text(
                  'Documentazione',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _seguitoRichiestaController,
                  decoration: InputDecoration(
                    labelText: 'Seguito alla richiesta *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                ),
                SizedBox(height: 16),
                _buildCheckbox(
                  'Relazione di verifica impianto',
                  (val) => setState(() => _relazioneVerifica = val!), 
                  _relazioneVerifica,
                ),
                _buildCheckbox(
                  '..Altro..',
                  (val) => setState(() => _relazioneAltroCb = val!), 
                  _relazioneAltroCb,
                ),
                if (_relazioneAltroCb) ...[
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _relazioneAltroController,
                    decoration: InputDecoration(
                      labelText: '(Specificare altro documento)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
                SizedBox(height: 16),
                _buildCheckbox(
                  'Copia certificato di conformità',
                  (val) => setState(() => _copiaCertificato = val!), 
                  _copiaCertificato,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, ValueChanged<bool?> onChanged, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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