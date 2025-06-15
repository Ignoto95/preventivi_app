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


  void _aggiornaDocumento() async {
    if (_formKey.currentState!.validate()) {
      final documentoAggiornato = {
        'id_documento': widget.documento['id_documento'],
        'data_documento': _dataDocumentoController.text,
        "esecutrice_impianto": _esecutriceController.text,
        "testo_norma_tecnica_impiego": _applicabileController.text,
        "norma_tecnica_applicabile": normaTecnica,
        "verificato_compatibilita": compatibilita,
        "progetto_art_5_7": progettoArt57,
        "tipologia_materiali_utilizzati": materiali,
        "schema_impianto": schemaImpianto,
        "riferimento_dichiarazioni": riferimentoDichiarazioni,
        "copia_certificato_riconoscimento": certificatoRiconoscimento,
        "attestazione_conformita": attestazioneConformita,
      };

      try {
        final response = await http.put(
          Uri.parse('http://94.176.182.61:3000/documenti-conformita/${widget.documento['id_documento']}'),
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
        appBar: AppBar(title: Text('Modifica Documento per $nome $cognome')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                controller: _dataDocumentoController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Data documento',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dataDocumento = pickedDate;
                      _dataDocumentoController.text = pickedDate.toIso8601String().split('T')[0]; // formato YYYY-MM-DD
                    });
                  }
                },
                validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Tipo documento'),
                  initialValue: tipoDocumento,
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                if (tipoDocumento == 'Dichiarazione di Conformità') ...[
                  TextFormField(
                    controller: _esecutriceController,
                    decoration: InputDecoration(labelText: "Esecutrice dell'impianto"),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildCheckbox('Seguito la norma tecnica applicabile all’impiego (S/N)', (val) => setState(() => normaTecnica = val!), normaTecnica),
                  TextFormField(
                    controller: _applicabileController,
                    decoration: InputDecoration(labelText: "La norma tecnica applicabile all’impiego"),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
                  ),
                  _buildCheckbox('Verificato la compatibilità tecnica con l’impianto preesistente (solo per rifacimenti parziali). (S/N)', (val) => setState(() => compatibilita = val!), compatibilita),
                  _buildCheckbox('Progetto (ai sensi dell’art. 5 e 7) (S/N)', (val) => setState(() => progettoArt57 = val!), progettoArt57),
                  _buildCheckbox('Relazione con tipologie dei materiali utilizzati (S/N)', (val) => setState(() => materiali = val!), materiali),
                  _buildCheckbox('Schema di impianto realizzato (S/N)', (val) => setState(() => schemaImpianto = val!), schemaImpianto),
                  _buildCheckbox('Riferimento a dichiarazioni di conformità precedenti o parziali già esistenti (S/N)', (val) => setState(() => riferimentoDichiarazioni = val!), riferimentoDichiarazioni),
                  _buildCheckbox('Copia del certificato di riconoscimento dei requisiti tecnico-professionali (S/N)', (val) => setState(() => certificatoRiconoscimento = val!), certificatoRiconoscimento),
                  _buildCheckbox('Attestazione di conformità per impianto realizzato con materiali o sistemi non normalizzati (S/N)', (val) => setState(() => attestazioneConformita = val!), attestazioneConformita),
                ],
                const SizedBox(height: 20),
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

    Widget _buildCheckbox(String label, ValueChanged<bool?> onChanged, bool value) {
      return CheckboxListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      );
    }
  }
