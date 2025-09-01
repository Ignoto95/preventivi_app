import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http; 
import 'services/pdf_preventivi_service.dart';
import 'services/delete_preventivo.dart';
import 'dart:convert';
import 'modifica_preventivo_page.dart';
import 'nuovo_cliente_page.dart';
import 'create_preventivo_from_cliente_page.dart' as createDaCliente;
import 'create_documento_conformita_page.dart' as createDocumento;
import 'detail_documento_page.dart';
import 'modifica_cliente_page.dart';
import 'revisioni_caldaie_page.dart';
import 'lista_richieste.dart';
import 'main_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<Map<String, dynamic>>> clientiConPreventivi = {};
  Map<String, List<Map<String, dynamic>>> clientiConDocumenti = {};
  String searchQuery = "";
  String? filtroAnno;
  String? filtroMese;
  String? filtroGiorno;
  bool isLoading = true;
  User? currentUser;
  

  @override
  void initState() {
    super.initState();
    fetchPreventivi().then((_) => fetchDocumenti());
    currentUser = FirebaseAuth.instance.currentUser;
  }

Future<void> fetchPreventivi() async {
  setState(() => isLoading = true);
  
  try {
    // Verifica se l'utente è admin
    final isAdmin = await AuthService().isAdmin();
    if (!isAdmin) {
      throw Exception('Accesso negato: solo gli admin possono accedere');
    }

    final response = await ApiClient().get('clienti');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      Map<String, List<Map<String, dynamic>>> clienti = {};

      for (var cliente in data) {
        final clienteKey = "${cliente["nome"]} ${cliente["cognome"]}";
        final List<dynamic> preventivi = cliente["preventivi"] ?? [];
        
        final Map<String, dynamic> clienteInfo = {
          'nome': cliente["nome"],
          'cognome': cliente["cognome"],
          'citta': cliente["citta"],
          'via': cliente["via"],
          'email': cliente["email"],
          'telefono': cliente["telefono"],
          'codice_fiscale': cliente["codice_fiscale"],
          'id_cliente': cliente["id_cliente"],
          'has_preventivi': preventivi.isNotEmpty,
          'preventivi': preventivi.map<Map<String, dynamic>>((p) => {
            'id_preventivo': p["id_preventivo"],
            'data_preventivo': p["data_preventivo"],
            'prezzo_totale': p["prezzo_totale"],
            'nome_cliente': cliente["nome"],
            'cognome_cliente': cliente["cognome"],
            'email': cliente["email"],
            'id_cliente': cliente["id_cliente"],
            'telefono': cliente["telefono"],
            'citta': cliente["citta"],
            'via': cliente["via"],
            'codice_fiscale': cliente["codice_fiscale"],
            'lavori': p["lavori"] ?? [],
            'rate': p["rate"] ?? [],
          }).toList(),
        };

        clienti[clienteKey] = [clienteInfo];
      }

      setState(() {
        clientiConPreventivi = clienti;
        isLoading = false;
      });
    } else {
      throw Exception('Errore durante il recupero dei dati');
    }
  } catch (e) {
    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatPrezzo(dynamic prezzo) {
    if (prezzo == null) return '0.00';
    if (prezzo is String) {
      final numValue = double.tryParse(prezzo) ?? 0.0;
      return numValue.toStringAsFixed(2);
    }
    if (prezzo is num) {
      return prezzo.toStringAsFixed(2);
    }
    return '0.00';
  }

Future<void> fetchDocumenti() async {
  try {
    // Verifica se l'utente è admin
    final isAdmin = await AuthService().isAdmin();
    if (!isAdmin) {
      throw Exception('Accesso negato: solo gli admin possono accedere');
    }

    final response = await ApiClient().get('documenti');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      Map<String, List<Map<String, dynamic>>> clienti = {};
      for (var item in data) {
        final clienteKey = "${item["nome_cliente"]} ${item["cognome_cliente"]}";
        clienti.putIfAbsent(clienteKey, () => []).add(item);
      }
      setState(() {
        clientiConDocumenti = clienti;
      });
    } else {
      throw Exception('Errore durante il recupero dei documenti');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore documenti: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
  // Funzione per confermare la cancellazione
Future<void> _confirmDeleteCliente(int idCliente, String nomeCliente) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Conferma cancellazione completa'),
        content: Text(
          'Sei sicuro di voler cancellare il cliente "$nomeCliente"?\n\n'
          'Questa azione cancellerà TUTTI i dati associati:\n'
          '• Preventivi\n'
          '• Caldaie\n'
          '• Altri dati collegati',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina definitivamente'),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await _deleteCliente(idCliente);
  }
}

Future<void> _deleteCliente(int idCliente) async {
  try {
    // Verifica se l'utente è admin
    final isAdmin = await AuthService().isAdmin();
    if (!isAdmin) {
      throw Exception('Accesso negato: solo gli admin possono cancellare clienti');
    }

    final response = await ApiClient().delete('clienti/$idCliente');

    if (response.statusCode == 200) {
      // Ricarica i dati dopo la cancellazione
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente cancellato con successo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Errore durante la cancellazione');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

Future<void> _refreshData() async {
  setState(() {
    isLoading = true;
  });
  
  try {
    await fetchPreventivi();
    await fetchDocumenti();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'aggiornamento: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

void _showClienteMenu(BuildContext context, int idCliente, String nomeCliente, Map<String, dynamic> clienteData) {
  //final isAdmin = await AuthService().isAdmin();
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              title: Text('Modifica cliente'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditCliente(clienteData);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Elimina cliente'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteCliente(idCliente, nomeCliente);
              },
            ),
          ],
        ),
      );
    },
  );
}
Future<void> _navigateToEditCliente(Map<String, dynamic> clienteData) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => ModificaClientePage(cliente: clienteData),
    ),
  );
  
  if (result == true) {
    // Ricarica i dati se è stato effettuato un aggiornamento
    await fetchPreventivi();
    await fetchDocumenti();
  }
}

  Widget _buildFiltroDataSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filtra per Data', 
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Anno (es. 2025)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    filtroAnno = val.isNotEmpty ? val : null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Mese (es. 05)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    filtroMese = val.isNotEmpty ? val : null;
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Giorno (es. 14)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    filtroGiorno = val.isNotEmpty ? val : null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('ANNULLA'),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('APPLICA FILTRO'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
          appBar: AppBar(
      title: Text('Rubrica Clienti'),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    ),
    drawer: _buildDrawer(context),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and filter bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Cerca Cliente',
                        prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.filter_alt, color: colorScheme.primary),
                    tooltip: 'Filtra per data',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildFiltroDataSheet(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: colorScheme.error),
                    tooltip: 'Pulisci filtro',
                    onPressed: () => setState(() {
                      filtroAnno = null;
                      filtroMese = null;
                      filtroGiorno = null;
                    }),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.person_add, color: colorScheme.primary),
                    tooltip: 'Nuovo Cliente',
                    onPressed: () async {
                      final idCliente = await Navigator.push<int>(
                        context,
                        MaterialPageRoute(builder: (context) => NuovoClientePage()),
                      );
                      if (idCliente != null) {
                        await fetchPreventivi();
                        await fetchDocumenti();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),
              ),
            ),
            SizedBox(height: 16),
            // New client button
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: FloatingActionButton(
            //     heroTag: 'newClientBtn',
            //     backgroundColor: colorScheme.primary,
            //     foregroundColor: colorScheme.onPrimary,
            //     onPressed: () async {
            //       final idCliente = await Navigator.push<int>(
            //         context,
            //         MaterialPageRoute(builder: (context) => NuovoClientePage()),
            //       );
            //       if (idCliente != null) {
            //         await fetchPreventivi();
            //         await fetchDocumenti();
            //       }
            //     },
            //     child: Icon(Icons.person_add),
            //     tooltip: 'Nuovo Cliente',
            //   ),
            // ),
            SizedBox(height: 16),
            // Client list
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : ListView(
                      children: clientiConPreventivi.entries
                          .where((entry) => entry.key.toLowerCase().contains(searchQuery.toLowerCase()))
                          .map((entry) => _buildClienteCard(entry, colorScheme))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteCard(
    MapEntry<String, List<Map<String, dynamic>>> entry, 
    ColorScheme colorScheme
  ) {
  final theme = Theme.of(context);
  final nomeCliente = entry.key;
  final List<Map<String, dynamic>> clientiList = entry.value;
  
  // Verifica che la lista non sia vuota
  if (clientiList.isEmpty) {
    return const SizedBox.shrink(); // o un widget alternativo
  }

  final Map<String, dynamic> clienteData = clientiList.first;
  final int idCliente = clienteData['id_cliente'];
  final hasPreventivi = clienteData['has_preventivi'] ?? false;
  final preventivi = clienteData['preventivi'] ?? [];
  final documenti = clientiConDocumenti[nomeCliente] ?? [];
  final hasDocumenti = documenti.isNotEmpty;

    final preventiviFiltrati = hasPreventivi 
        ? preventivi.where((p) {
            final data = DateTime.tryParse(p["data_preventivo"] ?? '') ?? DateTime.now();
            final matchAnno = filtroAnno == null || data.year.toString() == filtroAnno;
            final matchMese = filtroMese == null || data.month.toString().padLeft(2, '0') == filtroMese;
            final matchGiorno = filtroGiorno == null || data.day.toString().padLeft(2, '0') == filtroGiorno;
            return matchAnno && matchMese && matchGiorno;
          }).toList()
        : [];

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
          trailing: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             IconButton(
               icon: Icon(Icons.more_vert),
               onPressed: () => _showClienteMenu(context, idCliente, nomeCliente,clienteData),
             ),
           ],
         ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                nomeCliente.substring(0, 1),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeCliente,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    clienteData['citta'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Text(
          clienteData['email'] ?? '',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          // Preventivi section
          if (hasPreventivi && preventiviFiltrati.isNotEmpty) ...[
            ...groupPreventiviByAnno(preventiviFiltrati).entries.expand((annoEntry) => [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Preventivi Anno ${annoEntry.key}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color.fromARGB(255, 80, 134, 195), // Colore più acceso
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),  
              ),
              ...annoEntry.value.map((preventivo) => _buildPreventivoItem(preventivo)),
            ]),
          ] else if (!hasPreventivi) ...[
            _buildEmptyState(
              icon: Icons.request_quote,
              text: 'Nessun preventivo',
              actionText: 'Clicca per crearne uno',
              action: () => _navigateToNewPreventivo(nomeCliente, clienteData),
            ),
          ],
          
          // Documenti section
          if (hasDocumenti) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Documentazioni',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color.fromARGB(255, 80, 134, 195), // Colore più acceso
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ),
            ...documenti.map((doc) => _buildDocumentoItem(doc)),
          ],
          
          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.note_add, size: 18),
                  label: Text('Nuovo Preventivo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _navigateToNewPreventivo(nomeCliente, clienteData),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: Icon(Icons.description, size: 18),
                  label: Text('Nuovo Documento'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _navigateToNewDocumento(nomeCliente, clienteData),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreventivoItem(Map<String, dynamic> preventivo) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#${preventivo["id_preventivo"]}',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          'Preventivo del ${formatDataString(preventivo["data_preventivo"])}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Totale: €${_formatPrezzo(preventivo["prezzo_totale"])}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.picture_as_pdf, size: 20, color: Colors.orange),
              tooltip: 'Genera PDF',
              onPressed: () => _generatePdf(preventivo),
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: colorScheme.primary),
              onPressed: () => _editPreventivo(preventivo),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
              onPressed: () => _deletePreventivo(preventivo["id_preventivo"]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentoItem(Map<String, dynamic> doc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description,
            color: Colors.purple,
            size: 20,
          ),
        ),
        title: Text(
          'Documento di ${capitalize(doc["tipo_documento"] ?? "")}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Data: ${formatDataString(doc["data_documento"] ?? "N/A")}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
        onTap: () => _viewDocumentDetails(doc),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String text,
    required String actionText,
    required VoidCallback action,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: colorScheme.onSurface.withOpacity(0.4)),
      title: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      subtitle: Text(
        actionText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      onTap: action,
    );
  }

    Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(currentUser?.displayName ?? 'Utente'),
          accountEmail: Text(currentUser?.email ?? ''),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40),
          ),
        ),
          ListTile(
          leading: Icon(Icons.home),
          title: Text('Home'),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainHomePage()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Rubrica Clienti'),
          onTap: () {
            //setState(() => _selectedIndex = 1);
            Navigator.pop(context);
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
               );
          },
        ),
        ListTile(
          leading: Icon(Icons.engineering),
          title: Text('Revisioni Condizionatori'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RevisioneCondizionatoriPage()),
            );
          },
        ),
                ListTile(
          leading: Icon(Icons.person_add),
          title: Text('Richieste Clienti'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ListaRichiestePage()),
            );
          },
        ),
      ListTile(
        leading: Icon(Icons.receipt_long),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fatturazione Elettronica'),
            Text(
              'Funzionalità in arrivo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Funzionalità in arrivo prossimamente!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
}

  Future<void> _navigateToNewPreventivo(String nomeCliente, Map<String, dynamic> clienteData) async {
    final parts = nomeCliente.split(' ');
    final nome = parts.first;
    final cognome = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => createDaCliente.CreatePreventivoFromClientePage(
          nome: nome,
          cognome: cognome,
          citta: clienteData['citta'] ?? '',
          via: clienteData['via'] ?? '',
          email: clienteData['email'] ?? '',
          telefono: clienteData['telefono'] ?? '',
          codiceFiscale: clienteData['codice_fiscale'] ?? '',
          idCliente: clienteData['id_cliente'],
        ),
      ),
    );
    if (result == true) fetchPreventivi();
  }

  Future<void> _navigateToNewDocumento(String nomeCliente, Map<String, dynamic> clienteData) async {
    final parts = nomeCliente.split(' ');
    final nome = parts.first;
    final cognome = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => createDocumento.CreateDocumentoFromClientePage(
          idCliente: clienteData['id_cliente'],
          nome: nome,
          cognome: cognome,
        ),
      ),
    );
    if (result == true) fetchDocumenti();
  }

