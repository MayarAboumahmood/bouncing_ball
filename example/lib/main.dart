import 'package:flutter/material.dart';
import 'package:bouncing_ball/bouncing_ball.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final double ballHeightAndWidth = 80;

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Scaffold(
        body: Center(
          child: BouncingBall(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            gravity: 0.2,
            dt: 1,
            isCircle: true,
            // friction: 0.9,
            ballSize: ballHeightAndWidth * 0.9,
            ball: Container(
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              height: ballHeightAndWidth,
              width: ballHeightAndWidth,
            ),
            blockers: [
              PositionedBlocker(
                x: 100,
                y: 600,
                width: 100,
                height: 100,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              PositionedBlocker(
                x: 100,
                y: 250,
                width: 200,
                height: 10,
                child: Container(width: 200, height: 10, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
