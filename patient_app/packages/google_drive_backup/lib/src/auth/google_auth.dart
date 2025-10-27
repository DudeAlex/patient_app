import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    show GoogleSignInException;

/// Wrapper around google_sign_in v7 that centralises initialization, diagnostics,
/// and Drive scope header retrieval.
class GoogleAuthService {
  /// Provide a web client ID at build time:
  /// flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Provide an Android server client ID (Web client ID) at build time:
  /// flutter run -d <android_device> --dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
  static const _androidServerClientId =
      String.fromEnvironment('GOOGLE_ANDROID_SERVER_CLIENT_ID');

  bool _initialized = false;
  static const bool _debug =
      bool.fromEnvironment('GOOGLE_AUTH_DEBUG', defaultValue: true);
  static String? _cachedEmail;

  void _log(String msg) {
    if (_debug) debugPrint('[Auth] ' + msg);
  }

  String? get cachedEmail => _cachedEmail;

  void _rememberEmail(String? email) {
    if (email == null || email.isEmpty) {
      _cachedEmail = null;
    } else {
      _cachedEmail = email;
    }
  }

  String _sanitize(String v) {
    final t = v.trim();
    if (t.length >= 2 &&
        ((t.startsWith('"') && t.endsWith('"')) ||
            (t.startsWith('\'') && t.endsWith('\'')))) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  String get androidServerClientIdTail {
    final sanitized = _sanitize(_androidServerClientId);
    return sanitized.length > 10
        ? sanitized.substring(sanitized.length - 10)
        : sanitized;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _log('Initializing GoogleSignIn');
    if (kIsWeb) {
      await GoogleSignIn.instance.initialize(
        clientId: _webClientId.isNotEmpty ? _webClientId : null,
      );
      if (_webClientId.isEmpty) {
        _log('WARN: GOOGLE_WEB_CLIENT_ID not provided; web sign-in may fail');
      }
    } else {
      // Log environment/platform basics for diagnostics
      try {
        _log('Platform: ' +
            Platform.operatingSystem +
            ' | OS version: ' +
            (Platform.operatingSystemVersion.split('\n').first));
      } catch (_) {}
      final sanitized = _sanitize(_androidServerClientId);
      await GoogleSignIn.instance.initialize(
        serverClientId: sanitized.isNotEmpty ? sanitized : null,
      );
      if (sanitized.isEmpty) {
        _log('ERROR: GOOGLE_ANDROID_SERVER_CLIENT_ID not provided; Android sign-in will fail');
      } else {
        final suffix = sanitized.length > 10
            ? sanitized.substring(sanitized.length - 10)
            : sanitized;
        _log('Using Android server client id (...$suffix)');
        if (!(sanitized.endsWith('.apps.googleusercontent.com') &&
            sanitized.contains('-'))) {
          _log('WARN: serverClientId does not look like a Web OAuth client id (*.apps.googleusercontent.com)');
        }
      }
    }
    _initialized = true;
    _log('GoogleSignIn initialized');
  }

  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      _log('Starting interactive authenticate');
      final acc = await GoogleSignIn.instance.authenticate();
      if (acc == null) {
        _log('authenticate returned null (cancelled or failed)');
      } else {
        _log('authenticate success for: ' + acc.email);
        _rememberEmail(acc.email);
      }
      return acc;
    } on GoogleSignInException catch (e, st) {
      final msg = e.toString();
      _log('authenticate error: code=' + e.code.toString() + ', message=' + msg);
      if (msg.toLowerCase().contains('reauth failed') ||
          e.code.toString().toLowerCase().contains('canceled')) {
        _log('HINT: Ensure the emulator has a signed-in Google account, Play services are up to date, and your account is added as a Test user in the OAuth consent screen.');
      }
      _log('STACK: ' + st.toString().split('\n').first);
      return null;
    } catch (e, st) {
      _log('authenticate error (unexpected): ' + e.toString());
      _log('STACK: ' + st.toString().split('\n').first);
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    debugPrint('[Auth] Signing out');
    _rememberEmail(null);
    await GoogleSignIn.instance.disconnect();
  }

  Future<Map<String, String>?> getAuthHeaders({
    bool promptIfNecessary = false,
  }) async {
    await _ensureInitialized();
    try {
      _log('Fetching auth headers (promptIfNecessary: ' +
          promptIfNecessary.toString() +
          ')');
      final headers =
          await GoogleSignIn.instance.authorizationClient.authorizationHeaders(
        const ['https://www.googleapis.com/auth/drive.appdata'],
        promptIfNecessary: promptIfNecessary,
      );
      if (headers == null) {
        _log('authorizationHeaders returned null');
        return null;
      }
      if (headers.isEmpty) {
        _log('authorizationHeaders returned empty map');
        return headers;
      }
      _log('authorizationHeaders success; keys: ' + headers.keys.join(', '));
      return headers;
    } on GoogleSignInException catch (e, st) {
      _log('authorizationHeaders error: code=' +
          e.code.toString() +
          ', message=' +
          e.toString());
      _log('STACK: ' + st.toString().split('\n').first);
      return null;
    } catch (e, st) {
      _log('authorizationHeaders error (unexpected): ' + e.toString());
      _log('STACK: ' + st.toString().split('\n').first);
      return null;
    }
  }

