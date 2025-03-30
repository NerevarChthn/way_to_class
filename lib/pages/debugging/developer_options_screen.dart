import 'package:flutter/material.dart';
import 'package:way_to_class/pages/debugging/cache_stats.dart';
import 'package:way_to_class/pages/debugging/encryption_test.dart';
import 'package:way_to_class/pages/debugging/route_validator.dart';
import 'package:way_to_class/service/campus_graph_service.dart';

class DeveloperOptionsScreen extends StatefulWidget {
  final CampusGraphService graphService;

  const DeveloperOptionsScreen({super.key, required this.graphService});

  @override
  State<DeveloperOptionsScreen> createState() => _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entwickleroptionen'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Cache-Statistik'),
            Tab(icon: Icon(Icons.security), text: 'Verschlüsselung'),
            Tab(icon: Icon(Icons.route), text: 'Routenvalidierung'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CacheStatsScreen(graphService: widget.graphService),
          EncryptionTestScreen(graphService: widget.graphService),
          RouteValidatorScreen(graphService: widget.graphService),
        ],
      ),
    );
  }
}
