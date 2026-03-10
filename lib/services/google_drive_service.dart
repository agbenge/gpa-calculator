import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(authenticateClient);
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

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
