import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_models.dart';
import 'cloud_service.dart';
import 'pdf_service.dart';

/// 自動バックアップサービス
/// 領収書保存時にGoogle Driveへ自動的にPDFをアップロードする
class AutoBackupService {
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _backupProviderKey = 'backup_provider'; // 'google_drive' or 'onedrive'
  static const String _wifiOnlyKey = 'backup_wifi_only';
  static const String _selectedTemplateKey = 'selected_receipt_template'; // テンプレートID

  /// 自動バックアップが有効かどうか
  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  /// 自動バックアップを有効/無効にする
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
  }

  /// バックアッププロバイダーを取得（デフォルト: Google Drive）
  static Future<String> getBackupProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupProviderKey) ?? 'google_drive';
  }

  /// バックアッププロバイダーを設定
  static Future<void> setBackupProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupProviderKey, provider);
  }

  /// Wi-Fi接続時のみバックアップするかどうか
  static Future<bool> isWifiOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wifiOnlyKey) ?? true; // デフォルトはWi-Fiのみ
  }

  /// Wi-Fi接続時のみバックアップする設定を変更
  static Future<void> setWifiOnly(bool wifiOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, wifiOnly);
  }

  /// 選択されているテンプレートIDを取得
  static Future<String> getSelectedTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedTemplateKey) ?? 'standard'; // デフォルトは標準様式
  }

  /// テンプレートIDを設定
  static Future<void> setSelectedTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTemplateKey, templateId);
  }

  /// 領収書をGoogle Driveに自動バックアップ
  /// 
  /// [receipt] - バックアップする領収書
  /// [issuer] - 発行者情報（PDFに含める）
  /// 
  /// 返り値: バックアップ成功時はGoogle DriveのファイルID、失敗時はnull
  static Future<String?> autoBackupReceipt({
    required Receipt receipt,
    IssuerProfile? issuer,
  }) async {
    try {
      // 自動バックアップが無効の場合はスキップ
      final isEnabled = await isAutoBackupEnabled();
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('📦 Auto backup is disabled');
        }
        return null;
      }

      // Google Driveにサインインしているか確認
      final isSignedIn = await CloudService.isSignedInToGoogleDrive();
      if (!isSignedIn) {
        if (kDebugMode) {
          debugPrint('❌ Not signed in to Google Drive');
        }
        return null;
      }

      // Wi-Fi接続チェック（将来的に実装）
      // final wifiOnly = await isWifiOnly();
      // if (wifiOnly && !await _isWifiConnected()) {
      //   debugPrint('📵 Waiting for Wi-Fi connection');
      //   return null;
      // }

      if (kDebugMode) {
        debugPrint('☁️ Auto backup started for receipt: ${receipt.receiptNumber}');
      }

      // PDFを生成
      final receiptData = {
        'receiptNumber': receipt.receiptNumber,
        'issueDate': receipt.issueDate,
        'recipientName': receipt.recipientName,
        'recipientAddress': receipt.recipientAddress,
        'amount': receipt.amount,
        'description': receipt.description,
        'paymentMethod': receipt.paymentMethod,
        'taxItems': receipt.taxItems,
      };
      
      final pdfDocument = await PdfService.generateReceiptPdf(receiptData, issuer);
      final pdfBytes = await pdfDocument.save();

      // ファイル名を生成
      final filename = _generateFilename(receipt);

      // Google Driveにアップロード
      final fileId = await CloudService.uploadToGoogleDrive(
        pdfBytes: pdfBytes,
        filename: filename,
      );

      if (fileId != null) {
        if (kDebugMode) {
          debugPrint('✅ Auto backup successful: $filename (ID: $fileId)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Auto backup failed: $filename');
        }
      }

      return fileId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Auto backup error: $e');
      }
      return null;
    }
  }

  /// ファイル名を生成
  /// 形式: Receipt_[領収書番号]_[YYYYMMDD].pdf
  /// 例: Receipt_RCP-20260215-001_20260215.pdf
  static String _generateFilename(Receipt receipt) {
    final dateStr = receipt.issueDate.toIso8601String().substring(0, 10).replaceAll('-', '');
    final sanitizedNumber = receipt.receiptNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    return 'Receipt_${sanitizedNumber}_$dateStr.pdf';
  }

  /// Google Driveフォルダを作成（オプション）
  /// 将来的に「Receipt Maker」フォルダを作成して整理可能
  static Future<String?> createReceiptFolder() async {
    try {
      final isSignedIn = await CloudService.isSignedInToGoogleDrive();
      if (!isSignedIn) {
        return null;
      }

      // TODO: フォルダ作成機能を実装
      // 現在はルートディレクトリに保存

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Folder creation error: $e');
      }
      return null;
    }
  }

  /// バックアップ統計を取得
  static Future<Map<String, dynamic>> getBackupStats() async {
    try {
      final files = await CloudService.listGoogleDriveFiles();
      return {
        'totalFiles': files.length,
        'lastBackupTime': files.isNotEmpty ? files.first['createdTime'] : null,
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'lastBackupTime': null,
      };
    }
  }
}
