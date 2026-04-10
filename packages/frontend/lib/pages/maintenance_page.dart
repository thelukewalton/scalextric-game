import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  DateTime? _longPressStartTime;
  Timer? _progressTimer;

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() {
      _longPressStartTime = DateTime.now();
    });

    // Start a timer to update the progress indicator
    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_longPressStartTime != null) {
        final elapsed = DateTime.now().difference(_longPressStartTime!).inMilliseconds;
        if (elapsed >= 3000) {
          timer.cancel();
          _progressTimer = null;
          context.push(LeaderBoardsPage.name);
        }
        setState(() {});
      } else {
        timer.cancel();
        _progressTimer = null;
      }
    });
  }

  void _handleLongPressEnd() {
    setState(() {
      _longPressStartTime = null;
    });
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
        const LeaderBoardsPage(),
        Positioned.fill(child: Container(color: Colors.black.withAlpha(150))),
        Positioned.fill(child: CustomPaint(painter: _TapePainter())),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.red, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onLongPressStart: _handleLongPressStart,
              onLongPressEnd: (details) => _handleLongPressEnd(),
              onLongPressCancel: _handleLongPressEnd,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Game Not Available',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ).paddingTop(10),
                    Container(
                      padding: const EdgeInsets.only(top: 4),
                      width: 500,
                      child: LinearProgressIndicator(
                        value: _longPressStartTime == null
                            ? 0
                            : ((DateTime.now().difference(_longPressStartTime!).inMilliseconds) / 3000).clamp(0.0, 1.0),
                        color: Colors.red,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellowPaint = Paint()
      ..color = const Color(0xFFA8F930)
      ..strokeWidth = 100;

    canvas
      ..drawLine(
        const Offset(-100, -100),
        Offset(size.width + 200, size.height + 200),
        yellowPaint,
      )
      ..drawLine(
        Offset(size.width + 100, -100),
        Offset(0 - 100, size.height + 100),
        yellowPaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
