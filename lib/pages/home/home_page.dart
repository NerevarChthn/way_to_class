import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:way_to_class/pages/graph_view_page.dart' show GraphViewScreen;
import 'package:way_to_class/pages/home/components/developer_panel.dart';
import 'package:way_to_class/pages/home/components/nav_bar.dart';
import 'package:way_to_class/pages/home/components/quick_access_panel.dart';
import 'package:way_to_class/pages/home/components/route_desc_panel.dart';
import 'package:way_to_class/pages/home/components/search_panel.dart';
import 'package:way_to_class/core/components/graph.dart' show Graph;
import 'package:way_to_class/pages/prof_page.dart';
import 'package:way_to_class/service/graph_service.dart';
import 'package:way_to_class/theme/manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GraphService _graphService = GraphService();
  late final Future<Graph> _graphFuture;
  String resultText = 'Wegbeschreibung erscheint hier';
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // State-Variablen für die Werte der Eingabefelder
  String _startValue = '';
  String _zielValue = '';

  @override
  void initState() {
    super.initState();
    _graphFuture = _loadGraph();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Graph> _loadGraph() async {
    return _graphService.loadGraph('assets/haus_b/haus_b_f1.json');
  }

  // Wegfindungs-Methoden
  Future<void> _findPath() async {
    try {
      final stopwatch = Stopwatch()..start();

      final String startId = _getStartNodeId();
      final String targetId = _getTargetNodeId();
      await _findeWeg(startId, targetId);

      final double totalTime = stopwatch.elapsedMicroseconds / 1000;
      log('Button-zu-Ergebnis Zeit: $totalTime ms');
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  Future<void> _findNearestBathroom() async {
    try {
      final Graph graph = _graphService.currentGraph!;
      final String startId = _getStartNodeId();
      final String nearestBathroomId = graph.findNearestBathroomId(startId);

      await _findeWeg(startId, nearestBathroomId);
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  Future<void> _findNearestEmergencyExit() async {
    try {
      final Graph graph = _graphService.currentGraph!;
      final String startId = _getStartNodeId();
      final String nearestExit = graph.findNearestEmergencyExitId(startId);

      await _findeWeg(startId, nearestExit);
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  String _getStartNodeId() {
    final Graph graph = _graphService.currentGraph!;
    // Hier Logik zur ID-Ermittlung
    // Beispiel (angepasst an deine vorherige Implementierung):
    return graph.getNodeIdByName(_startValue) ?? '';
  }

  String _getTargetNodeId() {
    final Graph graph = _graphService.currentGraph!;
    // Hier Logik zur ID-Ermittlung
    // Beispiel:
    return graph.getNodeIdByName(_zielValue) ?? '';
  }

  Future<void> _findeWeg(String startId, String targetId) async {
    try {
      final Graph graph = _graphService.currentGraph!;

      if (startId.isEmpty) {
        setState(() => resultText = 'Bitte wähle einen Startpunkt aus.');
        return;
      }

      if (targetId.isEmpty) {
        setState(() => resultText = 'Bitte wähle ein Ziel aus.');
        return;
      }

      log('Starte Wegfindung von $startId nach $targetId');

      final List<String> instructions = await graph.getNavigationInstructions(
        startId,
        targetId,
      );

      if (instructions.isEmpty) {
        setState(() => resultText = 'Kein Weg gefunden.');
        return;
      }

      setState(() {
        resultText = instructions.join('\n');
      });
    } catch (e) {
      log('Fehler: $e');
      setState(() => resultText = 'Fehler bei der Wegfindung: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigator'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeManager.isDarkMode ? Icons.wb_sunny : Icons.dark_mode,
            ),
            onPressed: () {
              themeManager.toggleTheme();
            },
          ),
        ],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [_buildNavigationPage(), GraphViewScreen(), ProfTablePage()],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildNavigationPage() {
    final theme = Theme.of(context);

    return FutureBuilder<Graph>(
      future: _graphFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Graph wird geladen...', style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Fehler beim Laden des Graphen: ${snapshot.error}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }

        final graph = snapshot.data!;
        final List<String> nodeNames =
            graph.nodeMap.values.map((n) => n.name).toList();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.5),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Oberer Bereich: Start- und Zielauswahl
                SearchPanel(
                  nodeNames: nodeNames,
                  startValue: _startValue,
                  zielValue: _zielValue,
                  onStartChanged:
                      (value) => setState(() => _startValue = value),
                  onZielChanged: (value) => setState(() => _zielValue = value),
                  onSwap:
                      () => setState(() {
                        final tempStart = _startValue;
                        _startValue = _zielValue;
                        _zielValue = tempStart;
                      }),
                  onFindPath: _findPath,
                ),

                const SizedBox(height: 16),

                // Wegbeschreibung
                Expanded(child: RouteDescriptionPanel(resultText: resultText)),

                // Schnellzugriff-Panel
                QuickAccessPanel(
                  onBathroomPressed: _findNearestBathroom,
                  onExitPressed: _findNearestEmergencyExit,
                  onCanteenPressed: () => log('Mensa'),
                ),

                const SizedBox(height: 16),

                // Entwickleroptionen in einem expandierbaren Panel
                DeveloperPanel(graph: graph),
              ],
            ),
          ),
        );
      },
    );
  }
}
