import 'dart:math';
import 'package:flutter/material.dart';
import "package:vector_math/vector_math_64.dart" show Vector2;

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

  void update(Size area, List<Rect> blockers, double dt) {
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

  void _checkBlockers(List<Rect> blockers) {
    if (!isCircle) {
      final ballRect = Rect.fromLTWH(position.x, position.y, size, size);

      for (final blocker in blockers) {
        if (ballRect.overlaps(blocker)) {
          final overlapX = min(
            (ballRect.right - blocker.left).abs(),
            (ballRect.left - blocker.right).abs(),
          );
          final overlapY = min(
            (ballRect.bottom - blocker.top).abs(),
            (ballRect.top - blocker.bottom).abs(),
          );

          if (overlapX < overlapY) {
            // Horizontal collision
            if (ballRect.center.dx < blocker.center.dx) {
              position.x = blocker.left - size;
              changingInPosition.x = -changingInPosition.x * elasticity;
            } else {
              position.x = blocker.right;
              changingInPosition.x = -changingInPosition.x * elasticity;
            }
          } else {
            // Vertical collision
            if (ballRect.center.dy < blocker.center.dy) {
              position.y = blocker.top - size;
              changingInPosition.y = -changingInPosition.y * elasticity;
            } else {
              position.y = blocker.bottom;
              changingInPosition.y = -changingInPosition.y * elasticity;
            }
          }
        }
      }
    } else {
      // ✅ Circle vs Rect
      final radius = size / 2;
      final cx = position.x + radius;
      final cy = position.y + radius;

      for (final blocker in blockers) {
        final closestX = cx.clamp(blocker.left, blocker.right);
        final closestY = cy.clamp(blocker.top, blocker.bottom);

        final dxCircle = cx - closestX;
        final dyCircle = cy - closestY;
        final distanceSquared = dxCircle * dxCircle + dyCircle * dyCircle;

        if (distanceSquared < radius * radius) {
          if (dxCircle.abs() > dyCircle.abs()) {
            // Horizontal bounce
            if (cx < blocker.center.dx) {
              position.x = blocker.left - size;
              changingInPosition.x =
                  changingInPosition.x - 0.1; // bounce to left // push left
            } else {
              position.x = blocker.right;
              changingInPosition.x = changingInPosition.x + 0.1; // push right
            }
          } else {
            // Vertical bounce
            if (cy < blocker.center.dy) {
              position.y = blocker.top - size;
              changingInPosition.y = -changingInPosition.y * elasticity;
              if (cx <= blocker.left) {
                // ball at left edge → push left
                changingInPosition.x =
                    changingInPosition.x - 0.1; // bounce to left
              } else if (cx >= blocker.right) {
                // ball at right edge → push right
                changingInPosition.x = changingInPosition.x + 0.1;
              }
            } else {
              position.y = blocker.bottom;
              if (cx <= blocker.left) {
                // ball at left edge → push left
                changingInPosition.x =
                    changingInPosition.x - 0.1; // bounce to left
              } else if (cx >= blocker.right) {
                // ball at right edge → push right
                changingInPosition.x = changingInPosition.x + 0.1;
              }
              changingInPosition.y =
                  changingInPosition.y.abs() * elasticity; // push down
            }
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
