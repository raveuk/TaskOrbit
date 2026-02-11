import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/update_provider.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateAvailable update;

  const UpdateDialog({super.key, required this.update});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildContent(context),
            _buildActions(context),
          ],
        ),
      ).animate().scale(
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${update.version}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final updateProvider = context.watch<UpdateProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (update.apkSize != null) ...[
            Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Download size: ${updateProvider.formatFileSize(update.apkSize)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (update.releaseNotes != null && update.releaseNotes!.isNotEmpty) ...[
            Text(
              'What\'s New',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  _formatReleaseNotes(update.releaseNotes!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ] else ...[
            Text(
              'A new version of TaskOrbit is available!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          // Download progress
          if (updateProvider.downloadState == DownloadState.downloading) ...[
            Column(
              children: [
                LinearProgressIndicator(
                  value: updateProvider.downloadProgress / 100,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloading... ${updateProvider.downloadProgress}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (updateProvider.downloadState == DownloadState.failed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      updateProvider.downloadError ?? 'Download failed',
                      style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (updateProvider.downloadState == DownloadState.completed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download complete! Tap Install to continue.',
                      style: TextStyle(color: AppTheme.successColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final updateProvider = context.watch<UpdateProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Skip / Later button
          if (updateProvider.downloadState == DownloadState.idle ||
              updateProvider.downloadState == DownloadState.failed) ...[
            TextButton(
              onPressed: () {
                updateProvider.skipVersion(update.version);
                Navigator.pop(context);
              },
              child: const Text('Later'),
            ),
            const Spacer(),
          ],
          // Cancel download button
          if (updateProvider.downloadState == DownloadState.downloading) ...[
            TextButton(
              onPressed: () {
                updateProvider.cancelDownload();
              },
              child: const Text('Cancel'),
            ),
            const Spacer(),
          ],
          // Completed state - Install button
          if (updateProvider.downloadState == DownloadState.completed) ...[
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                updateProvider.installUpdate();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.install_mobile, size: 18),
              label: const Text('Install'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          // Idle / Failed - Download or Browser buttons
          if (updateProvider.downloadState == DownloadState.idle ||
              updateProvider.downloadState == DownloadState.failed) ...[
            OutlinedButton.icon(
              onPressed: () {
                updateProvider.openReleasePage(update.releasePageUrl);
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Browser'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                updateProvider.downloadUpdate(update.downloadUrl, update.version);
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReleaseNotes(String notes) {
    // Clean up markdown formatting for simple display
    return notes
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'^-\s*', multiLine: true), '• ')
        .trim();
  }
}

/// Helper function to show the update dialog
Future<void> showUpdateDialog(BuildContext context, UpdateAvailable update) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => UpdateDialog(update: update),
  );
}
