/// Zentrale Sammlung der Metadaten-Schlüssel für Routen-Segmente
///
/// Diese Klasse enthält alle Schlüssel, die für Segment-Metadaten verwendet werden,
/// um Konsistenz zu gewährleisten und einfache Anpassungen zu ermöglichen.
class MetadataKeys {
  // Allgemeine Metadaten
  static const String direction = 'direction';
  static const String distance = 'distance';
  static const String currentName = 'currentName';
  static const String building = 'building';
  static const String floor = 'floor';
  static const String outside = 'outside';

  // Landmarks
  static const String landmark = 'landmark';
  static const String landmarkType = 'landmarkType';

  // Ursprungs- und Ziel-Segmente
  static const String originName = 'originName';
  static const String side = 'side';

  // Türen
  static const String doorCount = 'doorCount';
  static const String name = 'name';
  static const String autoOpen = 'autoOpen';
  static const String locked = 'locked';

  // Treppen und Aufzüge
  static const String floorChange = 'floorChange';
  static const String targetFloor = 'targetFloor';
  static const String startFloor = 'startFloor';

  // Barrierefreiheit
  static const String accessible = 'accessible';

  // Notausgänge
  static const String emergency = 'emergency';

  // Richtungsangaben
  static const String straightDirection = 'geradeaus';
  static const String slightLeftDirection = 'leicht links';
  static const String leftDirection = 'links';
  static const String leftKeepDirection = 'links halten';
  static const String slightRightDirection = 'leicht rechts';
  static const String rightDirection = 'rechts';
  static const String rightKeepDirection = 'rechts halten';

  // Richtungen für Treppen/Aufzüge
  static const String upDirection = 'hoch';
  static const String downDirection = 'runter';

  // Seiten
  static const String leftSide = 'links';
  static const String rightSide = 'rechts';
}
