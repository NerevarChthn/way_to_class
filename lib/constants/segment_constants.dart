// Basis Segmenttypen (Bits 0-3)
const int segTypeMask = 0x0F; // 0000 1111
const int segCorridor = 0x01; // 0000 0001
const int segTransition = 0x02; // 0000 0010
const int segVertical = 0x04; // 0000 0100
const int segDestination = 0x08; // 0000 1000

// Subtypen (Bits 4-7)
const int segSubtypeMask = 0xF0; // 1111 0000
const int segStraight = 0x10; // 0001 0000
const int segTurn = 0x20; // 0010 0000
const int segExit = 0x30; // 0011 0000
const int segEntry = 0x40; // 0100 0000
const int segDoor = 0x50; // 0101 0000
const int segUp = 0x60; // 0110 0000
const int segDown = 0x70; // 0111 0000
const int segFacility = 0x80; // 1000 0000

// Eigenschaften (höhere Bits 8-15)
const int segPropFirst = 0x100; // 0000 0001 0000 0000 - Erstes Segment
const int segPropLandmark = 0x200; // 0000 0010 0000 0000 - Hat Landmarke
const int segPropFollowing = 0x400; // 0000 0100 0000 0000 - Folgendes Segment
const int segPropShort = 0x800; // 0000 1000 0000 0000 - Kurze Distanz
const int segPropAccessible = 0x1000; // 0001 0000 0000 0000 - Barrierefrei

const int segCorridorStraight = segCorridor | segStraight; // corridorStraight
const int segCorridorTurn = segCorridor | segTurn; // corridorTurn
const int segRoomExit = segTransition | segExit; // roomExit
const int segRoomEntry = segTransition | segEntry; // roomEntry
const int segDoorPass = segTransition | segDoor; // doorPass
const int segStairsUp = segVertical | segUp; // stairsUp
const int segStairsDown = segVertical | segDown; // stairsDown
const int segElevatorUp = segVertical | segUp | segPropAccessible; // elevatorUp
const int segElevatorDown =
    segVertical | segDown | segPropAccessible; // elevatorDown
const int segFacilityExit =
    segTransition | segExit | segFacility; // nonRoomExit
const int segFacilityEntry =
    segTransition | segEntry | segFacility; // nonRoomEntry
