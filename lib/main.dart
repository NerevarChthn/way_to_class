import 'package:flutter/material.dart';
import 'package:way_to_class/pages/home/home_page.dart';
import 'package:way_to_class/service/security/security_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityManager.initialize();

  runApp(const CampusNavigator());
}

class CampusNavigator extends StatelessWidget {
  const CampusNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Way2Class',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
