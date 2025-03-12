import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:way_to_class/core/utils/injection.dart';
import 'package:way_to_class/pages/home/home_page.dart';
import 'package:way_to_class/service/security/security_manager.dart';
import 'package:way_to_class/theme/manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityManager.initialize();

  // Dependency Injection
  await setupDependencies();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: ToastificationWrapper(child: const CampusNavigator()),
    ),
  );
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
