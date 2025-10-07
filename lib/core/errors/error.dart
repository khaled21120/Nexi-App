import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

abstract class Failure {
  final String errMsg;
  Failure(this.errMsg);

  @override
  String toString() => errMsg;
}

/// Server Failure (Firebase-related errors)
class ServerFailure extends Failure {
  ServerFailure(super.errMsg);

  factory ServerFailure.fromFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return ServerFailure('Your email address appears to be malformed.');
      case 'wrong-password':
        return ServerFailure('Your password is wrong.');
      case 'user-not-found':
        return ServerFailure("User with this email doesn't exist.");
      case 'user-disabled':
        return ServerFailure('User with this email has been disabled.');
      case 'too-many-requests':
        return ServerFailure('Too many requests. Try again later.');
      case 'operation-not-allowed':
        return ServerFailure(
          'Signing in with Email and Password is not enabled.',
        );
      case 'email-already-in-use':
        return ServerFailure(
          'The email is already in use by a different account.',
        );
      case 'invalid-credential':
        return ServerFailure(
          'The supplied auth credential is malformed or has expired.',
        );
      case 'requires-recent-login':
        return ServerFailure(
          'This operation is sensitive and requires recent authentication. Log in again before retrying this request.',
        );
      case 'account-exists-with-different-credential':
        return ServerFailure(
          'This account already exists with a different sign-in method. Try logging in differently.',
        );

      case 'weak-password':
        return ServerFailure('Your password is too weak.');
      default:
        return ServerFailure(
          'An undefined FirebaseAuth error happened: ${e.code}',
        );
    }
  }

  factory ServerFailure.fromFirebaseFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return ServerFailure('You do not have permission to access this data.');
      case 'unavailable':
        return ServerFailure('The service is currently unavailable.');
      case 'deadline-exceeded':
        return ServerFailure('The operation took too long to complete.');
      default:
        return ServerFailure(
          'An undefined Firestore error happened: ${e.code}',
        );
    }
  }

  factory ServerFailure.fromException(Object e) {
    if (e is FirebaseAuthException) {
      return ServerFailure.fromFirebaseAuthException(e);
    } else if (e is FirebaseException) {
      return ServerFailure.fromFirebaseFirestoreException(e);
    } else if (e is PlatformException) {
      switch (e.code) {
        case 'sign_in_canceled':
          return ServerFailure('Google sign-in was canceled.');
        case 'network_error':
          return ServerFailure('No internet connection for Google sign-in.');
        case 'sign_in_failed':
          return ServerFailure('Google sign-in failed. Please try again.');
        default:
          return ServerFailure('Google sign-in error: ${e.message ?? e.code}');
      }
    } else {
      return ServerFailure(e.toString());
    }
  }
}