  Future<String?> tryGetEmail() async {
    await _ensureInitialized();
    try {
      final cached = _cachedEmail;
      if (cached != null) {
        _log('Using cached email: ' + cached);
        return cached;
      }
      final fut = GoogleSignIn.instance.attemptLightweightAuthentication();
      final acc = await (fut ?? Future<GoogleSignInAccount?>.value(null));
      if (acc?.email != null) {
        _log('Lightweight auth success for: ' + acc!.email);
        _rememberEmail(acc.email);
      } else {
        _log('Lightweight auth returned null');
      }
      return acc?.email;
    } on GoogleSignInException catch (e, st) {
      _log('Lightweight auth error: code=' +
          e.code.toString() +
          ', message=' +
          e.toString());
      _log('STACK: ' + st.toString().split('\n').first);
      return null;
    } catch (e, st) {
      _log('Lightweight auth error (unexpected): ' + e.toString());
      _log('STACK: ' + st.toString().split('\n').first);
      return null;
    }
  }

  Future<String> diagnostics() async {
    final buf = StringBuffer();
    buf.writeln('Diagnostics start');
    buf.writeln('kIsWeb: ' + kIsWeb.toString());
    if (!kIsWeb) {
      try {
        buf.writeln('Platform: ' +
            Platform.operatingSystem +
            ' | ' +
            Platform.operatingSystemVersion.split('\n').first);
      } catch (_) {}
      final cid = _sanitize(_androidServerClientId);
      buf.writeln('ServerClientId set: ' +
          (cid.isNotEmpty).toString() +
          ' (tail: ...' +
          (androidServerClientIdTail) +
          ')');
    } else {
      buf.writeln('WebClientId set: ' + (_webClientId.isNotEmpty).toString());
    }
    buf.writeln('Initialized: ' + _initialized.toString());

    await _ensureInitialized();

    try {
      final fut = GoogleSignIn.instance.attemptLightweightAuthentication();
      final acc = await (fut ?? Future<GoogleSignInAccount?>.value(null));
      buf.writeln('Lightweight: ' + (acc?.email ?? 'null'));
      if (acc?.email != null) _rememberEmail(acc!.email);
    } catch (e) {
      buf.writeln('Lightweight EX: ' + e.toString());
    }

    try {
      final acc = await GoogleSignIn.instance.authenticate();
      buf.writeln('Authenticate: ' + (acc?.email ?? 'null'));
      if (acc?.email != null) _rememberEmail(acc!.email);
    } on GoogleSignInException catch (e) {
      buf.writeln('Authenticate EX: code=' +
          e.code.toString() +
          ' msg=' +
          e.toString());
    } catch (e) {
      buf.writeln('Authenticate EX: ' + e.toString());
    }

    try {
      final headers =
          await GoogleSignIn.instance.authorizationClient.authorizationHeaders(
        const ['email'],
        promptIfNecessary: true,
      );
      buf.writeln('AuthHeaders(email): ' +
          (headers == null ? 'null' : 'ok keys=' + headers.keys.join(',')));
    } on GoogleSignInException catch (e) {
      buf.writeln('AuthHeaders(email) EX: code=' +
          e.code.toString() +
          ' msg=' +
          e.toString());
    } catch (e) {
      buf.writeln('AuthHeaders(email) EX: ' + e.toString());
    }

    try {
      final headers =
          await GoogleSignIn.instance.authorizationClient.authorizationHeaders(
        const ['https://www.googleapis.com/auth/drive.appdata'],
        promptIfNecessary: true,
      );
      buf.writeln('AuthHeaders(drive.appdata): ' +
          (headers == null ? 'null' : 'ok keys=' + headers.keys.join(',')));
    } on GoogleSignInException catch (e) {
      buf.writeln('AuthHeaders(drive.appdata) EX: code=' +
          e.code.toString() +
          ' msg=' +
          e.toString());
    } catch (e) {
      buf.writeln('AuthHeaders(drive.appdata) EX: ' + e.toString());
    }

    final s = buf.toString();
    for (final line in s.split('\n')) {
      if (line.isNotEmpty) _log('[Diag] ' + line);
    }
    return s;
  }
}
