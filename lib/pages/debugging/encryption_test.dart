import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:way_to_class/core/models/route_segments.dart';
import 'package:way_to_class/service/campus_graph_service.dart';
import 'package:way_to_class/service/security/security_manager.dart';

class EncryptionTestScreen extends StatefulWidget {
  final CampusGraphService graphService;

  const EncryptionTestScreen({super.key, required this.graphService});

  @override
  State<EncryptionTestScreen> createState() => _EncryptionTestScreenState();
}

class _EncryptionTestScreenState extends State<EncryptionTestScreen> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String _originalData = '';
  String _encryptedData = '';
  String _decryptedData = '';
  Map<String, dynamic>? _cacheStatistics;
  String? _selectedCacheKey;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _loadCacheStatistics();
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCacheStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await widget.graphService.getCacheStatistics();

      setState(() {
        _isLoading = false;
        _cacheStatistics = stats;

        // If there are cache entries, select the first one by default
        final entries = stats['entries'] as List?;
        if (entries != null && entries.isNotEmpty) {
          _selectedCacheKey = entries[0]['key'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Cache-Statistiken: $e';
      });
    }
  }

  // Create dummy route segments for testing when cache is empty
  List<RouteSegment> _createDummyRouteSegments() {
    return [
      RouteSegment(
        type: SegmentType.origin,
        nodes: ['A001', 'F001'],
        metadata: {
          'startName': 'Eingang',
          'distance': 5.0,
          'direction': 'geradeaus',
        },
      ),
      RouteSegment(
        type: SegmentType.hallway,
        nodes: ['F001', 'F002', 'F003'],
        metadata: {'distance': 15.5, 'direction': 'rechts', 'floor': 1},
      ),
      RouteSegment(
        type: SegmentType.stairs,
        nodes: ['F003', 'F103'],
        metadata: {'distance': 8.0, 'direction': 'hoch', 'floors': 1},
      ),
      RouteSegment(
        type: SegmentType.destination,
        nodes: ['F103', 'R102'],
        metadata: {'targetName': 'Hörsaal 102', 'distance': 3.0},
      ),
    ];
  }

  Future<void> _runEncryptionTest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
      _originalData = '';
      _encryptedData = '';
      _decryptedData = '';
    });

    try {
      // Testing different scenarios based on cache availability
      if (_selectedCacheKey != null) {
        // Test with existing cache entry
        await _testExistingCacheEntry();
      } else {
        // Test with dummy data if cache is empty
        await _testWithDummyData();
      }

      // Check if encryption/decryption was successful
      setState(() {
        _isLoading = false;
        _isSuccess =
            _originalData.isNotEmpty && _originalData == _decryptedData;
      });

      // Show success message for a few seconds
      if (_isSuccess) {
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Fehler bei der Verschlüsselungsprüfung: ${e.toString()}';
      });
    }
  }

  Future<void> _testExistingCacheEntry() async {
    // Find the selected cache entry
    final entries = _cacheStatistics!['entries'] as List;
    final entry = entries.firstWhere(
      (e) => e['key'] == _selectedCacheKey,
      orElse: () => throw Exception('Cache-Eintrag nicht gefunden'),
    );

    // Execute the actual encryption test
    await _executeEncryptionTest(entry['preview']);
  }

  Future<void> _testWithDummyData() async {
    // Create dummy route segments
    final dummySegments = _createDummyRouteSegments();

    // Convert to JSON string
    final segmentMaps =
        dummySegments.map((segment) => segment.toJson()).toList();
    final jsonString = jsonEncode(segmentMaps);

    // Execute the encryption test
    await _executeEncryptionTest(jsonString);
  }

  Future<void> _executeEncryptionTest(String originalText) async {
    // Store original data
    _originalData = originalText;

    // Simulate small delay for UI feedback
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Encrypt the data
      _encryptedData = SecurityManager.encryptData(_originalData);

      // Decrypt the data
      _decryptedData = SecurityManager.decryptData(_encryptedData);
    } catch (e) {
      throw Exception('Fehler bei der Ver-/Entschlüsselung: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(theme),
              const SizedBox(height: 24),
              _buildCacheEntrySelector(theme),
              const SizedBox(height: 16),
              _buildTestButton(theme),
              if (_isSuccess) _buildSuccessBanner(theme),
              if (_errorMessage != null) _buildErrorBanner(theme),
              const SizedBox(height: 24),
              _buildResultCards(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Cache-Verschlüsselungstest',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dieser Test überprüft die Funktionalität der Cache-Verschlüsselung. '
              'Ein vorhandener Cache-Eintrag oder Testdaten werden entschlüsselt und wieder verschlüsselt, '
              'um die korrekte Funktion der Sicherheitsmechanismen zu verifizieren.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheEntrySelector(ThemeData theme) {
    if (_isLoading && _cacheStatistics == null) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cache-Statistiken werden geladen...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final cacheEntries = _cacheStatistics?['entries'] as List? ?? [];

    if (cacheEntries.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cache-Daten',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Keine Cache-Einträge verfügbar. Der Test wird mit Beispieldaten durchgeführt.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache-Eintrag auswählen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCacheKey,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Cache-Eintrag auswählen',
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items:
                  cacheEntries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry['key'],
                      child: Text(
                        'Route: ${entry['key']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCacheKey = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _runEncryptionTest,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon:
            _isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
                : const Icon(Icons.enhanced_encryption),
        label: Text(
          _isLoading ? 'Wird verarbeitet...' : 'Verschlüsselungstest starten',
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verschlüsselungstest erfolgreich! Original- und entschlüsselter Text stimmen überein.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCards(ThemeData theme) {
    if (_originalData.isEmpty &&
        _encryptedData.isEmpty &&
        _decryptedData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Starte den Test, um Ergebnisse zu sehen.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ergebnisse',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildResultCard(
          theme,
          title: 'Original-Daten',
          content: _originalData,
          icon: Icons.data_object,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _buildResultCard(
          theme,
          title: 'Verschlüsselte Daten',
          content: _encryptedData,
          icon: Icons.lock,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        _buildResultCard(
          theme,
          title: 'Entschlüsselte Daten',
          content: _decryptedData,
          icon: Icons.lock_open,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildResultCard(
    ThemeData theme, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
