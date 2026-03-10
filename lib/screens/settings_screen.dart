import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/gpa_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<GpaProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Grading Scale',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  title: const Text('Use 5.0 Point Scale'),
                  subtitle: Text(
                    provider.is5PointScale
                        ? "A=5, B=4, C=3, D=2, E=1, F=0"
                        : "A=4, B=3, C=2, D=1, F=0",
                  ),
                  value: provider.is5PointScale,
                  onChanged: (value) {
                    provider.toggleScale(value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Google Drive Integration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.cloud_upload_outlined),
                      title: const Text('Connect to Drive'),
                      subtitle: Text(
                        provider.isDriveConnected
                            ? 'Connected'
                            : 'Backup your data to the cloud',
                      ),
                      value: provider.isDriveConnected,
                      onChanged: (value) {
                        if (value) {
                          provider.signInToDrive();
                        } else {
                          provider.signOutFromDrive();
                        }
                      },
                    ),
                    if (provider.isDriveConnected) ...[
                      const Divider(),
                      ListTile(
                        leading: provider.isSyncing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        title: const Text('Sync Now'),
                        subtitle: Text(
                          provider.lastSyncTime != null
                              ? 'Last sync: ${provider.lastSyncTime!.toString().split('.').first}'
                              : 'Never synced',
                        ),
                        onTap: provider.isSyncing
                            ? null
                            : () => provider.syncWithDrive(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Legal & Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new, size: 20),
                      onTap: () => _launchURL(
                        'https://raph-ray.blogspot.com/2023/02/gpa-calculator.html#app_privacy',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person_remove_outlined),
                      title: const Text('Delete Account / Data'),
                      subtitle: const Text('Request data deletion'),
                      trailing: const Icon(Icons.open_in_new, size: 20),
                      onTap: () => _launchURL(
                        'https://raph-ray.blogspot.com/2023/02/gpa-calculator.html#delete_account',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
