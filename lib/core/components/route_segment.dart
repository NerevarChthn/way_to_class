import 'dart:developer' show log;
import 'dart:math' show Random;

import 'package:way_to_class/constants/node_constants.dart';
import 'package:way_to_class/constants/segment_constants.dart';

class RouteSegment {
  final int segmentType; // Integer-basierter Typ mit Bitmasken
  final Map<String, dynamic> data;

  RouteSegment(this.segmentType, this.data);

  // Hilfsmethoden für Typprüfungen
  bool isType(int baseType) => (segmentType & segTypeMask) == baseType;
  bool isSubtype(int subtype) => (segmentType & segSubtypeMask) == subtype;
  bool hasProperty(int property) => (segmentType & property) != 0;

  // Shortcuts für häufige Typen
  bool get isCorridor => isType(segCorridor);
  bool get isTransition => isType(segTransition);
  bool get isVertical => isType(segVertical);
  bool get isDestination => isType(segDestination);

  // Shortcuts für Subtypen
  bool get isStraight => isSubtype(segStraight);
  bool get isTurn => isSubtype(segTurn);
  bool get isExit => isSubtype(segExit);
  bool get isEntry => isSubtype(segEntry);
  bool get isDoorPass => isSubtype(segDoor);

  // Shortcuts für Eigenschaften
  bool get isFirstSegment => hasProperty(segPropFirst);
  bool get hasLandmark => hasProperty(segPropLandmark);
  bool get hasFollowing => hasProperty(segPropFollowing);
  bool get isShort => hasProperty(segPropShort);
  bool get isAccessible => hasProperty(segPropAccessible);

  // JSON-Konvertierung für Caching
  Map<String, dynamic> toJson() => {'type': segmentType, 'data': data};

