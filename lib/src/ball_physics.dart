import 'dart:math';
import 'package:flutter/material.dart';
import "package:vector_math/vector_math_64.dart" show Vector2;

import '../bouncing_ball.dart';

class BallPhysics {
  Vector2 position;
  Vector2 changingInPosition;

  final double size;
  final double gravity;
  final double friction;
  final double elasticity;
  final bool isCircle;

  BallPhysics({
    required this.position,
    Vector2? changingInPosition,
    this.size = 50,
    required this.gravity,
    required this.friction,
    required this.isCircle,
    this.elasticity = 0.8,
  }) : changingInPosition = changingInPosition ?? Vector2(2, 2);

  void update(Size area, List<PositionedBlocker> blockers, double dt) {
    // Apply gravity
    changingInPosition.y += gravity;

    // Update position using velocity
    position.x += changingInPosition.x * dt;
    position.y += changingInPosition.y * dt;

    // Apply friction

    if (position.y + size >= area.height) {
      // On the floor → apply stronger horizontal friction
      if (changingInPosition.x.abs() < 0.5) {
        changingInPosition.x = 0;
      }
    }
    changingInPosition.x *= friction;

    changingInPosition.y *= friction;

    // Check collisions
    _checkBounds(area);
    _checkBlockers(blockers);
  }

  void push(double forceX, double forceY) {
    changingInPosition.x += forceX / 6;
    changingInPosition.y += forceY / 6;
  }

  void _checkBlockers(List<PositionedBlocker> blockers) {
    for (final blocker in blockers) {
      if (isCircle && blocker.isCircle) {
        _handleCircleVsCircle(blocker);
      } else if (isCircle && !blocker.isCircle) {
        _handleCircleVsRect(blocker.rect);
      } else if (!isCircle && blocker.isCircle) {
        _handleRectVsCircle(blocker);
      } else {
        buildNormalBallLogic(blockers);
      }
    }
  }

  void _handleCircleVsCircle(PositionedBlocker blocker) {
    final radius = size / 2;
    final cx = position.x + radius;
    final cy = position.y + radius;

    final bx = blocker.x + blocker.width / 2;
    final by = blocker.y + blocker.height / 2;
    final br = blocker.width / 2; // assume circular blocker width = height

    final dx = cx - bx;
    final dy = cy - by;
    final distance = sqrt(dx * dx + dy * dy);
    final minDistance = radius + br;

    if (distance < minDistance && distance > 0) {
      // Overlap
      final overlap = (minDistance - distance);
      final nx = dx / distance;
      final ny = dy / distance;

      // Push out
      position.x += nx * overlap;
      position.y += ny * overlap;

      // Reflect velocity
      final dot = changingInPosition.x * nx + changingInPosition.y * ny;
      changingInPosition.x -= 2 * dot * nx * elasticity;
      changingInPosition.y -= 2 * dot * ny * elasticity;
    }
  }

  void _handleCircleVsRect(Rect blocker) {
    final radius = size / 2;
    final cx = position.x + radius;
    final cy = position.y + radius;

    final closestX = cx.clamp(blocker.left, blocker.right);
    final closestY = cy.clamp(blocker.top, blocker.bottom);

    final dx = cx - closestX;
    final dy = cy - closestY;
    final distanceSquared = dx * dx + dy * dy;

    if (distanceSquared < radius * radius) {
      final distance = sqrt(distanceSquared);
      final nx = dx / (distance == 0 ? 1 : distance);
      final ny = dy / (distance == 0 ? 1 : distance);

      // Push out
      final overlap = radius - distance;
      position.x += nx * overlap;
      position.y += ny * overlap;

      // Reflect velocity
      final dot = changingInPosition.x * nx + changingInPosition.y * ny;
      changingInPosition.x -= 2 * dot * nx * elasticity;
      changingInPosition.y -= 2 * dot * ny * elasticity;
    }
  }

  void _handleRectVsCircle(PositionedBlocker blocker) {
    final ballRect = Rect.fromLTWH(position.x, position.y, size, size);
    final bx = blocker.x + blocker.width / 2;
    final by = blocker.y + blocker.height / 2;
    final br = blocker.width / 2;

    // Find closest point on rect to circle center
    final closestX = bx.clamp(ballRect.left, ballRect.right);
    final closestY = by.clamp(ballRect.top, ballRect.bottom);

    final dx = bx - closestX;
    final dy = by - closestY;
    final distanceSq = dx * dx + dy * dy;

    if (distanceSq < br * br) {
      final dist = sqrt(distanceSq);
      final nx = dx / (dist == 0 ? 1 : dist);
      final ny = dy / (dist == 0 ? 1 : dist);
      final overlap = br - dist;

      // Push out
      position.x -= nx * overlap;
      position.y -= ny * overlap;

      // Reflect velocity
      final dot = changingInPosition.x * nx + changingInPosition.y * ny;
      changingInPosition.x -= 2 * dot * nx * elasticity;
      changingInPosition.y -= 2 * dot * ny * elasticity;
    }
  }


  void buildNormalBallLogic(List<PositionedBlocker> blockers) {
    final ballRect = Rect.fromLTWH(position.x, position.y, size, size);

    for (final blocker in blockers) {
      if (ballRect.overlaps(blocker.rect)) {
        final overlapX = min(
          (ballRect.right - blocker.rect.left).abs(),
          (ballRect.left - blocker.rect.right).abs(),
        );
        final overlapY = min(
          (ballRect.bottom - blocker.rect.top).abs(),
          (ballRect.top - blocker.rect.bottom).abs(),
        );

        if (overlapX < overlapY) {
          // Horizontal collision
          if (ballRect.center.dx < blocker.rect.center.dx) {
            position.x = blocker.rect.left - size;
            changingInPosition.x = -changingInPosition.x * elasticity;
          } else {
            position.x = blocker.rect.right;
            changingInPosition.x = -changingInPosition.x * elasticity;
          }
        } else {
          // Vertical collision
          if (ballRect.center.dy < blocker.rect.center.dy) {
            position.y = blocker.rect.top - size;
            changingInPosition.y = -changingInPosition.y * elasticity;
          } else {
            position.y = blocker.rect.bottom;
            changingInPosition.y = -changingInPosition.y * elasticity;
          }
        }
      }
    }
  }

  void _checkBounds(Size area) {
    if (position.x <= 0) {
      position.x = 0;
      changingInPosition.x = -changingInPosition.x * elasticity;
    } else if (position.x + size >= area.width) {
      position.x = area.width - size;
      changingInPosition.x = -changingInPosition.x * elasticity;
    }

    if (position.y <= 0) {
      position.y = 0;
      changingInPosition.y = -changingInPosition.y * elasticity;
    } else if (position.y + size >= area.height) {
      position.y = area.height - size;
      changingInPosition.y = -changingInPosition.y * elasticity;
      if (changingInPosition.y.abs() < 1) {
        changingInPosition.y = 0; // stop small bouncing
      }
    }
  }
}
