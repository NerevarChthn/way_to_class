// Basistypen (untere 4 Bits)
const int typeMask = 0xF; // 0000 0000 0000 1111 (Bits 0-3)
const int typeRoom = 0x1; // 0000 0000 0000 0001
const int typeCorridor = 0x2; // 0000 0000 0000 0010
const int typeStaircase = 0x3; // 0000 0000 0000 0011
const int typeElevator = 0x4; // 0000 0000 0000 0100
const int typeDoor = 0x5; // 0000 0000 0000 0101
const int typeToilet = 0x6; // 0000 0000 0000 0110
const int typeMachine = 0x7; // 0000 0000 0000 0111

// Properties (Bits 4-9) - zwischen Type und Gebäude
const int propMask = 0x3F0; // 0000 0011 1111 0000
const int propAccessible = 0x10; // 0000 0000 0001 0000 (Bit 4 - Barrierefrei)
const int propEmergency = 0x20; // 0000 0000 0010 0000 (Bit 5 - Notfall-bezogen)
const int propExit = 0x40; // 0000 0000 0100 0000 (Bit 6 - Ausgang)
const int propLocked = 0x80; // 0000 0000 1000 0000 (Bit 7 - Abgeschlossen)
const int propPublic = 0x100; // 0000 0001 0000 0000 (Bit 8 - Öffentlich)
const int propReserved = 0x200; // 0000 0010 0000 0000 (Bit 9 - Reserviert)

// Gebäude (Bits 10-12)
const int buildingShift = 10; // Ab Bit 10 beginnt das Gebäude
const int buildingMask = 0x1C00; // 0001 1100 0000 0000 (Bits 10-12)
const int buildingA = 0x0400; // 0000 0100 0000 0000 (Gebäude A = 1)
const int buildingB = 0x0800; // 0000 1000 0000 0000 (Gebäude B = 2)
const int buildingC = 0x0C00; // 0000 1100 0000 0000 (Gebäude C = 3)
const int buildingD = 0x1000; // 0001 0000 0000 0000 (Gebäude D = 4)
const int buildingE = 0x1400; // 0001 0100 0000 0000 (Gebäude E = 5)

// Etagen (Bits 13-15)
const int floorShift = 13; // Ab Bit 13 beginnt die Etagennummer
const int floorMask = 0xE000; // 1110 0000 0000 0000 (Bits 13-15)
const int floorBasement = 0x0000; // 0000 0000 0000 0000 (UG = 0)
const int floor0 = 0x2000; // 0010 0000 0000 0000 (EG = 1)
const int floor1 = 0x4000; // 0100 0000 0000 0000 (1. OG = 2)
const int floor2 = 0x6000; // 0110 0000 0000 0000 (2. OG = 3)
const int floor3 = 0x8000; // 1000 0000 0000 0000 (3. OG = 4)
const int floor4 = 0xA000; // 1010 0000 0000 0000 (4. OG = 5)
const int floor5 = 0xC000;      // 1100 0000 0000 0000 (5. OG = 6)