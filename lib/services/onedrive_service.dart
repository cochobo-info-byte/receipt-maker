import 'dart:typed_data';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

/// OneDrive連携サービス
/// Azure AD OAuthを使用してOneDriveへPDFをアップロード
class OneDriveService {
  static AadOAuth? _oauth;
  static String? _accessToken;
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Azure App Registration設定
  static const String _clientId = '65e3a6e1-9a27-4efa-bef9-6cde1f328325'; // Azure Portal > App registrations
  static const String _redirectUri = 'msauth://com.receiptmaker.receipt/Dx1gYOTSV3UyGZ%2BP%2FsCXrd%2Bqg8c%3D';
  static const String _tenant = 'common'; // マルチテナント対応

  /// OAuthクライアントの初期化
  static void _initOAuth() {
    if (_oauth != null) return;

    final config = Config(
      tenant: _tenant,
      clientId: _clientId,
      scope: 'Files.ReadWrite offline_access',
      redirectUri: _redirectUri,
      navigatorKey: _navigatorKey,
    );

    _oauth = AadOAuth(config);
  }

  /// OneDriveにサインイン
  static Future<bool> signIn() async {
    try {
      _initOAuth();
      await _oauth!.login();
      _accessToken = await _oauth!.getAccessToken();
      return _accessToken != null && _accessToken!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// OneDriveからサインアウト
  static Future<void> signOut() async {
    try {
      _initOAuth();
      await _oauth!.logout();
      _accessToken = null;
    } catch (e) {
      // エラーは無視
    }
  }

  /// サインイン状態を確認
  static Future<bool> isSignedIn() async {
    if (_accessToken == null) return false;
    try {
      _initOAuth();
      _accessToken = await _oauth!.getAccessToken();
      return _accessToken != null && _accessToken!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ユーザーのメールアドレスを取得（Microsoft Graph API）
  static Future<String?> getUserEmail() async {
    if (_accessToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['userPrincipalName'] ?? data['mail'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// PDFをOneDriveにアップロード
  /// Microsoft Graph API: PUT /me/drive/root:/path/filename.pdf:/content
  static Future<String?> uploadPdf({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    if (_accessToken == null) {
      throw Exception('OneDriveにサインインしていません');
    }

    try {
      // OneDrive API: Simple upload (< 4MB推奨)
      final uploadUrl = Uri.parse(
        'https://graph.microsoft.com/v1.0/me/drive/root:/Receipts/$filename:/content',
      );

      final response = await http.put(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/pdf',
        },
        body: pdfBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id']; // OneDriveファイルID
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// OneDriveからPDFファイル一覧を取得
  static Future<List<Map<String, String>>> listPdfFiles() async {
    if (_accessToken == null) return [];

    try {
      // Receiptsフォルダー内のPDFファイルを取得
      final response = await http.get(
        Uri.parse(
          'https://graph.microsoft.com/v1.0/me/drive/root:/Receipts:/children',
        ),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = data['value'] as List;

        return files
            .where((file) => file['name']?.toString().endsWith('.pdf') ?? false)
            .map((file) {
          return {
            'id': file['id']?.toString() ?? '',
            'name': file['name']?.toString() ?? '',
            'createdTime': file['createdDateTime']?.toString() ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
