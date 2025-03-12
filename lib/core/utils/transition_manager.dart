import 'package:way_to_class/constants/node_constants.dart';
import 'package:way_to_class/constants/template_constants.dart';
import 'package:way_to_class/core/utils/transition_template.dart';

enum TemplateCategory { exit, entry, travel, direction, destination, info }

// Optimierter TransitionTemplateManager

class TransitionTemplateManager {
  final List<TransitionTemplate> _templates = [];

  TransitionTemplateManager() {
    _initializeTemplates();
  }

  void _initializeTemplates() {
    // Bewegungstemplates für Korridore
    _addTemplate(
      templateMovement |
          templateStraight |
          templateWithDistance |
          templateForCorridor,
      'Gehe etwa {steps} Schritte {direction}durch den Flur{landmark}{destination}.',
      ['steps'],
    );

    _addTemplate(
      templateMovement |
          templateStraight |
          templateWithDistance |
          templateForCorridor |
          templateIsFirst,
      'Gehe etwa {steps} Schritte geradeaus durch den Flur{landmark}{destination}.',
      ['steps'],
    );

    _addTemplate(
      templateMovement | templateTurn,
      'Biege {direction} ab{nextTurn}.',
      ['direction'],
    );

    _addTemplate(
      templateMovement |
          templateTurn |
          templateWithDistance |
          templateWithLandmark,
      'Gehe {steps} Schritte {firstSegment}und biege dann{landmark} {direction} ab.',
      ['steps', 'direction'],
    );

    // Raum verlassen
    _addTemplate(
      templateExit | templateForRoom,
      'Verlasse {name} und {nextAction}.',
      ['name', 'nextAction'],
    );

    _addTemplate(
      templateExit | templateForRoom | templateForCorridor,
      'Verlasse {name} und gehe {direction} in den Flur.',
      ['name', 'direction'], // Beide Parameter sind erforderlich
    );

    _addTemplate(
      templateExit | templateForRoom | templateForCorridor,
      'Verlasse {name} und gehe in den Flur.',
      ['name'],
    );

    // Spezielle Exit-Templates für Aufzug und Treppe
    _addTemplate(
      templateExit | templateForElevator,
      'Verlasse den Aufzug und {nextAction}.',
      ['nextAction'],
    );

    _addTemplate(
      templateExit | templateForStairs,
      'Verlasse die Treppe und {nextAction}.',
      ['nextAction'],
    );

    _addTemplate(
      templateExit | templateForElevator | templateForCorridor,
      'Verlasse den Aufzug und gehe in den Flur.',
    );

    _addTemplate(
      templateExit | templateForStairs | templateForCorridor,
      'Verlasse die Treppe und gehe in den Flur.',
    );

    // Eingangs-Templates
    _addTemplate(templateEntry | templateForRoom, 'Gehe in {name}.', ['name']);

    _addTemplate(templateEntry | templateForToilet, 'Gehe zur {name}.', [
      'name',
    ]);

    _addTemplate(templateEntry | templateForElevator, 'Gehe zum {name}.', [
      'name',
    ]);

    _addTemplate(templateEntry | templateForStairs, 'Gehe zur {name}.', [
      'name',
    ]);

    // Tür-Templates
    _addTemplate(
      templateEntry | templateDoor | templateForRoom,
      'Gehe durch die Tür in {name}.',
      ['name'],
    );

    _addTemplate(
      templateEntry | templateDoor | templateForCorridor,
      'Gehe durch die Tür in den Flur.',
    );

    _addTemplate(
      templateEntry | templateDoor,
      'Gehe durch die Tür zu {name}.',
      ['name'],
    );

    // Vertikale Bewegung (Treppe/Aufzug)
    _addTemplate(
      templateTravel | templateForStairs | templateDirectionUp,
      'Gehe die Treppe {floors} nach oben.',
      ['floors'],
    );

    _addTemplate(
      templateTravel | templateForStairs | templateDirectionDown,
      'Gehe die Treppe {floors} nach unten.',
      ['floors'],
    );

    _addTemplate(
      templateTravel | templateForElevator | templateDirectionUp,
      'Fahre mit dem Aufzug {floors} nach oben.',
      ['floors'],
    );

    _addTemplate(
      templateTravel | templateForElevator | templateDirectionDown,
      'Fahre mit dem Aufzug {floors} nach unten.',
      ['floors'],
    );

    // Ziel-Templates für verschiedene Raumtypen
    _addTemplate(
      templateDestination | templateForRoom,
      '{locationType} {name} befindet sich {position}.',
      ['name', 'position', 'locationType'],
    );

    _addTemplate(
      templateDestination | templateForStairs,
      '{locationType} befindet sich {position}.',
      ['position', 'locationType'],
    );

    _addTemplate(
      templateDestination | templateForElevator,
      '{locationType} befindet sich {position}.',
      ['position', 'locationType'],
    );

    _addTemplate(
      templateDestination | templateForToilet,
      '{locationType} befindet sich {position}.',
      ['position', 'locationType'],
    );

    // Info-Templates für Start-/Zielknoten
    _addTemplate(
      templateInfo | templateForRoom,
      '{name} befindet sich in {building} in Etage {floor}.',
      ['name', 'building', 'floor'],
    );
  }

