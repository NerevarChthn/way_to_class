import 'package:flutter/material.dart';
import 'package:way_to_class/screens/map_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: MapScreen());
  }
}
