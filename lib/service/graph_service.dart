import 'dart:developer' show log;

import 'package:way_to_class/core/components/graph.dart' show Graph;

class GraphService {
  // Singleton-Pattern
  static final GraphService _instance = GraphService._internal();
  factory GraphService() => _instance;
  GraphService._internal();

  Graph? _currentGraph;
  bool _isLoading = false;

  /// Lädt den Graphen asynchron
  Future<Graph> loadGraph(String assetPath) async {
    if (_currentGraph != null) return _currentGraph!;
    if (_isLoading) {
      // Warte bis der Graph geladen ist
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _currentGraph!;
    }

    _isLoading = true;
    try {
      _currentGraph = await Graph.load(assetPath);
      return _currentGraph!;
    } catch (e) {
      log('Fehler beim Laden der Graphdaten: $e');
      // Ein leerer Graph als Fallback
      _currentGraph = Graph({});
      return _currentGraph!;
    } finally {
      _isLoading = false;
    }
  }

  /// Gibt den aktuell geladenen Graphen zurück oder null wenn noch nicht geladen
  Graph? get currentGraph => _currentGraph;

  /// Prüft ob der Graph bereits geladen wurde
  bool get isGraphLoaded => _currentGraph != null;
}
