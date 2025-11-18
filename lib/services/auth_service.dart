import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // FIXED: GoogleSignIn è ora un singleton - non più istanziato direttamente
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  
  // Gestione manuale dello stato utente (currentUser non esiste più)
  GoogleSignInAccount? _currentGoogleUser;
  // Flag per controllare se è già stato inizializzato
  bool _isInitialized = false;

  Stream<User?> get user => _auth.authStateChanges();
  
  // Getter per l'utente Google corrente (gestione manuale)
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;
  bool get isSignedInWithGoogle => _currentGoogleUser != null;

  // NUOVO: Metodo per inizializzare GoogleSignIn (obbligatorio in v7.x)
  // OBBLIGATORIO: Inizializzazione asincrona
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // --- LOGICA WEB ---
        // Molto più semplice, gestisce tutto Firebase
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // Richiedi esplicitamente l'account, anche se loggato altrove
        googleProvider.setCustomParameters({'prompt': 'select_account'}); 

        final UserCredential userCredential = 
            await _auth.signInWithPopup(googleProvider);
        _currentGoogleUser = null; // Sul web non gestiamo _currentGoogleUser
        return userCredential.user;

      } else {
        // Step 1: Inizializza GoogleSignIn
        // OBBLIGATORIO: Inizializza GoogleSignIn prima di qualsiasi operazione
        await _ensureInitialized();

        // Step 2: Autenticazione con Google (sostituisce signIn())
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
          scopeHint: ['email', 'profile'], // Specifica gli scope necessari
        );
      
        // Step 3: Aggiorna lo stato utente manualmente
        _currentGoogleUser = googleUser;

        // Step 4: Ottieni l'autorizzazione per gli scope necessari
        final authClient = _googleSignIn.authorizationClient;
        final authorization = await authClient.authorizationForScopes(['email', 'profile']);
      
        if (authorization == null) {
          throw Exception('Failed to get authorization for required scopes');
        }

        // Step 5: Ottieni l'authentication (ora sincrono)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // Step 6: Crea le credenziali Firebase
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken, // Usa il token dall'authorization
          idToken: googleAuth.idToken,
        );

        // Step 7: Accedi a Firebase
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In error: ${e.code.name} - ${e.description}');
      _currentGoogleUser = null; // Reset stato in caso di errore
      return null;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      _currentGoogleUser = null; // Reset stato in caso di errore
      return null;
    }
  }

  // Tentativo di accesso silenzioso
  Future<User?> attemptSilentSignIn() async {
    try {
      await _ensureInitialized();
      
      // FIXED: sostituisce signInSilently()
      final result = _googleSignIn.attemptLightweightAuthentication();
      GoogleSignInAccount? googleUser;
      
      // Gestisce sia risultati sincroni che asincroni
      if (result is Future<GoogleSignInAccount?>) {
        googleUser = await result;
      } else {
        googleUser = result as GoogleSignInAccount?;
      }
      
      if (googleUser != null) {
        _currentGoogleUser = googleUser;
        
        // Ottieni autorizzazione e procedi con Firebase
        final authClient = _googleSignIn.authorizationClient;
        final authorization = await authClient.authorizationForScopes(['email', 'profile']);
        
        if (authorization != null) {
          final GoogleSignInAuthentication googleAuth = googleUser.authentication;
          
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: authorization.accessToken,
            idToken: googleAuth.idToken,
          );
          
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          return userCredential.user;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      _currentGoogleUser = null;
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentGoogleUser = null; // Reset stato manuale
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  // Helper function to keep data deletion logic separate.
  Future<void> _deleteFirestoreData(String userId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final teamsSnapshot = await userDocRef.collection('teams').get();
    for (final teamDoc in teamsSnapshot.docs) {
      final athletesSnapshot = await teamDoc.reference.collection('athletes').get();
      for (final athleteDoc in athletesSnapshot.docs) {
        final chronosSnapshot = await athleteDoc.reference.collection('chronos').get();
        for (final chronoDoc in chronosSnapshot.docs) {
          await chronoDoc.reference.delete();
        }
        await athleteDoc.reference.delete();
      }
      await teamDoc.reference.delete();
    }
    await userDocRef.delete();
  }

  // UPDATED: Refactored to be non-recursive and more robust.
  Future<void> deleteAccountAndData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user is currently signed in.");
    }

    try {
      // First, attempt to delete all data and the user account.
      await _deleteFirestoreData(user.uid);
      await user.delete();
      await signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('Re-authentication required. Prompting user to sign in again.');
        
        try {
          // FIXED: Usa il nuovo pattern v7.x per la re-autenticazione
          await _ensureInitialized();
          
          // FIXED: Re-autenticazione con Google con nuovo pattern v7.x
          final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
            scopeHint: ['email', 'profile'],
          );
          
          _currentGoogleUser = googleUser;
          
          // Ottieni autorizzazione per la re-autenticazione
          final authClient = _googleSignIn.authorizationClient;
          final authorization = await authClient.authorizationForScopes(['email', 'profile']);
          
          if (authorization == null) {
            throw Exception('Failed to get authorization during re-authentication');
          }
          
          final GoogleSignInAuthentication googleAuth = googleUser.authentication;
          
          // Crea le credenziali per la re-autenticazione
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: authorization.accessToken,
            idToken: googleAuth.idToken,
          );
          
          // Step 4: Re-autentica l'utente
          await user.reauthenticateWithCredential(credential);

          // Ottieni l'istanza utente aggiornata e ritenta l'eliminazione
          user = _auth.currentUser;
          if (user == null) {
            throw Exception('User is null after re-authentication.');
          }
          
          debugPrint('Re-authentication successful. Retrying account deletion.');
          await _deleteFirestoreData(user.uid);
          await user.delete();
          await signOut();
          
        } catch (reauthError) {
          debugPrint("Error during re-authentication: $reauthError");
          rethrow;
        }
      } else {
        debugPrint("Error deleting account: $e");
        rethrow;
      }
    } catch (e) {
      debugPrint("An unexpected error occurred: $e");
      rethrow;
    }
  }

  // Metodo per ottenere token di accesso per scope specifici
  Future<String?> getAccessTokenForScopes(List<String> scopes) async {
    try {
      await _ensureInitialized();
      
      final authClient = _googleSignIn.authorizationClient;
      
      // Prova ad ottenere autorizzazione esistente
      var authorization = await authClient.authorizationForScopes(scopes);
      
      if (authorization == null && _currentGoogleUser != null) {
        // Richiedi nuova autorizzazione
        authorization = await authClient.authorizeScopes(scopes);
      }
      
      return authorization?.accessToken;
    } catch (e) {
      debugPrint('Failed to get access token for scopes: $e');
      return null;
    }
  }

  // Metodo helper per gestire errori GoogleSignInException
  String? _getGoogleSignInErrorMessage(GoogleSignInException exception) {
    switch (exception.code.name) {
      case 'canceled':
        return 'Sign-in was cancelled. Please try again if you want to continue.';
      case 'interrupted':
        return 'Sign-in was interrupted. Please try again.';
      case 'clientConfigurationError':
        return 'There is a configuration issue with Google Sign-In. Please contact support.';
      case 'providerConfigurationError':
        return 'Google Sign-In is currently unavailable. Please try again later or contact support.';
      case 'uiUnavailable':
        return 'Google Sign-In is currently unavailable. Please try again later or contact support.';
      case 'userMismatch':
        return 'There was an issue with your account. Please sign out and try again.';
      case 'unknownError':
      default:
        return 'An unexpected error occurred during Google Sign-In. Please try again.';
    }
  }
}