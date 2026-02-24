import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Importiamo le risorse locali e di auth
import 'firebase_options.dart';
import 'auth_service.dart';
import '../../repositories/database_repository.dart';

class CloudSyncService {
  final DatabaseRepository _localDb;
  
  // Flag per evitare inizializzazioni multiple
  bool _isInitialized = false;

  CloudSyncService(this._localDb);

  /// 1. Inizializza Firebase "on demand" (Lazy Initialization)
  Future<void> _ensureFirebaseReady() async {
    if (!_isInitialized) {
      try {
        // Controlla se è già stata inizializzata un'app Firebase
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        _isInitialized = true;
      } catch (e) {
        debugPrint("Errore inizializzazione Firebase: $e");
        rethrow; // Rilancia l'errore per gestirlo nella UI
      }
    }
  }

  /// 2. Esegue il Backup: Local DB (Sembast) -> Cloud (Firestore)
  Future<void> backupToCloud(BuildContext context) async {
    // A. Accendi i motori (Firebase)
    await _ensureFirebaseReady();

    // B. ORA possiamo creare l'AuthService in sicurezza
    final authService = AuthService();

    // C. Controlla Autenticazione
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Se non loggato, mostra popup Google
      user = await authService.signInWithGoogle();
      if (user == null) {
        // Utente ha annullato il login
        throw Exception("Login annullato o fallito");
      }
    }

    final String userId = user.uid;
    final firestore = FirebaseFirestore.instance;
    
    // Usiamo un Batch per scrivere tutto insieme (più efficiente)
    // Nota: Il batch ha un limite di 500 operazioni. Se hai tantissimi dati,
    // andrebbe diviso, ma per ora va bene così.
    final batch = firestore.batch();

    debugPrint("Inizio Backup per utente: $userId");

    // --- D. Leggi tutto dal Locale ---
    // Usiamo .first per ottenere un'istantanea (snapshot) dei dati attuali
    final teams = await _localDb.getTeamsStream().first;

    for (var team in teams) {
      // 1. Scrivi Team
      final teamRef = firestore
          .collection('users')
          .doc(userId)
          .collection('teams')
          .doc(team.id);
      
      batch.set(teamRef, team.toMap());

      // 2. Leggi e Scrivi Atleti del Team
      final athletes = await _localDb.getAthletesStream(team.id).first;
      
      for (var athlete in athletes) {
        final athleteRef = teamRef.collection('athletes').doc(athlete.id);
        batch.set(athleteRef, athlete.toMap());

        // 3. Leggi e Scrivi Tempi dell'Atleta
        final chronos = await _localDb.getChronosStream(athlete.id).first;
        
        for (var chrono in chronos) {
          final chronoRef = athleteRef.collection('chronos').doc(chrono.id);
          
          // CONVERSIONE IMPORTANTE:
          // Sembast salva le date come int (millisecondi).
          // Firestore vuole Timestamp. Facciamo la conversione qui al volo.
          final chronoMap = chrono.toMap();
          // Conversione int -> Timestamp
          if (chronoMap['date'] is int) {
            chronoMap['date'] = Timestamp.fromMillisecondsSinceEpoch(chronoMap['date']);
          }
          
          batch.set(chronoRef, chronoMap);
        }
      }
    }

    // --- E. Invia tutto al Cloud ---
    await batch.commit();
    debugPrint("Backup completato con successo!");
  }

  /// Logout (Opzionale, se vuoi permettere di cambiare account sync)
  Future<void> signOut() async {
    await _ensureFirebaseReady();
    // Creiamo l'istanza al volo anche qui
    final authService = AuthService();
    await authService.signOut();
  }
}