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
          SnackBar(
            content: Text('Cliente creato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context, responseData['id_cliente']);
      } else {
        throw Exception('Errore ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il salvataggio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuovo Cliente', style: TextStyle(color: const Color.fromARGB(255, 80, 134, 195))),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
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
                            TextFormField(
                              controller: _nomeController,
                              decoration: InputDecoration(
                                labelText: 'Nome*',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _cognomeController,
                              decoration: InputDecoration(
                                labelText: 'Cognome*',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _viaController,
                              decoration: InputDecoration(
                                labelText: 'Via/Piazza*',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _cittaController,
                              decoration: InputDecoration(
                                labelText: 'Città',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _telefonoController,
                              decoration: InputDecoration(
                                labelText: 'Telefono',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value!.isNotEmpty && (value.length < 8 || value.length > 15)) {
                                  return 'Numero non valido';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value!.isNotEmpty && !value.contains('@')) {
                                  return 'Email non valida';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _codiceFiscaleController,
                              decoration: InputDecoration(
                                labelText: 'Codice Fiscale',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value!.isNotEmpty && value.length != 16) {
                                  return 'CF deve avere 16 caratteri';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvaCliente,
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
                            'SALVA CLIENTE',
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
}