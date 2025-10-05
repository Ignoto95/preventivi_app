import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Pagina che diventerà "Rubrica clienti"
//import 'login_page.dart'; 
//import 'package:firebase_auth/firebase_auth.dart';
import 'lista_richieste.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'revisioni_caldaie_page.dart';
import 'package:preventivi_app/services/api_client.dart';
import 'package:preventivi_app/services/auth_service.dart';


class MainHomePage extends StatefulWidget {
  @override
  _MainHomePageState createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;
  User? currentUser;
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

Future<Map<String, dynamic>> fetchStatistiche() async {
  try {
    final response = await _apiClient.get('statistiche');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      throw Exception('Sessione scaduta');
    } else {
      throw Exception('Errore ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento delle statistiche: ${e.toString()}')),
      );
    }
    return {
      'totaleClienti': 0,
      'preventiviPerAnno': [],
      'totaleCondizionatori': 0,
      'condizionatoriScadenza': {
        'scadute': 0,
        'in_scadenza_30gg': 0,
        'in_scadenza_90gg': 0,
        'non_scadute': 0
      },
    };
  }
}
  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
      if (!_authService.isAuthenticated()) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
  appBar: AppBar(
    title: Text('Home Page'),
  ),
      drawer: _buildDrawer(context),
      body: _getPage(_selectedIndex),
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
            setState(() => _selectedIndex = 0);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Rubrica Clienti'),
          onTap: () {
            Navigator.push(
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
            try {
              // Mostra un dialog di conferma
              bool? confirm = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Conferma Logout'),
                    content: Text('Sei sicuro di voler uscire?'),
                    actions: [
                      TextButton(
                        child: Text('Annulla'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('Esci'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );
        
              if (confirm == true) {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/', 
                    (route) => false
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore durante il logout: ${e.toString()}')),
                );
              }
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildWelcomePage() {
  return FutureBuilder(
    future: fetchStatistiche(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Errore nel caricamento delle statistiche'));
      }

      final data = snapshot.data as Map<String, dynamic>;
      final totaleClienti = data['totaleClienti'];
      final preventiviPerAnno = data['preventiviPerAnno'];
      final totaleCondizionatori = data['totaleCondizionatori'];
      final scadenze = data['condizionatoriScadenza'] ?? {
          'scadute': 0,
          'in_scadenza_30gg': 0,
          'in_scadenza_90gg': 0,
          'non_scadute': 0
        };

      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Benvenuto nell\'app gestionale di IMC',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Riga con statistiche e stato revisioni
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonna sinistra con le statistiche
                    Expanded(
                      child: Column(
                        children: [
                          // Statistiche Clienti
                          _buildStatCard(
                            icon: Icons.people,
                            title: 'Clienti',
                            value: '$totaleClienti',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Statistiche Condizionatori
                          _buildStatCard(
                            icon: Icons.ac_unit,
                            title: 'Condizionatori totali',
                            value: '$totaleCondizionatori',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Colonna destra con lo stato revisioni
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Stato Revisioni Condizionatori',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildScadenzaRow(
                                'Scadute',
                                scadenze['scadute'].toString(),
                                Colors.red,
                              ),
                              _buildScadenzaRow(
                                'In scadenza (30 giorni)',
                                scadenze['in_scadenza_30gg'].toString(),
                                Colors.orange,
                              ),
                              _buildScadenzaRow(
                                'In scadenza (90 giorni)',
                                scadenze['in_scadenza_90gg'].toString(),
                                Colors.amber,
                              ),
                              _buildScadenzaRow(
                                'Non scadute',
                                scadenze['non_scadute'].toString(),
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Preventivi per anno
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Preventivi per Anno',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...preventiviPerAnno.map<Widget>((item) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item["anno"]}'),
                                Text(
                                  '${item["totale"]}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
Widget _buildStatCard({required IconData icon, required String title, required String value}) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blue.shade600),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildScadenzaRow(String label, String value, Color color) {
  // Icona per ogni tipo di scadenza
  IconData? icon;
  String shortLabel = label;
  
  if (MediaQuery.of(context).size.width < 600) {
    switch (label) {
      case 'Scadute':
        icon = Icons.error_outline;
        shortLabel = 'Scadute';
        break;
      case 'In scadenza (30 giorni)':
        icon = Icons.warning_amber;
        shortLabel = '30gg';
        break;
      case 'In scadenza (90 giorni)':
        icon = Icons.info_outline;
        shortLabel = '90gg';
        break;
      case 'Non scadute':
        icon = Icons.check_circle_outline;
        shortLabel = 'Ok';
        break;
    }
  }

  return Padding( 
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            if (icon != null) Icon(icon, size: 18, color: color),
            if (icon != null) SizedBox(width: 4),
            Text(shortLabel),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}



Widget _getPage(int index) {
  switch (index) {
    case 0:
      return _buildWelcomePage();
    case 1:
      return HomePage();
    default:
      return Center(child: Text('Pagina non trovata'));
  }}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}