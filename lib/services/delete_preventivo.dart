import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';


Future<bool> confermaECancellaPreventivo(BuildContext context, int idPreventivo) async {
  // Verifica se l'utente è admin
  final isAdmin = await AuthService().isAdmin();
  if (!isAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accesso negato: solo gli admin possono eliminare preventivi')),
    );
    return false;
  }

  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conferma eliminazione'),
      content: Text('Sei sicuro di voler eliminare il preventivo #$idPreventivo?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );

  if (shouldDelete == true) {
    try {
      final response = await ApiClient().delete('preventivo/$idPreventivo');

      if (response.statusCode == 200) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'eliminazione: ${response.body}')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
      return false;
    }
  }

  return false;
}