import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:way_to_class/core/utils/injection.dart';
import 'package:way_to_class/pages/home/home_page.dart';
import 'package:way_to_class/service/campus_graph_service.dart';
import 'package:way_to_class/service/security/security_manager.dart';
import 'package:way_to_class/theme/manager.dart';

void main() async {
  await initApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const CampusNavigator(),
    ),
  );
}

Future<void> initApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await setupDependencies();

    // Zuerst SecurityManager initialisieren, da dieser für das Caching benötigt wird
    try {
      await SecurityManager.initialize();
    } catch (securityError) {
      log(
        'Fehler bei der Initialisierung des SecurityManagers: $securityError',
      );
      // App kann trotzdem weiterlaufen, Cache wird evtl. unverschlüsselt sein
    }

    // Danach den CampusGraphService initialisieren
    try {
      final campusGraphService = getIt<CampusGraphService>();
      await campusGraphService.initialize();
    } catch (graphError) {
      log('Fehler bei der Initialisierung des CampusGraphService: $graphError');
      // App kann trotzdem starten, aber evtl. ohne Cache
    }
  } catch (e) {
    log('Fehler bei der App-Initialisierung: $e');
  }
}

class CampusNavigator extends StatelessWidget {
  const CampusNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Way2Class',
      theme: ThemeManager.getLightTheme(),
      darkTheme: ThemeManager.getDarkTheme(),
      themeMode: themeManager.themeMode,
      home: const HomePage(),
    );
  }
}
