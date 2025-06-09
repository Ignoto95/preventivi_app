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

  @override
  void dispose() {
    _esecutriceController.dispose();
    _applicabileController.dispose();
    _dataDocumentoController.dispose();
    super.dispose();
  }

 void _salvaDocumento() async {
  if (_formKey.currentState!.validate()) {
    final documento = {
  'id_cliente': widget.idCliente, 
  'tipo_documento': tipoDocumento,
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
      final response = await http.post(
        Uri.parse('http://94.176.182.61:3000/documenti-conformita'),  // <-- cambia con il tuo IP/server
        headers: {'Content-Type': 'application/json'},
        body: json.encode(documento),
      );

      if (response.statusCode == 201) {
        print("Documento salvato correttamente!");
        Navigator.pop(context, true);
      } else {
        print("Errore nel salvataggio: ${response.body}");
        _showErrorDialog("Errore nel salvataggio del documento.");
      }
    } catch (e) {
      print("Eccezione durante il salvataggio: $e");
      _showErrorDialog("Errore durante il salvataggio del documento.");
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
    return Scaffold(
      appBar: AppBar(title: Text('Nuovo Documento per ${widget.nome} ${widget.cognome}')),
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Tipo documento'),
                value: tipoDocumento,
                items: [
                  DropdownMenuItem(value: 'Dichiarazione di Conformità', child: Text('Dichiarazione di Conformità')),
                  DropdownMenuItem(value: 'Dichiarazione di Rispondenza', child: Text('Dichiarazione di Rispondenza')),
                ],
                onChanged: (value) {
                  setState(() {
                    tipoDocumento = value!;
                  });
                },
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
                label: Text('Salva Documento'),
                onPressed: _salvaDocumento,
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
