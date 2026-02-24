import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // GoogleSignIn è un singleton
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  
  // Gestione manuale dello stato utente
  GoogleSignInAccount? _currentGoogleUser;
  
  // Flag per controllare se è già stato inizializzato (solo per Mobile)
  bool _isInitialized = false;

  Stream<User?> get user => _auth.authStateChanges();
  
  // Getter per l'utente Google corrente
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;
  bool get isSignedInWithGoogle => _currentGoogleUser != null;

  // Inizializzazione GoogleSignIn (obbligatorio per Mobile in v7.x, opzionale/diverso per Web)
  // OBBLIGATORIO: Inizializzazione asincrona
  Future<void> _ensureInitialized() async {
    if (kIsWeb) {
      // Sul Web l'inizializzazione è gestita implicitamente o tramite index.html
      return; 
    }
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
        
        // 'select_account' forza la schermata di scelta account Google
        googleProvider.setCustomParameters({'prompt': 'select_account'}); 

        // Usiamo signInWithPopup che è nativo per il web e gestisce tutto il flusso OAuth
        final UserCredential userCredential = 
            await _auth.signInWithPopup(googleProvider);
            
        // Sul web non usiamo _currentGoogleUser di google_sign_in perché
        // Firebase gestisce direttamente il provider.
        _currentGoogleUser = null; 
        
        return userCredential.user;

      } else {
        // --- LOGICA MOBILE ---
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

  // Tentativo di accesso silenzioso (Utile al riavvio dell'app)
  Future<User?> attemptSilentSignIn() async {
    // Sul Web, Firebase persiste la sessione automaticamente (LocalPersistence).
    // Di solito basta ascoltare lo stream 'user', ma se vuoi forzare un check:
    if (kIsWeb) {
      // Se c'è già un utente Firebase, lo restituiamo
      return _auth.currentUser;
    }

    // --- LOGICA MOBILE ---
    try {
      await _ensureInitialized();
      
      // Sostituisce signInSilently()
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
      // 1. Logout da Firebase (Fondamentale sia per Web che Mobile)
      await _auth.signOut();

      // 2. Logout da Google (Per pulire la cache del browser o lo stato nativo)
      if (kIsWeb) {
        // Sul Web, google_sign_in potrebbe non essere stato usato se abbiamo fatto
        // signInWithPopup tramite firebase_auth. Tuttavia, se è stato inizializzato,
        // proviamo a disconnetterlo. Spesso su web basta _auth.signOut().
        try {
           // Non chiamiamo _ensureInitialized() su web qui per evitare errori se non serve
           await _googleSignIn.disconnect(); 
        } catch (_) {
           // Ignora errori di disconnect su web (es. se non era loggato via plugin)
        }
      } else {
        // Su Mobile è obbligatorio per permettere il cambio account
        await _ensureInitialized();
        await _googleSignIn.signOut();
      }

      _currentGoogleUser = null;
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  // Helper function to keep data deletion logic separate.
  Future<void> _deleteFirestoreData(String userId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    
    // Recupera e cancella sottocollezioni (Teams -> Athletes -> Chronos)
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

  // Elimina Account e Dati (Gestione Re-autenticazione)
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
        debugPrint('Re-authentication required.');
        
        try {
          if (kIsWeb) {
            // --- RE-AUTH WEB ---
            GoogleAuthProvider googleProvider = GoogleAuthProvider();
            googleProvider.setCustomParameters({'prompt': 'select_account'});
            
            // Usa reauthenticateWithPopup per il web
            await user.reauthenticateWithPopup(googleProvider);
          } else {
            // --- RE-AUTH MOBILE ---
            await _ensureInitialized();
            final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
              scopeHint: ['email', 'profile'],
            );
            _currentGoogleUser = googleUser;
            
            final authClient = _googleSignIn.authorizationClient;
            final authorization = await authClient.authorizationForScopes(['email', 'profile']);
            
            if (authorization == null) throw Exception('Failed authorization');
            
            final GoogleSignInAuthentication googleAuth = googleUser.authentication;
            final AuthCredential credential = GoogleAuthProvider.credential(
              accessToken: authorization.accessToken,
              idToken: googleAuth.idToken,
            );
            
            await user.reauthenticateWithCredential(credential);
          }

          // Dopo re-auth riuscita, riprova a cancellare
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