import 'package:way_to_class/constants/types.dart';

/// Segment types for route description
enum SegmentType {
  hallway, // Flur
  stairs, // Treppe
  elevator, // Aufzug
  room, // Raum
  exit, // Ausgang
  toilet, // Toilette
  origin, // Startpunkt
  destination, // Zielpunkt
  door, // Tür
  unknown, // Unklassifiziert
}

/// Represents a semantic segment of a route
class RouteSegment {
  /// Segment type
  final SegmentType type;

  /// List of node IDs in this segment
  final List<NodeId> nodes;

  /// Metadata for description generation
  final Map<String, dynamic> metadata;

  /// Constructor
  RouteSegment({
    required this.type,
    required this.nodes,
    required this.metadata,
  });

  /// Creates a new segment from a JSON representation
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    List<NodeId> nodeIds = [];
    if (json['nodes'] != null) {
      nodeIds = (json['nodes'] as List).map((e) => e as String).toList();
    }

    return RouteSegment(
      type: SegmentType.values[json['type']],
      nodes: nodeIds,
      metadata: json['metadata'],
    );
  }

  /// Creates a compact JSON representation for persistence
  /// Only stores metadata and type, since node IDs are not needed for text generation
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'metadata': metadata,
      'nodes': nodes, // Added nodes to serialization for better debugging
    };
  }

  /// Getter for node IDs for backward compatibility
  List<NodeId> get nodeIds => nodes;

  /// Provides a readable string representation for debugging
  @override
  String toString() {
    // Get segment type name
    final String typeName = type.toString().split('.').last;

    // Format nodes info
    final String nodesInfo =
        '${nodes.length} ${nodes.length == 1 ? 'node' : 'nodes'}';

    // Format primary info
    final String primaryInfo = 'RouteSegment($typeName, $nodesInfo)';

    // Format all metadata alphabetically for consistent output
    final List<String> metadataStrings = [];

    // Sort keys alphabetically for consistent output
    final List<String> sortedKeys = metadata.keys.toList()..sort();

    for (String key in sortedKeys) {
      var value = metadata[key];
      String valueStr;

      // Format values consistently based on their type
      if (value is double) {
        valueStr = value.toStringAsFixed(1);
      } else if (value is bool || value is int) {
        valueStr = value.toString();
      } else if (value is String) {
        valueStr = '"$value"'; // Strings in quotes
      } else {
        valueStr = value?.toString() ?? 'null';
      }

      metadataStrings.add('$key: $valueStr');
    }

    // Return the formatted string
    if (metadataStrings.isNotEmpty) {
      return '$primaryInfo\n  $nodes \n${metadataStrings.join('\n  ')}\n';
    } else {
      return primaryInfo;
    }
  }
}
