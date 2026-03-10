import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/gpa_provider.dart';
import 'screens/dashboard_screen.dart';

import 'package:workmanager/workmanager.dart';

const String syncTaskName = "com.softcare.calculator.syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final provider = GpaProvider();
    await provider.loadData();
    if (provider.isDriveConnected) {
      await provider.syncWithDrive();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager().registerPeriodicTask(
    "1",
    syncTaskName,
    frequency: const Duration(hours: 24),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  final gpaProvider = GpaProvider();
  await gpaProvider.loadData();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: gpaProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPA Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
