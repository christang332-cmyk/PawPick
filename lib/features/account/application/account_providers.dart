import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/config.dart';
import '../../../data/firestore_repository.dart';

class AccountState {
  const AccountState({
    this.email,
    this.name,
    this.photoUrl,
    this.isLoading = false,
    this.error,
  });

  final String? email;
  final String? name;
  final String? photoUrl;
  final bool isLoading;
  final String? error;

  bool get isSignedIn => email != null;

  AccountState copyWith({
    String? email,
    String? name,
    String? photoUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AccountState(
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final accountProvider =
    NotifierProvider<AccountNotifier, AccountState>(AccountNotifier.new);

class AccountNotifier extends Notifier<AccountState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.googleServerClientId.isEmpty
        ? null
        : AppConfig.googleServerClientId,
  );
  StreamSubscription<User?>? _subscription;

  @override
  AccountState build() {
    _subscription = _auth.authStateChanges().listen(_setUser);
    ref.onDispose(() => _subscription?.cancel());
    _setUser(_auth.currentUser);
    return const AccountState();
  }

  void _setUser(User? user) {
    state = user == null
        ? const AccountState()
        : AccountState(
            email: user.email,
            name: user.displayName ?? user.email?.split('@').first,
            photoUrl: user.photoURL,
          );
  }

  Future<String?> signIn(String email, String password) async {
    final validation = validateCredentials(email, password);
    if (validation != null) return validation;
    return _authenticate(
      () => _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .then((credential) => credential.user),
    );
  }

  Future<String?> signUp(String name, String email, String password) async {
    if (name.trim().isEmpty) return 'Enter your name.';
    final validation = validateCredentials(email, password);
    if (validation != null) return validation;
    return _authenticate(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      return credential.user;
    }, postLogin: (user) async {
      await firestoreRepository.saveProfile(
        uid: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
      );
    });
  }

  Future<String?> signInWithGoogle() async {
    GoogleSignInAccount? googleAccountForProfile;
    return _authenticate(() async {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw const GoogleSignInCancelledException();
      }
      googleAccountForProfile = googleAccount;
      final authentication = await googleAccount.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInConfigurationException();
      }
      final googleCredential = GoogleAuthProvider.credential(idToken: idToken);
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email?.toLowerCase() ==
              googleAccount.email.toLowerCase()) {
        await currentUser.linkWithCredential(googleCredential);
        return currentUser;
      }
      final result = await _auth.signInWithCredential(googleCredential);
      return result.user;
    }, postLogin: (user) async {
      final account = googleAccountForProfile;
      if (account == null) return;
      await _saveGoogleProfile(
        user,
        account,
      );
    });
  }

  Future<void> _saveGoogleProfile(
    User user,
    GoogleSignInAccount googleAccount,
  ) {
    return firestoreRepository.ensureGoogleProfile(
      uid: user.uid,
      name: user.displayName ?? googleAccount.displayName ?? 'PawPick friend',
      email: user.email ?? googleAccount.email,
      photoUrl: user.photoURL ?? googleAccount.photoUrl,
    );
  }

  Future<String?> sendPasswordReset(String email) async {
    if (!isValidEmail(email)) return 'Enter a valid email address.';
    return _run(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  void continueAsGuest() {
    state = const AccountState(name: 'Guest');
  }

  Future<String?> _authenticate(
    Future<User?> Function() action, {
    Future<void> Function(User user)? postLogin,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    User? authenticatedUser;
    try {
      authenticatedUser = await action();
    } on GoogleSignInCancelledException {
      state = state.copyWith(isLoading: false);
      return null;
    } on GoogleSignInConfigurationException {
      state = state.copyWith(isLoading: false);
      return 'Google sign-in is not configured for this app yet.';
    } on FirebaseAuthException catch (error) {
      authenticatedUser = _auth.currentUser;
      if (authenticatedUser == null) {
        state = state.copyWith(isLoading: false, error: error.message);
        return _authMessage(error.code);
      }
      debugPrint('Authentication completed with recoverable error: $error');
    } on FirebaseException catch (error) {
      authenticatedUser = _auth.currentUser;
      if (authenticatedUser == null) {
        state = state.copyWith(isLoading: false, error: error.message);
        return error.code == 'unavailable'
            ? 'Check your internet connection and try again.'
            : 'We could not finish sign-in. Please try again.';
      }
      debugPrint('Authentication completed with recoverable Firebase error: $error');
    } on PlatformException catch (error) {
      authenticatedUser = _auth.currentUser;
      if (authenticatedUser != null) {
        debugPrint('Authentication completed with recoverable platform error: $error');
      } else {
        state = state.copyWith(isLoading: false);
        switch (error.code) {
          case 'sign_in_canceled':
          case 'canceled':
            return null;
          case 'network_error':
            return 'Check your internet connection and try again.';
          case 'sign_in_failed':
            return 'Google sign-in failed. Confirm the Android SHA fingerprints '
                'and refresh google-services.json.';
          case 'sign_in_required':
            return 'Select a Google account to continue.';
          default:
            return 'Google sign-in is unavailable right now. Please try again.';
        }
      }
    } on Exception catch (error) {
      authenticatedUser = _auth.currentUser;
      if (authenticatedUser == null) {
        state = state.copyWith(isLoading: false);
        final message = error.toString().toLowerCase();
        if (message.contains('network')) {
          return 'Check your internet connection and try again.';
        }
        return 'Google sign-in is unavailable right now. Please try again.';
      }
      debugPrint('Authentication completed with recoverable error: $error');
    }
    authenticatedUser ??= _auth.currentUser;
    if (authenticatedUser == null) {
      state = state.copyWith(isLoading: false);
      return 'We could not finish sign-in. Please try again.';
    }
    await _runPostLogin(authenticatedUser, postLogin);
    state = state.copyWith(isLoading: false);
    return null;
  }

  Future<void> _runPostLogin(
    User user,
    Future<void> Function(User user)? postLogin,
  ) async {
    if (postLogin == null) return;
    try {
      await postLogin(user);
    } catch (error) {
      debugPrint('Non-fatal post-login work failed: $error');
      unawaited(Future<void>.delayed(const Duration(seconds: 2), () async {
        try {
          await postLogin(user);
        } catch (retryError) {
          debugPrint('Non-fatal post-login retry failed: $retryError');
        }
      }));
    }
  }

  Future<String?> _run(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
      return null;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      return _authMessage(error.code);
    } catch (error) {
      debugPrint('Account action failed: $error');
      state = state.copyWith(isLoading: false);
      return 'Check your internet connection and try again.';
    }
  }
}

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}

