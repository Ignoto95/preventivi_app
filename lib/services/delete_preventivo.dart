import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<bool> confermaECancellaPreventivo(BuildContext context, int idPreventivo) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Conferma eliminazione'),
      content: Text('Sei sicuro di voler eliminare il preventivo #$idPreventivo?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Elimina'),
        ),
      ],
    ),
  );

  if (shouldDelete == true) {
    final response = await http.delete(
      Uri.parse('http://94.176.182.61:3000/preventivo/$idPreventivo'),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione.')),
      );
    }
  }

  return false;
}
