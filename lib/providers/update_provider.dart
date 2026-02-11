import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents the result of an update check
sealed class UpdateResult {}

class UpdateAvailable extends UpdateResult {
  final String version;
  final String downloadUrl;
  final String releasePageUrl;
  final String? releaseNotes;
  final int? apkSize;

  UpdateAvailable({
    required this.version,
    required this.downloadUrl,
    required this.releasePageUrl,
    this.releaseNotes,
    this.apkSize,
  });
}

class NoUpdate extends UpdateResult {}

class UpdateError extends UpdateResult {
  final String message;
  UpdateError(this.message);
}

/// Represents the state of an APK download
enum DownloadState { idle, downloading, completed, failed }

/// Provider for checking and downloading app updates from GitHub
class UpdateProvider extends ChangeNotifier {
  static const String _githubRepo = 'raveuk/TaskOrbit';
  static const String _apiUrl = 'https://api.github.com/repos/$_githubRepo/releases';
  static const String _lastCheckKey = 'last_update_check';
  static const String _skippedVersionKey = 'skipped_version';

  final Dio _dio = Dio();

  UpdateResult? _updateResult;
  DownloadState _downloadState = DownloadState.idle;
  int _downloadProgress = 0;
  String? _downloadedFilePath;
  String? _downloadError;
  String _currentVersion = '1.0.0';
  bool _isChecking = false;
  CancelToken? _cancelToken;

  UpdateResult? get updateResult => _updateResult;
  DownloadState get downloadState => _downloadState;
  int get downloadProgress => _downloadProgress;
  String? get downloadedFilePath => _downloadedFilePath;
  String? get downloadError => _downloadError;
  String get currentVersion => _currentVersion;
  bool get isChecking => _isChecking;
  bool get hasUpdate => _updateResult is UpdateAvailable;

  UpdateProvider() {
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  /// Check GitHub releases for a newer version
  Future<UpdateResult> checkForUpdate({bool force = false}) async {
    if (_isChecking) return _updateResult ?? NoUpdate();

    _isChecking = true;
    notifyListeners();

    try {
      // Check if we should skip this check (unless forced)
      if (!force) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Only check once every 6 hours
        if (now - lastCheck < 6 * 60 * 60 * 1000) {
          _isChecking = false;
          notifyListeners();
          return _updateResult ?? NoUpdate();
        }
      }

      final response = await _dio.get(
        _apiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'TaskOrbit-Flutter',
          },
        ),
      );

      if (response.statusCode != 200) {
        _updateResult = UpdateError('Server returned: ${response.statusCode}');
        _isChecking = false;
        notifyListeners();
        return _updateResult!;
      }

      final releases = response.data as List;
      _updateResult = _parseReleasesResponse(releases);

      // Save last check time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

      _isChecking = false;
      notifyListeners();
      return _updateResult!;
    } catch (e) {
      _updateResult = UpdateError(e.toString());
      _isChecking = false;
      notifyListeners();
      return _updateResult!;
    }
  }

  UpdateResult _parseReleasesResponse(List releases) {
    if (releases.isEmpty) return NoUpdate();

    for (final release in releases) {
      // Skip prereleases and drafts
      if (release['prerelease'] == true || release['draft'] == true) {
        continue;
      }

      final tagName = release['tag_name'] as String;
      final latestVersion = tagName.replaceFirst('v', '');

      if (_isNewerVersion(_currentVersion, latestVersion)) {
        // Find APK asset
        final assets = release['assets'] as List;
        String? downloadUrl;
        int? apkSize;

        for (final asset in assets) {
          final name = asset['name'] as String;
          if (name.endsWith('.apk') && !name.toLowerCase().contains('family')) {
            downloadUrl = asset['browser_download_url'] as String;
            apkSize = asset['size'] as int?;
            break;
          }
        }

        return UpdateAvailable(
          version: latestVersion,
          downloadUrl: downloadUrl ?? release['html_url'],
          releasePageUrl: release['html_url'],
          releaseNotes: release['body'] as String?,
          apkSize: apkSize,
        );
      }

      // Only check the first non-prerelease (latest)
      break;
    }

    return NoUpdate();
  }

  /// Compare semantic versions. Returns true if latest > current.
  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  /// Download APK with progress tracking
  Future<void> downloadUpdate(String url, String version) async {
    _downloadState = DownloadState.downloading;
    _downloadProgress = 0;
    _downloadError = null;
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      // Get download directory
      final dir = await getApplicationCacheDirectory();
      final apkDir = Directory('${dir.path}/apk_updates');
      if (!await apkDir.exists()) {
        await apkDir.create(recursive: true);
      }

      // Clean up old APKs
      await _deleteOldApks(apkDir);

      final filePath = '${apkDir.path}/TaskOrbit-$version.apk';

      await _dio.download(
        url,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress = ((received / total) * 100).toInt();
            notifyListeners();
          }
        },
        options: Options(
          headers: {'User-Agent': 'TaskOrbit-Flutter'},
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      final file = File(filePath);
      if (await file.exists() && await file.length() > 0) {
        _downloadedFilePath = filePath;
        _downloadState = DownloadState.completed;
      } else {
        _downloadState = DownloadState.failed;
        _downloadError = 'Downloaded file is empty or missing';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _downloadState = DownloadState.failed;
        _downloadError = 'Download cancelled';
      } else {
        _downloadState = DownloadState.failed;
        _downloadError = e.message ?? 'Download failed';
      }
    } catch (e) {
      _downloadState = DownloadState.failed;
      _downloadError = e.toString();
    }

    notifyListeners();
  }

  /// Cancel an in-progress download
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
    _downloadState = DownloadState.idle;
    _downloadProgress = 0;
    notifyListeners();
  }

  /// Install downloaded APK
  Future<void> installUpdate() async {
    if (_downloadedFilePath == null) return;

    try {
      final result = await OpenFilex.open(_downloadedFilePath!);
      if (result.type != ResultType.done) {
        debugPrint('Failed to open APK: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
    }
  }

  /// Open release page in browser
  Future<void> openReleasePage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open GitHub repository
  Future<void> openGitHubRepo() async {
    final uri = Uri.parse('https://github.com/$_githubRepo');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Skip this version
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, version);
    _updateResult = NoUpdate();
    notifyListeners();
  }

  /// Check if version was skipped
  Future<bool> isVersionSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skippedVersionKey) == version;
  }

  /// Delete old APK files
  Future<void> _deleteOldApks(Directory apkDir) async {
    try {
      if (await apkDir.exists()) {
        await for (final file in apkDir.list()) {
          if (file is File && file.path.endsWith('.apk')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting old APKs: $e');
    }
  }

  /// Check if APK exists for a specific version
  Future<bool> hasDownloadedApk(String version) async {
    try {
      final dir = await getApplicationCacheDirectory();
      final file = File('${dir.path}/apk_updates/TaskOrbit-$version.apk');
      return await file.exists() && await file.length() > 0;
    } catch (e) {
      return false;
    }
  }

  /// Format file size for display
  String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Reset download state
  void resetDownloadState() {
    _downloadState = DownloadState.idle;
    _downloadProgress = 0;
    _downloadError = null;
    _downloadedFilePath = null;
    notifyListeners();
  }
}
