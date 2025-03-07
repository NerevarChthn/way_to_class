import 'dart:math';

import 'package:way_to_class/core/components/node.dart';

enum Direction { links, rechts, geradeaus }

// Direction utilities
class DirectionUtils {
  static double _angleBetweenVectors(
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final double angleA = atan2(ay, ax);
    final double angleB = atan2(by, bx);
    double diff = angleB - angleA;

    // Normalize to [-pi, pi]
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }

    return diff;
  }

  static Direction _computeTurnFromAngleDiff(double diff) {
    final double diffDeg = diff * 180 / pi;
    return diffDeg.abs() < 20
        ? Direction.geradeaus
        : (diffDeg > 0 ? Direction.links : Direction.rechts);
  }

  static Direction computeRelativeTurn({
    required Node reference,
    required Node current,
    required Node target,
  }) {
    final double tx = (current.x - reference.x).toDouble();
    final double ty = (reference.y - current.y).toDouble(); // Umgekehrt
    final double vx = (target.x - current.x).toDouble();
    final double vy = (current.y - target.y).toDouble(); // Umgekehrt

    return _computeTurnFromAngleDiff(_angleBetweenVectors(tx, ty, vx, vy));
  }
}
