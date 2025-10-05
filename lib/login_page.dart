import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'main_home_page.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoAnimation;
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>(); // Aggiungi questa chiave per il Form

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadRememberMePreference();
    
    if (_rememberMe) {
      // Imposta persistenza e controlla se l'utente è già loggato
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        // Piccolo delay per far vedere l'animazione
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainHomePage()),
        );
      }
    }
  }

  Future<void> _loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveRememberMePreference(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', remember);
  }

  Future<void> _login() async {
    try {
      // Chiudi il contesto di autofill PRIMA del login
      TextInput.finishAutofillContext();

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Imposta la persistenza in base a "Ricordami"
      if (_rememberMe) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } else {
        await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // SALVA LA PREFERENZA DOPO IL LOGIN SUCCESSO
      await _saveRememberMePreference(_rememberMe);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainHomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo con animazione
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Image.asset(
                    'assests/Logosimone.png',
                    height: 150,
                  ),
                ),
                SizedBox(height: 40),
                
                // Form con animazione di fade
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: colorScheme.surface,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Form(
                          key: _formKey, // Aggiungi la chiave del Form
                          child: AutofillGroup(
                            child: Column(
                              children: [
                                Text(
                                  'Accesso all\'Area Riservata',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 24),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: colorScheme.onSurface),
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Inserisci la tua email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Inserisci un\'email valida';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  obscureText: true,
                                  style: TextStyle(color: colorScheme.onSurface),
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onEditingComplete: () {
                                    // Chiudi autofill e effettua login
                                    TextInput.finishAutofillContext();
                                    _handleLogin();
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Inserisci la tua password';
                                    }
                                    if (value.length < 6) {
                                      return 'La password deve essere di almeno 6 caratteri';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      fillColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return colorScheme.primary;
                                          }
                                          return colorScheme.onSurface.withOpacity(0.6);
                                        },
                                      ),
                                    ),
                                    Text(
                                      'Ricordami',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Accedi',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16.0),
                                          ),
                                          title: Text(
                                            "Assistenza Password",
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Per problemi di accesso contatta l'amministratore:"),
                                              SizedBox(height: 8),
                                              Text("• Invia email a: gm.angelini@outlook.com"),
                                              SizedBox(height: 12),
                                              Text("Ti risponderò al più presto!"),
                                            ],
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text("COPIA EMAIL"),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: "gm.angelini@outlook.com"));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Email copiata negli appunti")),
                                                );
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: Text("CHIUDI"),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    'Password dimenticata?',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}