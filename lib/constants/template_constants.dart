// Neue Datei für Template-Konstanten

// Template-Typen mit Bitmasken
const int templateTypeMask = 0xF0000000; // Obere 4 Bits für Basistyp
const int templateMovement = 0x10000000; // Bewegungstemplates
const int templateExit = 0x20000000; // Ausgangstemplates
const int templateEntry = 0x30000000; // Eingangstemplates
const int templateTravel = 0x40000000; // Vertikale Bewegungstemplates
const int templateDestination = 0x50000000; // Zieltemplates
const int templateInfo = 0x60000000; // Informationstemplates

// Subtypen für Bewegungstemplates (Bits 24-27)
const int templateSubtypeMask = 0x0F000000;
const int templateStraight = 0x01000000; // Geradeaus gehen
const int templateTurn = 0x02000000; // Abbiegen
const int templateDoor = 0x03000000; // Durch Tür gehen

// Eigenschaften für Templates (Bits 16-23)
const int templatePropMask = 0x00FF0000;
const int templateWithLandmark = 0x00010000; // Mit Orientierungspunkt
const int templateWithDistance = 0x00020000; // Mit Entfernungsangabe
const int templateWithDestination = 0x00040000; // Mit Zielnennung
const int templateWithFollowup = 0x00080000; // Mit Folgeanweisung
const int templateIsFirst = 0x00100000; // Erste Anweisung

// Objekttypen für Templates (zur Kombination mit Knotentypen, Bits 8-15)
const int templateForRoom = 0x00000100;
const int templateForCorridor = 0x00000200;
const int templateForStairs = 0x00000300;
const int templateForElevator = 0x00000400;
const int templateForDoor = 0x00000500;
const int templateForToilet = 0x00000600;
const int templateForMachine = 0x00000700;

// Richtungsbezug für Templates (Bits 0-7)
const int templateDirectionMask = 0x000000FF;
const int templateDirectionStraight = 0x00000001;
const int templateDirectionLeft = 0x00000002;
const int templateDirectionRight = 0x00000003;
const int templateDirectionUp = 0x00000004;
const int templateDirectionDown = 0x00000005;