Future<void> _generatePdf(Map<String, dynamic> preventivo) async {
  // Mostra il dialog di caricamento
  _showPdfLoadingDialog();
  
  try {
    await PdfService.generateAndOpenPdf(
      preventivo["id_preventivo"],
      preventivo,
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore generazione PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  } finally {
    // Chiudi il dialog
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
void _showPdfLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                SizedBox(height: 16),
                Text('Generazione PDF in corso...'),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Future<void> _editPreventivo(Map<String, dynamic> preventivo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModificaPreventivoPage(
          preventivo: preventivo,
          nome: preventivo['nome_cliente'],
          cognome: preventivo['cognome_cliente'],
          idCliente: preventivo['id_cliente'], 
        ),
      ),
    );
    if (result == true) fetchPreventivi();
  }

  Future<void> _deletePreventivo(int idPreventivo) async {
    final deleted = await confermaECancellaPreventivo(context, idPreventivo);
    if (deleted) fetchPreventivi();
  }

  Future<void> _viewDocumentDetails(Map<String, dynamic> doc) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DettaglioDocumentoPage(documento: doc),
      ),
    );
    if (shouldRefresh == true) {
      fetchDocumenti();
    }
  }

  String formatDataString(dynamic rawDate) {
    if (rawDate == null) return '';
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return '';
    return parsed.toIso8601String().substring(0, 10);
  }

  Map<String, List<Map<String, dynamic>>> groupPreventiviByAnno(List<Map<String, dynamic>> preventivi) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var preventivo in preventivi) {
      final date = DateTime.tryParse(preventivo["data_preventivo"] ?? '') ?? DateTime.now();
      final year = date.year.toString();
      grouped.putIfAbsent(year, () => []).add(preventivo);
    }
    return grouped;
  }
  

}