  void _addTemplate(
    int type,
    String text, [
    List<String> requiredParams = const [],
  ]) {
    _templates.add(
      TransitionTemplate(
        type: type,
        template: text,
        requiredParams: requiredParams,
      ),
    );
  }

  /// Findet das am besten passende Template für einen bestimmten Kontext
  TransitionTemplate findBestTemplate(
    int context,
    int nodeType,
    int properties,
  ) {
    // Debug-Logging für besseres Verständnis
    //log('Suche Template für Context: 0x${context.toRadixString(16)}, NodeType: 0x${nodeType.toRadixString(16)}, Props: 0x${properties.toRadixString(16)}');

    final candidates =
        _templates
            .where(
              (t) => t.matchesContext(context) && t.matchesNodeType(nodeType),
            )
            .toList();

    if (candidates.isEmpty) {
      //log('WARNUNG: Kein passendes Template gefunden!');
      return TransitionTemplate(
        type: 0,
        template: 'Keine passende Vorlage gefunden.',
      );
    }

    // Verbesserter Sortieralgorithmus mit drei Kriterien:
    // 1. Anzahl der übereinstimmenden Kontextbits (höher ist besser)
    // 2. Anzahl der übereinstimmenden Eigenschaftsbits (höher ist besser)
    // 3. Bei gleicher Übereinstimmung: Template mit mehr erforderlichen Parametern bevorzugen
    candidates.sort((a, b) {
      // 1. Kontext-Bits vergleichen (Anzahl der Übereinstimmungen mit context)
      final aContextMatches = _countMatchingBits(a.type, context);
      final bContextMatches = _countMatchingBits(b.type, context);

      if (aContextMatches != bContextMatches) {
        return bContextMatches - aContextMatches; // Mehr ist besser
      }

      // 2. Properties-Bits vergleichen
      final aPropsMatches = _countMatchingBits(a.type, properties);
      final bPropsMatches = _countMatchingBits(b.type, properties);

      if (aPropsMatches != bPropsMatches) {
        return bPropsMatches - aPropsMatches; // Mehr ist besser
      }

      // 3. Bei gleicher Übereinstimmung: Template mit mehr erforderlichen Parametern bevorzugen
      return b.requiredParams.length - a.requiredParams.length;
    });

    //log('Gewähltes Template: ${candidates.first.template}');
    return candidates.first;
  }

  /// Zählt die Anzahl der übereinstimmenden Bits zwischen zwei Bitmasken
  int _countMatchingBits(int a, int b) {
    return _countSetBits(a & b);
  }

