import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gpa_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              const Card(
                child: ListTile(
                  leading: Icon(Icons.cloud_upload_outlined),
                  title: Text('Backup to Drive'),
                  subtitle: Text(
                    'Setup OAuth keys to enable direct Drive sync. (Coming Soon)',
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
