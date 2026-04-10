import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/card.dart';
import 'package:scalextric/components/dashboard.dart';
import 'package:scalextric/components/formatted_duration.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class LiveTiming extends StatelessWidget {
  const LiveTiming({super.key, this.index, this.left});

  final int? index;
  final bool? left;
  @override
  Widget build(BuildContext context) {
    return Consumer2<WebSocketState, GameState>(
      builder: (context, state, gameState, _) {
        final String userName;

        if (gameState.loggedInUser != null) {
          userName = gameState.loggedInUser!.name;
        } else if (gameState.racers.isNotEmpty && index != null && index! - 1 < gameState.racers.length) {
          userName = gameState.racers[index! - 1].name;
        } else {
          userName = 'Player ${index == null ? '1' : index.toString()}';
        }

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment:
                left != null ? (left! ? CrossAxisAlignment.start : CrossAxisAlignment.end) : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FittedBox(
                child: Hero(
                  tag: 'name-$index',
                  child: Text(
                    userName.trim(),
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ).paddingTop(28).paddingHorizontal(gameState.settings.useFSCamera ? 150 : 250),
              Row(
                mainAxisAlignment: (left != null && gameState.settings.useFSCamera)
                    ? left!
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end
                    : MainAxisAlignment.center,
                children: [
                  TranslucentCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 80),
                      child: left != null
                          ? Row(
                              mainAxisAlignment: left! ? MainAxisAlignment.start : MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    spacing: 40,
                                    children: [
                                      LapNumber(index: index, fontSize: 68),
                                      Column(
                                        children: [
                                          const Text(
                                            'FASTEST LAP',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                          FastestLapTime(
                                            index: index,
                                            fontSize: 38,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                if (gameState.isEmulator)
                                  ZetaButton(
                                    label: 'Fake lap',
                                    onPressed: () => state.fakeLapTime(index),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      LapNumber(index: index).paddingBottom(30),
                                      if (index == null) const SizedBox(width: 180),
                                      Column(
                                        children: [
                                          const Text(
                                            'FASTEST LAP',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                          FastestLapTime(
                                            index: index,
                                            fontSize: 48,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              Dashboard(index: index),
            ],
          ),
        );
      },
    );
  }
}

class LapNumber extends StatefulWidget {
  const LapNumber({
    super.key,
    required this.index,
    this.fontSize = 48,
  });

  final int? index;
  final double fontSize;

  @override
  State<LapNumber> createState() => _LapNumberState();
}

class _LapNumberState extends State<LapNumber> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  int? _previousLap;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.greenAccent,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animate() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketState>(
      builder: (context, state, _) {
        final currentLap = widget.index != null ? state.getCurrentLapFromIndex(widget.index!) : state.currentLap;
        final actualCurrentLap = currentLap == 0 && state.lapTimes.isNotEmpty ? state.lapTimes.length : currentLap;
        final displayLap = actualCurrentLap.clamp(1, state.maxLaps);

        // Check if lap has changed and trigger animation
        if (_previousLap != null && _previousLap != actualCurrentLap && actualCurrentLap > _previousLap!) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animate();
          });
        }
        _previousLap = actualCurrentLap;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                'LAP $displayLap/${state.totalLaps}',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: widget.fontSize,
                  color: _colorAnimation.value ?? Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FastestLapTime extends StatefulWidget {
  const FastestLapTime({
    super.key,
    required this.index,
    required this.fontSize,
  });

  final int? index;
  final double fontSize;

  @override
  State<FastestLapTime> createState() => _FastestLapTimeState();
}

class _FastestLapTimeState extends State<FastestLapTime> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  Duration? _previousDuration;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.purpleAccent,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animate() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketState>(
      builder: (context, state, _) {
        final fastestLapMs = widget.index != null ? state.getFastestLapFromIndex(widget.index!) : state.fastestLap ?? 0;
        final currentDuration = Duration(milliseconds: fastestLapMs);

        // Check if fastest lap has improved and trigger animation
        if (_previousDuration != null &&
            currentDuration.inMilliseconds > 0 &&
            currentDuration != _previousDuration &&
            (currentDuration.inMilliseconds < _previousDuration!.inMilliseconds ||
                _previousDuration!.inMilliseconds == 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animate();
          });
        }
        _previousDuration = currentDuration;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FormattedDuration(
                currentDuration,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w400,
                  color: _colorAnimation.value ?? Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
