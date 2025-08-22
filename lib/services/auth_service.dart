import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ADDED: Helper function to keep data deletion logic separate.
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
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('Re-authentication required. Prompting user to sign in again.');
        
        // If it fails, re-authenticate the user.
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Re-authentication cancelled by user.');
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);

        // After re-authentication, get a fresh user instance and retry deletion.
        user = _auth.currentUser;
        if (user == null) {
           throw Exception('User is null after re-authentication.');
        }
        print('Re-authentication successful. Retrying account deletion.');
        await _deleteFirestoreData(user.uid);
        await user.delete();
        await _googleSignIn.signOut();

      } else {
        print("Error deleting account: $e");
        rethrow;
      }
    } catch (e) {
      print("An unexpected error occurred: $e");
      rethrow;
    }
  }
}
