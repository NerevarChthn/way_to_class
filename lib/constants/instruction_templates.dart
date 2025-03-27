/// Sammlung von Templates für Navigationsanweisungen
class InstructionTemplates {
  // ORIGIN TEMPLATES
  static const Set<String> origin = {
    'Verlasse {initialConnector} {originName} und gehe geradeaus in den {hallSynonym}',
    'Verlasse {initialConnector} {originName} und gehe in den {hallSynonym}',
    'Starte {initialConnector} bei {originName} und begib dich in den {hallSynonym}',
    'Von {originName} aus gehst du {initialConnector} in den {hallSynonym}',
  };

  static const Set<String> originWithDirection = {
    'Verlasse {initialConnector} {originName} und biege {direction} in den {hallSynonym} ein',
    'Verlasse {initialConnector} {originName} und gehe {direction} in den {hallSynonym}',
    'Starte {initialConnector} bei {originName} und biege {direction} in den {hallSynonym} ab',
    'Von {originName} aus biegst du {initialConnector} {direction} in den {hallSynonym} ab',
  };

  // HALLWAY TEMPLATES
  static const Set<String> hallway = {
    'Gehe {middleConnector} {distance} den {hallSynonym} entlang',
    'Folge {middleConnector} dem {hallSynonym} für {distance}',
    'Laufe {middleConnector} {distance} geradeaus durch den {hallSynonym}',
  };

  static const Set<String> hallwayWithTurn = {
    'biege {landmarkConnector} {landmark} {direction} ab',
    'nimm {landmarkConnector} {landmark} die Abzweigung nach {direction}',
    'wechsle {landmarkConnector} {landmark} die Richtung nach {direction}',
  };

  // DOOR TEMPLATES
  static const Set<String> door = {
    'Gehe {middleConnector} durch die {doorName}',
    'Passiere {middleConnector} die {doorName}',
    'Durchquere {middleConnector} die {doorName}',
  };

  static const Set<String> lockedDoor = {
    'Die {doorName} ist verschlossen. Du benötigst einen Schlüssel oder musst klingeln',
    'Vor dir ist die {doorName}, die abgeschlossen ist. Du brauchst eine Zugangsberechtigung',
    'Diese {doorName} ist gesichert. Du kannst nur mit Autorisierung passieren',
  };

  static const Set<String> multipleDoors = {
    'Gehe {middleConnector} durch {doorCount} Türen hindurch',
    'Passiere {middleConnector} {doorCount} Türen auf deinem Weg',
    'Durchquere {middleConnector} eine Folge von {doorCount} Türen',
  };

  // STAIRS TEMPLATES
  static const Set<String> stairs = {
    'Nimm {middleConnector} die Treppe {direction}',
    'Gehe {middleConnector} die Treppe {direction}',
    'Benutze {middleConnector} die Treppe, um {direction} zu gelangen',
    'Steige {middleConnector} die Treppe {direction}',
  };

  // ELEVATOR TEMPLATES
  static const Set<String> elevator = {
    'Nimm {middleConnector} den Aufzug {direction} in den {targetFloor}. Stock',
    'Fahre {middleConnector} mit dem Aufzug {direction} in den {targetFloor}. Stock',
    'Benutze {middleConnector} den Aufzug, um {direction} in den {targetFloor}. Stock zu gelangen',
  };

  // DESTINATION TEMPLATES
  static const Set<String> destination = {
    '{currentName} findest du {side} {ref}',
    '{currentName} befindet sich {side} {ref}',
    '{currentName} ist {side} {ref} zu finden',
    '{currentName} liegt {side} {ref}',
  };

  // SPECIAL TEMPLATES
  static const Set<String> toilet = {
    '{finalConnector} findest du die Toilette',
    'Die Toilette befindet sich {finalConnector} vor dir',
    '{finalConnector} erreichst du die Toilette',
  };

  static const Set<String> exit = {
    '{finalConnector} erreichst du den Ausgang',
    'Der Ausgang befindet sich {finalConnector} vor dir',
    '{finalConnector} siehst du den Ausgang',
  };
}
