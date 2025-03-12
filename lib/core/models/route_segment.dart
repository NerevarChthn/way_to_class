import 'dart:developer' show log;

import 'package:way_to_class/constants/node_constants.dart';
import 'package:way_to_class/constants/segment_constants.dart';
import 'package:way_to_class/constants/template_constants.dart';
import 'package:way_to_class/core/utils/transition_manager.dart';
import 'package:way_to_class/core/utils/injection.dart';

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

  // Ersetze die generateText()-Methode mit dieser vollständigen Implementierung:

  String generateText() {
    // TransitionTemplateManager aus Dependency Injection holen
    final templateManager = getIt<TransitionTemplateManager>();

    // Basistyp mit Bitmasken bestimmen
    if ((segmentType & segTypeMask) == segCorridor) {
      if ((segmentType & segSubtypeMask) == segStraight) {
        final steps = data['steps'] as int? ?? 0;
        final bool isFirstSegment = data['isFirstSegment'] as bool? ?? false;
        final String? destinationDesc = data['destinationDesc']?.toString();
        final String? landmarkText = data['landmarkText']?.toString();

        return templateManager.getCorridorTemplate(
          isFirstSegment: isFirstSegment,
          hasLandmark: landmarkText != null,
          hasFollowingTurn: false,
          hasTurn: false,
          hasDestination: destinationDesc != null,
          steps: steps,
          landmarkText: landmarkText,
          destinationDesc: destinationDesc,
        );
      } else if ((segmentType & segSubtypeMask) == segTurn) {
        final String? direction = data['direction']?.toString();
        final int steps = data['steps'] as int? ?? 0;
        final String? landmarkText = data['landmarkText']?.toString();
        final bool hasFollowingTurn =
            data['hasFollowingTurn'] as bool? ?? false;
        final String? nextDirection = data['nextDirection']?.toString();
        final bool isFirstSegment = data['isFirstSegment'] as bool? ?? false;

        return templateManager.getCorridorTemplate(
          isFirstSegment: isFirstSegment,
          hasLandmark: landmarkText != null,
          hasFollowingTurn: hasFollowingTurn,
          hasTurn: true,
          hasDestination: false,
          steps: steps,
          landmarkText: landmarkText,
          direction: direction,
          nextDirection: nextDirection,
        );
      }
    } else if ((segmentType & segTypeMask) == segTransition) {
      // Raumübergänge
      if ((segmentType & segSubtypeMask) == segExit) {
        int context = templateExit;
        int nodeType = data['sourceType'] as int? ?? typeRoom;

        // Erzeuge die passenden Template-Kontexteinstellungen
        if ((segmentType & segFacility) != 0) {
          // facilityExit (Nicht-Raum-Exit)
          Map<String, dynamic> params = {
            'name': data['sourceDesc']?.toString() ?? "den Ort",
            'nextAction': "gehe zu ${data['targetDesc']?.toString() ?? ""}",
          };
          return templateManager
              .findBestTemplate(context, nodeType, 0)
              .apply(params);
        } else {
          // roomExit (Raum-Exit)
          int targetType = data['targetType'] as int? ?? typeCorridor;

          // Spezialfall: Raum zu Flur
          if ((targetType & typeMask) == typeCorridor) {
            context |= templateForRoom | templateForCorridor;

            Map<String, dynamic> params = {
              'name': data['roomId']?.toString() ?? "",
              'direction': data['direction']?.toString() ?? "geradeaus",
              // Zusätzlicher Parameter für Abwärtskompatibilität mit anderen Templates
              'nextAction': "gehe in den Flur",
            };

            // Debug-Log zur Fehleranalyse
            log(
              'RoomExit params: $params, context: ${context.toRadixString(16)}, nodeType: ${nodeType.toRadixString(16)}',
            );

            return templateManager
                .findBestTemplate(context, nodeType, 0)
                .apply(params);
          } else {
            // Anderer Zieltyp
            Map<String, dynamic> params = {
              'name': data['roomId']?.toString() ?? "",
              'nextAction': "gehe zu ${data['targetDesc']?.toString() ?? ""}",
            };

            return templateManager
                .findBestTemplate(context | templateForRoom, nodeType, 0)
                .apply(params);
          }
        }
      } else if ((segmentType & segSubtypeMask) == segEntry) {
        int context = templateEntry;
        int targetType = data['targetType'] as int? ?? typeRoom;

        if ((segmentType & segFacility) != 0) {
          // facilityEntry (Nicht-Raum-Entry)
          Map<String, dynamic> params = {
            'name': data['targetDesc']?.toString() ?? "dem Ort",
          };

          // Kontext für besondere Knoten anpassen
          if ((targetType & typeMask) == typeToilet) {
            context |= templateForToilet;
          } else if ((targetType & typeMask) == typeElevator) {
            context |= templateForElevator;
          } else if ((targetType & typeMask) == typeStaircase) {
            context |= templateForStairs;
          }

          return templateManager
              .findBestTemplate(context, targetType, 0)
              .apply(params);
        } else {
          // roomEntry (Raum-Entry)
          Map<String, dynamic> params = {
            'name': data['nodeId']?.toString() ?? "dem Raum",
          };

          // Falls Rauminfo vorhanden ist, verwende Info-Template statt Entry-Template
          if (data.containsKey('buildingName') &&
              data.containsKey('floorNumber')) {
            context = templateInfo;
            params['building'] = data['buildingName'];
            params['floor'] = data['floorNumber'];
            params['name'] = data['nodeName'] ?? params['name'];
          }

          return templateManager
              .findBestTemplate(context, targetType, 0)
              .apply(params);
        }
      } else if ((segmentType & segSubtypeMask) == segDoor) {
        int context = templateEntry | templateDoor;
        int targetType = data['targetType'] as int? ?? typeCorridor;

        Map<String, dynamic> params = {
          'name':
              data['targetDesc']?.toString() ??
              (data['targetId']?.toString() ?? "dem Ziel"),
        };

        // Spezifischer Kontext für Türen zu Räumen
        if ((targetType & typeMask) == typeRoom) {
          context |= templateForRoom;
        } else if ((targetType & typeMask) == typeCorridor) {
          context |= templateForCorridor;
        }

        return templateManager
            .findBestTemplate(context, targetType, 0)
            .apply(params);
      }
    } else if ((segmentType & segTypeMask) == segVertical) {
      int context = templateTravel;
      int properties = 0;

      // Richtungseigenschaft setzen
      if ((segmentType & segSubtypeMask) == segUp) {
        properties |= templateDirectionUp;
      } else {
        properties |= templateDirectionDown;
      }

      // Fahrstuhl oder Treppe
      int nodeTypeProperty =
          hasProperty(segPropAccessible)
              ? templateForElevator
              : templateForStairs;

      int floors = data['floors'] as int? ?? 1;

      Map<String, dynamic> params = {
        'floors': floors == 1 ? "eine Etage" : "$floors Etagen",
      };

      return templateManager
          .findBestTemplate(
            context | nodeTypeProperty,
            hasProperty(segPropAccessible) ? typeElevator : typeStaircase,
            properties,
          )
          .apply(params);
    } else if ((segmentType & segTypeMask) == segDestination) {
      // Zielsegment nutzen optimierten TransitionTemplateManager
      int context = templateDestination;
      int nodeType = data['nodeTypeInt'] as int? ?? typeRoom;

      Map<String, dynamic> params = {
        'name': data['nodeId']?.toString() ?? "unbekanntem Ort",
        'position': data['position']?.toString() ?? "vor dir",
        'locationType': templateManager.getArticleForNodeType(nodeType, true),
      };

      return templateManager
          .findBestTemplate(context, nodeType, 0)
          .apply(params);
    }

    // Fallback zur alten Implementierung, falls keine Übereinstimmung gefunden wird
    return 'funkt nich';
  }
}