  /// Zählt die gesetzten Bits in einer Bitmaske
  int _countSetBits(int n) {
    int count = 0;
    while (n > 0) {
      count += n & 1;
      n >>= 1;
    }
    return count;
  }

  /// Generiert eine Wegbeschreibung für einen Korridor
  String getCorridorTemplate({
    required bool isFirstSegment,
    required bool hasLandmark,
    required bool hasFollowingTurn,
    required bool hasTurn,
    required bool hasDestination,
    required int steps,
    String? landmarkText,
    String? direction,
    String? nextDirection,
    String? destinationDesc,
  }) {
    // Kontext- und Eigenschaftsbitmasken erstellen
    int context = templateMovement;
    int properties = 0;

    if (hasTurn) {
      context |= templateTurn;
      if (steps > 3) properties |= templateWithDistance;
      if (hasLandmark) properties |= templateWithLandmark;
      if (hasFollowingTurn) properties |= templateWithFollowup;
    } else {
      context |= templateStraight;
      properties |= templateWithDistance;
      if (hasDestination) properties |= templateWithDestination;
    }

    if (isFirstSegment) properties |= templateIsFirst;

    // Bestes Template finden
    final template = findBestTemplate(context, typeCorridor, properties);

    // Parameter vorbereiten
    final params = <String, dynamic>{
      'steps': steps,
      'direction': direction ?? (isFirstSegment ? 'geradeaus ' : ''),
    };

    if (hasLandmark && landmarkText != null) {
      params['landmark'] = ' auf Höhe von $landmarkText';
    } else {
      params['landmark'] = '';
    }

    if (hasFollowingTurn && nextDirection != null) {
      params['nextTurn'] = ' und direkt danach wieder $nextDirection';
    } else {
      params['nextTurn'] = '';
    }

    if (hasDestination && destinationDesc != null) {
      params['destination'] = ' bis $destinationDesc';
    } else {
      params['destination'] = '';
    }

    params['firstSegment'] =
        isFirstSegment ? 'geradeaus durch den Flur ' : 'weiter ';

    return template.apply(params);
  }

  /// Erstellt eine Ziel-Beschreibung mit direkter Verwendung der Knotentyp-Bitmaske
  String getDestinationTemplateForNode(
    int nodeType,
    String nodeName,
    String position,
    bool hasReached,
  ) {
    // Kontext- und Eigenschaftsbitmasken erstellen
    int context = templateDestination;
    int properties = 0;

    String formattedName = formatNameForNodeType(nodeType, nodeName);
    Map<String, dynamic> params = {'name': formattedName, 'position': position};

    // Artikel basierend auf dem tatsächlichen Knotentyp (nicht String)
    params['locationType'] = getArticleForNodeType(nodeType, hasReached);

    // Bestes Template finden
    final template = findBestTemplate(
      context,
      nodeType, // Direkter Knotentyp als Integer
      properties,
    );

    return template.apply(params);
  }

  /// Bestimmt den deutschen Artikel direkt basierend auf dem Knotentyp als Bitmaske
  String getArticleForNodeType(int nodeType, bool capitalized) {
    switch (nodeType & typeMask) {
      case typeRoom:
        return capitalized ? 'Der Raum' : 'der Raum';
      case typeStaircase:
        return capitalized ? 'Die Treppe' : 'die Treppe';
      case typeElevator:
        return capitalized ? 'Der Aufzug' : 'der Aufzug';
      case typeToilet:
        return capitalized ? 'Die Toilette' : 'die Toilette';
      default:
        if ((nodeType & propEmergency) != 0 && (nodeType & propExit) != 0) {
          return capitalized ? 'Der Notausgang' : 'der Notausgang';
        }
        return '';
    }
  }

  /// Formatiert den Namen basierend auf dem Knotentyp als Bitmaske
  String formatNameForNodeType(int nodeType, String name) {
    if ((nodeType & typeMask) == typeRoom &&
        !name.toLowerCase().contains('raum')) {
      return 'Raum $name';
    }
    return name;
  }
}
