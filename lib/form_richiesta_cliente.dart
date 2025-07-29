import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormRichiestaCliente extends StatefulWidget {
  @override
  _FormRichiestaClienteState createState() => _FormRichiestaClienteState();
}

class _FormRichiestaClienteState extends State<FormRichiestaCliente> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'nome': '',
    'cognome': '',
    'email': '',
    'telefono': '',
    'via': '',
    'citta': '',
    'codice_fiscale': '',
  };

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final response = await http.post(
        Uri.parse('http://94.176.182.61:3000/richieste-clienti'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_formData),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Successo'),
            content: Text('Richiesta inviata con successo!'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'invio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Richiesta di registrazione')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextFormField('Nome', 'nome', Icons.person),
              _buildTextFormField('Cognome', 'cognome', Icons.person),
              _buildTextFormField('Email', 'email', Icons.email, isEmail: true),
              _buildTextFormField('Telefono', 'telefono', Icons.phone, isPhone: true),
              _buildTextFormField('Via e numero civico', 'via', Icons.home),
              _buildTextFormField('Città', 'citta', Icons.location_city),
              _buildTextFormField('Codice Fiscale', 'codice_fiscale', Icons.badge),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Invia richiesta'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, String field, IconData icon, 
      {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon), 
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obbligatorio';
          if (isEmail && !value.contains('@')) return 'Email non valida';
          if (isPhone && !RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo numeri';
          return null;
        },
        onSaved: (value) => _formData[field] = value!.trim(),
      ),
    );
  }
}