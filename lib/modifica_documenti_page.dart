import 'package:flutter/material.dart';
import 'package:preventivi_app/services/dati_cliente_byid.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _loadClienteData();
    //print(widget.documento);

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

  Future<void> _aggiornaDocumento() async {
    if (!mounted) return;
    
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
        // Verifica permessi admin
        final isAdmin = await AuthService().isAdmin();
        if (!isAdmin) {
          throw Exception('Solo gli admin possono aggiornare documenti');
        }

        final endpoint = tipoDocumento == 'Dichiarazione di Conformità'
            ? 'documenti-conformita'
            : 'documenti-rispondenza';
              
        final response = await ApiClient().put(
          '$endpoint/${widget.documento['id_documento']}',
          body: json.encode(documentoAggiornato),
        );

        if (response.statusCode == 200) {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento aggiornato con successo!'),
              backgroundColor: Colors.green,
            ),
          );
          
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Errore durante l\'aggiornamento');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      appBar: AppBar(
        title: Text('Modifica $tipoDocumento per $nome $cognome'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _aggiornaDocumento,
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
                        TextFormField(
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
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Tipo documento',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          initialValue: tipoDocumento,
                          readOnly: true,
                          enabled: false,
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
                  onPressed: _aggiornaDocumento,
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
                        'AGGIORNA DOCUMENTO',
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
                  'Relazione de verifica impianto',
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