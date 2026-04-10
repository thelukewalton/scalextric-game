import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/shaker.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class MVImage extends StatefulWidget {
  const MVImage({super.key, required this.size, this.raceMode = false});
  final bool raceMode;
  final double size;

  @override
  State<MVImage> createState() => _MVImageState();
}

class _MVImageState extends State<MVImage> with TickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  Uint8List? _previousImage;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _triggerFlash(Uint8List? currentImage) {
    // Trigger flash only when image changes from null to non-null or changes to a different image
    if (_previousImage == null && currentImage != null) {
      _flashController.reset();
      _flashController.forward().then((_) {
        if (mounted) _flashController.reverse();
      });
    } else if (_previousImage != null && currentImage != null) {
      // Use length comparison as a simple way to detect different images
      if (_previousImage!.length != currentImage.length) {
        _flashController.reset();
        _flashController.forward().then((_) {
          if (mounted) _flashController.reverse();
        });
      }
    }
    _previousImage = currentImage;
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = context.watch<GameState>().currentImageP1;

    // Trigger flash effect when image changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFlash(currentImage);
    });
    return Stack(
      children: [
        // Main image layer - isolated from shake animations
        if (currentImage != null)
          Center(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFA8F930),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: Image.memory(currentImage),
                ),
              ),
            ),
          ).paddingBottom(40)
        else
          Stack(
            children: [
              Center(
                child: SizedBox(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  child: CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: widget.size / 20,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Center(
                child: Shaker(
                  child: Image.asset('assets/fs40.png', width: widget.size / 3, height: 180),
                ),
              ),
            ],
          ),

        // Separate layer for shaking overlay - this prevents interference
        if (currentImage != null)
          Positioned(
            left: -10,
            top: 10,
            child: Shaker(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1, 1, 1),
                child: Image.asset('assets/fs40.png', height: 80),
              ),
            ),
          ),

        // Text and flash overlays
        if (!widget.raceMode)
          Positioned(
            bottom: 0,
            right: 10,
            child: Text(
              context.watch<GameState>().imageLapCount ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withAlpha(180),
                  ),
                ],
              ),
            ),
          ),

        // Camera flash overlay
        if (currentImage != null)
          AnimatedBuilder(
            animation: _flashAnimation,
            builder: (context, child) {
              return _flashAnimation.value > 0.1
                  ? Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: _flashAnimation.value * 0.4),
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}
