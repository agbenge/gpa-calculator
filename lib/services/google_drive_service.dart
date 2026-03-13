import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;
  GoogleSignInAccount? _currentUser;
  GoogleSignInClientAuthorization? _authorization;

  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await _googleSignIn.initialize(
         serverClientId: dotenv.env['CLIENT_ID'],
        );
      } catch (e) {
        print('GoogleSignIn Initialization Error:  : $e ');
      }
      _initialized = true;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      print(" initialised");
      _currentUser = await _googleSignIn.authenticate(
        scopeHint: _scopes,  );
      print(" Auth ");
      if (_currentUser != null) {
        print("User is  ${_currentUser!.email}");
        _authorization = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
      }else{
        print("User is null");
      }
      return _currentUser;
    } catch (e) {
      print('Google SignIn Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.disconnect();
      _currentUser = null;
      _authorization = null;
    } catch (e) {
      print('Google SignOut Error: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.attemptLightweightAuthentication( reportAllExceptions: true);
      if (account != null) {
        _currentUser = account;
        print('Google isSignedIn  ${account.email}');
        return true;
      }
      print('Google isSignedIn  nul  ');
      return false;
    } catch (e) {
      print('Google isSignedIn Error: $e');
      return false;
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      await _ensureInitialized();
      final account = _currentUser ?? await _googleSignIn.attemptLightweightAuthentication();
      if (account == null) return null;

      if (_authorization == null) {
        _authorization = await account.authorizationClient.authorizationForScopes(_scopes);
        if (_authorization == null) {
          _authorization = await account.authorizationClient.authorizeScopes(_scopes);
        }
      }

      final client = _authorization!.authClient(scopes: _scopes);
      return drive.DriveApi(client);
    } catch (e) {
      print('Google Drive API Error: $e');
      return null;
    }
  }

  Future<bool> uploadData(String jsonData) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return false;

    // Search for existing file in appDataFolder
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'gpa_data.json'",
    );

    final driveFile = drive.File()
      ..name = 'gpa_data.json'
      ..parents = ['appDataFolder'];

    final media = drive.Media(
      Stream.value(utf8.encode(jsonData)),
      jsonData.length,
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      // Update existing
      final fileId = fileList.files!.first.id!;
      await driveApi.files.update(driveFile, fileId, uploadMedia: media);
    } else {
      // Create new
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
    return true;
  }

  Future<String?> downloadData() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'gpa_data.json'",
    );

    if (fileList.files == null || fileList.files!.isEmpty) return null;

    final fileId = fileList.files!.first.id!;
    final response =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final contents = await response.stream.transform(utf8.decoder).join();
    return contents;
  }
}
