library;

export 'package:bouncing_ball/bouncing_ball.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'src/ball_physics.dart';
import "package:vector_math/vector_math_64.dart" show Vector2;

/// A widget that simulates a bouncing ball inside a given area.
/// The ball can be pushed by dragging (onPanUpdate) and collides with blockers.
class BouncingBall extends StatefulWidget {
  /// The width of the bouncing area.
  final double width;

  /// The height of the bouncing area.
  final double height;

  /// The diameter (size) of the ball.
  final double ballSize;

  /// The gravity force applied to the ball (downward acceleration).
  ///
  /// Default: `0.3`
  final double? gravity;

  /// The friction factor applied to the ball’s velocity each update.
  /// Values should be between `0` (full stop) and `1` (no friction).
  ///
  /// Default: `0.98`
  final double? friction;

  /// The widget used to render the ball.
  ///
  /// If null, a default blue circle will be used.
  final Widget? ball;

  /// Whether the ball should be treated as a circle (`true`)
  /// or a square (`false`) when handling collisions.
  ///
  /// Default: `true`
  final bool isCircle;

  /// The timeStep (dt) used for physics updates.
  /// Smaller values = smoother but slower motion, larger values = faster motion.
  ///
  /// Default: `2`
  final double dt;

  /// A list of blockers (obstacles) that the ball can collide with.
  ///
  /// Default: empty list
  final List<PositionedBlocker> blockers;

  /// Creates a bouncing ball simulation.
  const BouncingBall({
    super.key,
    required this.width,
    required this.height,
    required this.ballSize,
    this.gravity,
    this.friction,
    this.ball,
    this.isCircle = true,
    this.dt = 2,
    this.blockers = const [],
  });

  @override
  State<BouncingBall> createState() => _BouncingBallState();
}

class _BouncingBallState extends State<BouncingBall> {
  late BallPhysics physics;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    physics = BallPhysics(
      isCircle: widget.isCircle,
      position: Vector2(widget.width / 2, widget.height / 2),
      friction: widget.friction ?? 0.98,
      gravity: widget.gravity ?? 0.3,
      size: widget.ballSize,
    );

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        physics.update(
          Size(widget.width, widget.height),
          widget.blockers.map((b) => b.rect).toList(),
          widget.dt,
        );
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        physics.push(details.delta.dx, details.delta.dy);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade200,
        child: Stack(
          children: [
            // Ball
            Positioned(
              left: physics.position.x,
              top: physics.position.y,
              child:
                  widget.ball ??
                  Container(
                    width: widget.ballSize,
                    height: widget.ballSize,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
            ),
            // Blockers
            ...widget.blockers.map(
              (b) => Positioned(left: b.x, top: b.y, child: b.child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents an obstacle that the ball can collide with.
class PositionedBlocker {
  /// The X coordinate of the blocker’s top-left corner.
  final double x;

  /// The Y coordinate of the blocker’s top-left corner.
  final double y;

  /// The width of the blocker.
  final double width;

  /// The height of the blocker.
  final double height;

  /// The widget used to render the blocker.
  final Widget child;

  /// Creates a rectangular blocker positioned at (x, y).
  const PositionedBlocker({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.child,
  });

  /// The rectangle area of the blocker, used for collision detection.
  Rect get rect => Rect.fromLTWH(x, y, width, height);
}
