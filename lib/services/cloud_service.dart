import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/foundation.dart';
import 'onedrive_service.dart';

class CloudService {
  // Google Drive scopes
  static const List<String> _driveScopes = [
    drive.DriveApi.driveFileScope,
  ];

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _driveScopes,
  );

  // Google Drive Authentication
  static Future<bool> signInToGoogleDrive() async {
    try {
      // Sign out first to force fresh authentication
      await _googleSignIn.signOut();
      
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        if (kDebugMode) {
          debugPrint('❌ Google Sign-In: User cancelled');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('✅ Google Sign-In successful: ${account.email}');
      }
      
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Google Sign-In error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  static Future<void> signOutFromGoogleDrive() async {
    await _googleSignIn.signOut();
  }

  static Future<bool> isSignedInToGoogleDrive() async {
    return _googleSignIn.currentUser != null;
  }

  static String? getGoogleDriveUserEmail() {
    return _googleSignIn.currentUser?.email;
  }

  // Upload PDF to Google Drive
  static Future<String?> uploadToGoogleDrive({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    try {
      final user = _googleSignIn.currentUser;
      if (user == null) {
        throw Exception('Not signed in to Google Drive');
      }

      // Get authenticated HTTP client
      final httpClient = (await _googleSignIn.authenticatedClient())!;
      final driveApi = drive.DriveApi(httpClient);

      // Create file metadata
      final driveFile = drive.File()
        ..name = filename
        ..mimeType = 'application/pdf';

      // Upload file
      final media = drive.Media(
        Stream.value(pdfBytes),
        pdfBytes.length,
      );

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      return result.id;
    } catch (e) {
      return null;
    }
  }

  // List files from Google Drive
  static Future<List<Map<String, String>>> listGoogleDriveFiles() async {
    try {
      final user = _googleSignIn.currentUser;
      if (user == null) {
        throw Exception('Not signed in to Google Drive');
      }

      final httpClient = (await _googleSignIn.authenticatedClient())!;
      final driveApi = drive.DriveApi(httpClient);

      final fileList = await driveApi.files.list(
        q: "mimeType='application/pdf'",
        orderBy: 'modifiedTime desc',
        pageSize: 50,
      );

      return (fileList.files ?? []).map((file) {
        return {
          'id': file.id ?? '',
          'name': file.name ?? '',
          'createdTime': file.createdTime?.toIso8601String() ?? '',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // OneDrive implementation using Microsoft Graph API
  static Future<bool> signInToOneDrive() async {
    return await OneDriveService.signIn();
  }

  static Future<void> signOutFromOneDrive() async {
    await OneDriveService.signOut();
  }

  static Future<bool> isSignedInToOneDrive() async {
    return await OneDriveService.isSignedIn();
  }

  static String? getOneDriveUserEmail() {
    // Note: This is async in OneDriveService, simplified here
    return null; // 実際の実装ではFutureBuilderで取得
  }

  static Future<String?> uploadToOneDrive({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    return await OneDriveService.uploadPdf(
      pdfBytes: pdfBytes,
      filename: filename,
    );
  }

  static Future<List<Map<String, String>>> listOneDriveFiles() async {
    return await OneDriveService.listPdfFiles();
  }

  // Get sync status
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final googleDriveSignedIn = await isSignedInToGoogleDrive();
    final oneDriveSignedIn = await isSignedInToOneDrive();
    final oneDriveEmail = oneDriveSignedIn ? await OneDriveService.getUserEmail() : null;

    return {
      'googleDrive': {
        'signedIn': googleDriveSignedIn,
        'email': getGoogleDriveUserEmail(),
      },
      'oneDrive': {
        'signedIn': oneDriveSignedIn,
        'email': oneDriveEmail,
      },
    };
  }
}
