import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  static const name = '/cameraScreen';

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebSocketState>(context, listen: false).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return Center(
          child: SizedBox(
            width: 1000,
            height: 1000,
            child: state.currentImageP1 != null
                ? Image.memory(
                    state.currentImageP1!,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('Error loading image: $error');
                    },
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
