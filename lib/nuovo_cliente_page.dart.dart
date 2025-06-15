import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NuovoClientePage extends StatefulWidget {
  @override
  _NuovoClientePageState createState() => _NuovoClientePageState();
}

class _NuovoClientePageState extends State<NuovoClientePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _cittaController = TextEditingController();
  final TextEditingController _viaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _codiceFiscaleController = TextEditingController();

  bool _isLoading = false;

  Future<void> _salvaCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final clienteData = {
      'nome': _nomeController.text.trim(),
      'cognome': _cognomeController.text.trim(),
      'citta': _cittaController.text.trim(),
      'via': _viaController.text.trim(),
      'email': _emailController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'codice_fiscale': _codiceFiscaleController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://94.176.182.61:3000/clienti'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(clienteData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente creato con successo!')),
        );
        Navigator.pop(context, responseData['id_cliente']);
      } else {
        throw Exception('Errore ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuovo Cliente'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _salvaCliente,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(labelText: 'Nome*'),
                      validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    TextFormField(
                      controller: _cognomeController,
                      decoration: InputDecoration(labelText: 'Cognome*'),
                      validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    TextFormField(
                      controller: _cittaController,
                      decoration: InputDecoration(labelText: 'Città'),
                    ),
                    TextFormField(
                      controller: _viaController,
                      decoration: InputDecoration(labelText: 'Via/Piazza*'),
                      validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isNotEmpty && !value.contains('@')) {
                          return 'Email non valida';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(labelText: 'Telefono'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value!.isNotEmpty && (value.length < 8 || value.length > 15)) {
                          return 'Numero non valido';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _codiceFiscaleController,
                      decoration: InputDecoration(labelText: 'Codice Fiscale'),
                      validator: (value) {
                        if (value!.isNotEmpty && value.length != 16) {
                          return 'CF deve avere 16 caratteri';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvaCliente,
                      child: Text('SALVA CLIENTE'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}