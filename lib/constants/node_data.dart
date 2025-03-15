/// Base type for all nodes (Bits 0-3)
const int nodeMask = 0xF; // 0000 0000 0000 1111
const int nodeRoom = 0x1; // 0000 0000 0000 0001
const int nodeCorridor = 0x2; // 0000 0000 0000 0010
const int nodeStaircase = 0x3; // 0000 0000 0000 0011
const int nodeElevator = 0x4; // 0000 0000 0000 0100
const int nodeDoor = 0x5; // 0000 0000 0000 0101
const int nodeToilet = 0x6; // 0000 0000 0000 0110
const int nodeMachine = 0x7; // 0000 0000 0000 0111

/// Building (Bits 4-6)
const int buildingMask = 0x70; // 0000 0000 0111 0000 (Bits 4-6)
const int buildingA = 0x10; // 0000 0000 0001 0000 (Gebäude A = 1)
const int buildingB = 0x20; // 0000 0000 0010 0000 (Gebäude B = 2)
const int buildingC = 0x30; // 0000 0000 0011 0000 (Gebäude C = 3)
const int buildingD = 0x40; // 0000 0000 0100 0000 (Gebäude D = 4)
const int buildingE = 0x50; // 0000 0000 0101 0000 (Gebäude E = 5)

/// Floors (Bits 7-9)
const int floorMask = 0x380; // 0000 0011 1000 0000 (Bits 7-9)
const int floorBasement = 0x80; // 0000 0000 1000 0000 (UG = 1)
const int floor0 = 0x100; // 0000 0001 0000 0000 (EG = 2)
const int floor1 = 0x180; // 0000 0001 1000 0000 (1. OG = 3)
const int floor2 = 0x200; // 0000 0010 0000 0000 (2. OG = 4)
const int floor3 = 0x280; // 0000 0010 1000 0000 (3. OG = 5)
const int floor4 = 0x300; // 0000 0011 0000 0000 (4. OG = 6)
const int floor5 = 0x380; // 0000 0011 1000 0000 (5. OG = 7)

/// Properties (Bits 10-13)
const int propMask = 0xFC0; // 0000 1111 1100 0000
const int propAccessible = 0x400; // 0000 0100 0000 0000 (Bit 10 - Barrierefrei)
const int propEmergencyExit =
    0x800; // 0000 1000 0000 0000 (Bit 11 - Notausgang)
const int propEntranceExit =
    0x1000; // 0001 0000 0000 0000 (Bit 12 - Ein-/Ausgang)
const int propLocked = 0x2000; // 0010 0000 0000 0000 (Bit 13 - Abgeschlossen)