  // Abwärtskompatible Konstruktorfunktion für migrierte Daten
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('type')) {
      return RouteSegment(
        json['type'] as int,
        Map<String, dynamic>.from(json['data'] as Map),
      );
    }
    // Fallback
    return RouteSegment(
      segCorridorStraight,
      Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  // Diese Methode in RouteSegment-Klasse einfügen
  String generateTextWithErrorHandling() {
    try {
      return generateText();
    } catch (e, stacktrace) {
      log(
        'Fehler in generateText() für Segment-Typ: ${segmentType.toRadixString(16)}',
      );
      log('Daten: $data');
      log('Fehler: $e');
      log('Stacktrace: $stacktrace');
      return 'Fehler in der Textgenerierung';
    }
  }

  // Text-Generierung mit Bitmasken
  String generateText() {
    // Basistyp mit Bitmasken bestimmen
    if ((segmentType & segTypeMask) == segCorridor) {
      return _generateCorridorText();
    } else if ((segmentType & segTypeMask) == segTransition) {
      return _generateTransitionText();
    } else if ((segmentType & segTypeMask) == segVertical) {
      return _generateVerticalText();
    } else if ((segmentType & segTypeMask) == segDestination) {
      return _generateDestinationText();
    }

    // Fallback
    return 'Unbekannte Anweisung';
  }

  String _generateCorridorText() {
    // Prüfe auf spezifischen Unteryp
    if ((segmentType & segSubtypeMask) == segStraight) {
      // corridorStraight Segment
      final steps = data['steps'] as int? ?? 0;
      final bool isFirstSegment = data['isFirstSegment'] as bool? ?? false;
      final String? destinationDesc = data['destinationDesc']?.toString();

      // Verschiedene Varianten für geradeaus gehen
      final List<String> variants =
          isFirstSegment
              ? [
                'Gehe etwa $steps Schritte geradeaus durch den Flur${destinationDesc != null ? " bis $destinationDesc" : ""}.',
                'Folge dem Flur für ungefähr $steps Schritte${destinationDesc != null ? " bis $destinationDesc" : ""}.',
                'Laufe $steps Schritte den Gang entlang${destinationDesc != null ? " bis $destinationDesc" : ""}.',
              ]
              : [
                'Gehe etwa $steps Schritte geradeaus${destinationDesc != null ? " bis $destinationDesc" : ""}.',
                'Folge dem Flur für weitere $steps Schritte${destinationDesc != null ? " bis $destinationDesc" : ""}.',
                'Laufe noch $steps Schritte weiter${destinationDesc != null ? " bis $destinationDesc" : ""}.',
              ];

      return _getRandomVariant(variants);
    } else if ((segmentType & segSubtypeMask) == segTurn) {
      // corridorTurn Segment
      final String? direction = data['direction']?.toString();
      if (direction == null) return 'Biege ab.'; // Fallback

      final int steps = data['steps'] as int? ?? 0;
      final String? landmarkText = data['landmarkText']?.toString();
      final bool hasFollowingTurn = data['hasFollowingTurn'] as bool? ?? false;
      final String? nextDirection = data['nextDirection']?.toString();

      if (hasFollowingTurn && nextDirection != null) {
        return 'Biege $direction ab und direkt danach wieder $nextDirection ab.';
      }

      if (steps > 3) {
        final bool isFirstSegment = data['isFirstSegment'] as bool? ?? false;
        final String stepsText = 'etwa $steps';

        if (isFirstSegment) {
          final List<String> variants = [
            'Gehe $stepsText Schritte geradeaus durch den Flur und biege dann${landmarkText != null ? " $landmarkText" : ""} $direction ab.',
            'Folge dem Flur für $stepsText Schritte und biege dann${landmarkText != null ? " $landmarkText" : ""} $direction ab.',
            'Laufe $stepsText Schritte geradeaus und biege dann${landmarkText != null ? " $landmarkText" : ""} $direction ab.',
          ];
          return _getRandomVariant(variants);
        } else {
          final List<String> variants = [
            'Gehe $stepsText Schritte weiter und biege dann${landmarkText != null ? " $landmarkText" : ""} $direction ab.',
            'Setze deinen Weg für $stepsText Schritte fort und biege dann${landmarkText != null ? " $landmarkText" : ""} $direction ab.',
            'Folge dem Flur für weitere $stepsText Schritte und biege dann${landmarkText != null ? " $landmarkText" : ""} $direction ab.',
          ];
          return _getRandomVariant(variants);
        }
      } else {
        return 'Biege $direction ab.';
      }
    }

    return 'Folge dem Flur.'; // Generischer Text als Fallback
  }

  String _generateTransitionText() {
    // Prüfe mit Bitmasken auf Subtyp
    if ((segmentType & segSubtypeMask) == segExit) {
      // roomExit oder facilityExit
      if ((segmentType & segFacility) != 0) {
        // facilityExit (nonRoomExit)
        final String sourceType =
            (data['sourceType'] as int?)?.toString() ?? '';
        final String targetDesc = data['targetDesc']?.toString() ?? '';
        return 'Verlasse $sourceType und gehe zu $targetDesc.';
      } else {
        // roomExit
        final String? roomId = data['roomId']?.toString();
        if (roomId == null) {
          switch (data['sourceType'] as int?) {
            case typeElevator:
              return 'Verlasse den Fahrstuhl.';
            case typeStaircase:
              return 'Verlasse die Treppe.';
            case typeToilet:
              return 'Verlasse die Toilette.';
            default:
              return 'Verlasse den Raum.';
          }
        } // Fallback

        final String? direction = data['direction']?.toString();

        if (direction == 'geradeaus') {
          final List<String> variants = [
            'Verlasse Raum $roomId und gehe geradeaus in den Flur.',
            'Gehe aus Raum $roomId geradeaus in den Flur.',
            'Vom Raum $roomId aus gehe geradeaus in den Flur.',
          ];
          return _getRandomVariant(variants);
        } else if (direction == 'links') {
          return 'Verlasse Raum $roomId und biege links in den Flur ein.';
        } else if (direction == 'rechts') {
          return 'Verlasse Raum $roomId und biege rechts in den Flur ein.';
        } else {
          return 'Verlasse Raum $roomId und gehe in den Flur.';
        }
      }
    } else if ((segmentType & segSubtypeMask) == segEntry) {
      // roomEntry oder facilityEntry
      if ((segmentType & segFacility) != 0) {
        // facilityEntry (nonRoomEntry)
        final int? targetType = data['targetType'] as int?;
        final String targetDesc = data['targetDesc']?.toString() ?? '';

        if (targetType != null && (targetType & typeMask) == typeToilet) {
          return 'Gehe zur $targetDesc.';
        } else {
          return 'Gehe zu $targetDesc.';
        }
      } else {
        // roomEntry
        final String? nodeId = data['nodeId']?.toString();
        final String? buildingName = data['buildingName']?.toString();
        final int? floorNumber = data['floorNumber'] as int?;
        final String? nodeName = data['nodeName']?.toString();

        if (nodeId == null) return 'Du hast den Raum erreicht.'; // Fallback

        if (buildingName != null && floorNumber != null && nodeName != null) {
          return '$nodeName befindet sich in $buildingName in Etage $floorNumber.\n';
        } else {
          return 'Du hast Raum $nodeId erreicht.';
        }
      }
    } else if ((segmentType & segSubtypeMask) == segDoor) {
      // doorPass
      final int? targetType = data['targetType'] as int?;
      final String? targetId = data['targetId']?.toString();
      final String targetDesc = data['targetDesc']?.toString() ?? '';

      if (targetType != null) {
        if ((targetType & typeMask) == typeRoom) {
          return 'Gehe durch die Tür in Raum ${targetId ?? ""}.';
        } else if ((targetType & typeMask) == typeCorridor) {
          return 'Gehe durch die Tür in den Flur.';
        }
      }
      return 'Gehe durch die Tür zu $targetDesc.';
    }

    return 'Wechsle den Raum.'; // Generischer Text als Fallback
  }

  String _generateVerticalText() {
    // Prüfe auf Richtung und Zugänglichkeit
    final bool isUp = (segmentType & segSubtypeMask) == segUp;
    final bool isAccessible = hasProperty(segPropAccessible);
    final int floors = data['floors'] as int? ?? 1;

    final String direction = isUp ? 'nach oben' : 'nach unten';
    final String floorText = floors == 1 ? 'eine Etage' : '$floors Etagen';

    if (isAccessible) {
      // Fahrstuhl
      return 'Fahre mit dem Fahrstuhl $floorText $direction.';
    } else {
      // Treppe
      final List<String> variants = [
        'Gehe die Treppe $floorText $direction.',
        'Steige die Treppe $floorText $direction.',
        'Nehme die Treppe $floorText $direction.',
      ];
      return _getRandomVariant(variants);
    }
  }

  String _generateDestinationText() {
    final String? nodeId = data['nodeId']?.toString();
    if (nodeId == null) return 'Du hast dein Ziel erreicht.'; // Fallback

    final String? nodeType = data['nodeType']?.toString();
    final String? position = data['position']?.toString();

    if (position == null) return 'Du hast $nodeId erreicht.'; // Fallback

    if (nodeType == 'room') {
      return 'Der Raum $nodeId befindet sich $position.';
    } else if (nodeType == 'staircase') {
      return 'Die Treppe befindet sich $position.';
    } else if (nodeType == 'elevator') {
      return 'Der Fahrstuhl befindet sich $position.';
    } else if (nodeType == 'emergency') {
      return 'Der Notausgang befindet sich $position.';
    } else {
      return 'Du hast $nodeId erreicht, schau $position.';
    }
  }

  // Kombiniert Zeit und Zufall für bessere Streuung
  static final _random = Random();
  static int _lastTimestamp = 0;

  String _getRandomVariant(List<String> variants) {
    final now = DateTime.now().microsecondsSinceEpoch;
    // Falls gleicher Timestamp, nutze einen echten Zufallswert
    if (now == _lastTimestamp) {
      return variants[_random.nextInt(variants.length)];
    }
    // Sonst nutze den Timestamp, aber speichere ihn für den nächsten Vergleich
    _lastTimestamp = now;
    return variants[now % variants.length];
  }
}