class GoogleSignInConfigurationException implements Exception {
  const GoogleSignInConfigurationException();
}

String? validateCredentials(String email, String password) {
  if (!isValidEmail(email)) return 'Enter a valid email address.';
  if (password.length < 8) return 'Password must be at least 8 characters.';
  if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return 'Password must include a letter and a number.';
  }
  return null;
}

bool isValidEmail(String value) {
  return RegExp(
    r'^[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  ).hasMatch(value.trim());
}

String _authMessage(String code) {
  switch (code) {
    case 'wrong-password':
    case 'user-not-found':
      return 'The email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account already exists for this email. Sign in with email first, then use Google to link it.';
    case 'account-exists-with-different-credential':
      return 'This email already uses another sign-in method. Sign in with email first, then use Google to link it.';
    case 'credential-already-in-use':
      return 'This Google account is already linked to another PawPick account.';
    case 'operation-not-allowed':
      return 'Google sign-in is disabled in Firebase. Enable it in Authentication settings.';
    case 'invalid-api-key':
      return 'Firebase configuration is out of date. Download a fresh google-services.json.';
    case 'invalid-credential':
      return 'Google returned an invalid credential. Confirm the Web OAuth client ID and enable Google sign-in in Firebase.';
    case 'provider-already-linked':
      return 'Google is already linked to this PawPick account.';
    case 'requires-recent-login':
      return 'Please sign in again before linking Google.';
    case 'weak-password':
      return 'Choose a stronger password.';
    case 'network-request-failed':
      return 'Check your internet connection and try again.';
    default:
      return 'Authentication failed. Please try again.';
  }
}
