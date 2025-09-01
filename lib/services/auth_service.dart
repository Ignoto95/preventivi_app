import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
    static const List<String> ADMIN_UIDS = [
    'cpAq4pxuU1YU0fgi3Wzzr500dkq2',
    'eFuKQQ1ZtngUcVpjJ5Bo575WPdA3'
  ];
    // Nuovo metodo per verificare se è admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    return user != null && ADMIN_UIDS.contains(user.uid);
  }
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      //print('Utente corrente: ${_auth.currentUser?.uid}');
      //print('Email: ${_auth.currentUser?.email}');
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Errore durante il login con Google: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken(true); // true forza il refresh del token
      }
      return null;
    } catch (e) {
      print('Errore durante il recupero del token: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> handleUnauthorized() async {
    await signOut();
    // Qui potresti aggiungere la navigazione alla pagina di login
  }

  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  User? get currentUser => _auth.currentUser;
}