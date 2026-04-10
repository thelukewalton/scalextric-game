import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scalextric/main.dart';
import 'package:scalextric/pages/leaderboard_page.dart';

import 'package:scalextric/pages/qualifying/practice_coutdown_page.dart';
import 'package:scalextric/pages/qualifying/practice_instructions_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_finish_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_page.dart';
import 'package:scalextric/pages/race/race_finish_page.dart';
import 'package:scalextric/pages/race/race_instructions_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketState with ChangeNotifier {
  WebSocketState(this.restState, this.gameState);

  final RestState restState;
  final GameState gameState;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  List<int> lapTimes = [];
  Map<String, int> reactionTimes = {};
  Map<String, List<int>> raceLapTimes = {};
  String carId = '';
  User? raceWinner;

  Map<String, String> raceCarIds = {};

  List<String> invalidatedLaps = [];

  int get winningIndex => gameState.racers.indexOf(raceWinner!);

  int get maxLaps => restState.status == Status.race ? gameState.settings.raceLaps : gameState.settings.qualifyingLaps;

  bool get connected => _channel != null;

  bool isBestReaction(String id) {
    if (reactionTimes.isEmpty) {
      return false;
    }
    final bestReaction = reactionTimes.entries
        .where((element) => element.key == id)
        .map((e) => e.value)
        .reduce((value, element) => value < element ? value : element);
    return bestReaction == reactionTimes.values.reduce((value, element) => value < element ? value : element);
  }

  void addMessage(String message) {
    if (message.contains('jump')) {
      //jump start
      final obj = jsonDecode(message);

      final carId = (obj as Map<String, dynamic>)['carId'] as String;
      invalidatedLaps.add(carId);
    } else if (message.contains('Car scanned')) {
      try {
        final obj = jsonDecode(message);

        final scannedCarId = (obj as Map<String, dynamic>)['carId'] as String;
        if (restState.status != Status.race) {
          carId = scannedCarId;
        } else {
          if (raceCarIds.isEmpty) {
            raceCarIds[gameState.racers.first.id] = scannedCarId;
          } else {
            raceCarIds[gameState.racers.last.id] = scannedCarId;
            restState.stopRFID();
            router.go(RaceInstructionsPage.name);
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error parsing message 2: $message');
      }
      if (restState.status != Status.race && gameState.loggedInUser != null) {
        if (gameState.loggedInUser!.attempts == 0) {
          router.pushReplacement(PracticeInstructionsPage.name);
        } else {
          router.pushReplacement(PracticeCountdownPage.name);
        }
      }

      return;
    } else if (message.contains('reactionTime')) {
      final obj = jsonDecode(message);
      final carId = (obj as Map<String, dynamic>)['carId'] as String;
      final reactionTime = obj['reactionTime'] as int;
      reactionTimes[carId] = reactionTime;
    } else if (message.contains('New Image')) {
      try {
        final obj = jsonDecode(message) as Map<String, dynamic>;
        final imageData = obj['imageData'] as String;
        gameState.imageLapCount = lapTimes.length < gameState.settings.practiceLaps
            ? 'Practice lap ${lapTimes.length + 1}'
            : 'Lap ${lapTimes.length - gameState.settings.practiceLaps + 1}';
        gameState.currentImageP1 = base64Decode(imageData);
      } catch (e) {
        debugPrint('Error parsing message FTP Image: $message');
      }
    } else {
      try {
        final obj = jsonDecode(message) as Map<String, dynamic>;
        if (restState.status != Status.race) {
          lapTimes = (obj.entries.first.value as List).map((e) => e as int).toList();
        } else {
          for (final element in obj.entries) {
            final carId = element.key;
            if (raceCarIds.entries.any((element) => element.value == carId)) {
              final lapTimes = (element.value as List).map((element) => element as int);
              raceLapTimes[carId] = lapTimes.toList();
            }
          }
          if (raceWinner == null) {
            final finishers =
                raceLapTimes.entries.where((element) => element.value.length > gameState.settings.raceLaps);

            if (finishers.isNotEmpty) {
              final String winingCarId;

              if (finishers.length == 1) {
                winingCarId = finishers.first.key;
              } else {
                final p1Times = finishers.first.value
                    .getRange(1, gameState.settings.raceLaps)
                    .reduce((combined, element) => combined + element);
                final p2Times = finishers.last.value
                    .getRange(1, gameState.settings.raceLaps)
                    .reduce((combined, element) => combined + element);
                if (p1Times < p2Times) {
                  winingCarId = finishers.first.key;
                } else {
                  winingCarId = finishers.last.key;
                }
              }
              final userId = getUserIdFromCarId(winingCarId);
              raceWinner = gameState.racers.firstWhereOrNull((element) => element.id == userId);
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing message 3: $message');
      }
    }

    if (restState.status != Status.race) {
      if (practiceLapsRemaining > 0) {
        router.pushReplacement(PracticeCountdownPage.name);
      } else if (lapTimes.length == gameState.settings.practiceLaps) {
        router.pushReplacement(QualifyingPage.name);
      } else if (lapTimes.length >= gameState.settings.practiceLaps + gameState.settings.qualifyingLaps) {
        sendLapTime();
      }
    } else if (raceWinner != null) {
      sendFastestLaps();
      restState
        ..reset()
        ..stopRFID();
      router.pushReplacement(RaceFinishPage.name);
    }

    notifyListeners();
  }

  void sendFastestLaps() {
    try {
      final player1Laps = raceLapTimes.entries.toList()[0].value.sublist(1)..sort();
      final player1Id = raceCarIds.entries.first.key;
      final player1CarId = raceCarIds.entries.first.value;
      final player1FastestLap = player1Laps.first;

      if (restState.lapLeaderboard != null && restState.lapLeaderboard!.isNotEmpty) {
        final leaderboard = restState.lapLeaderboard!;
        final player1Lap = leaderboard.firstWhereOrNull((e) => e.id == player1Id);

        if ((player1Lap != null && player1Lap.fastestLap != null && player1Lap.fastestLap! > player1FastestLap) ||
            player1Lap == null) {
          restState.postFastestLap(player1FastestLap, player1Id, player1CarId);
        }
      }
    } catch (e) {
      debugPrint('Error sending fastest laps: PLayer 1$e');
    }
    try {
      final player2Laps = raceLapTimes.entries.toList()[1].value.sublist(1)..sort();
      final player2Id = raceCarIds.entries.last.key;
      final player2CarId = raceCarIds.entries.last.value;
      final player2FastestLap = player2Laps.last;

      if (restState.lapLeaderboard != null && restState.lapLeaderboard!.isNotEmpty) {
        final leaderboard = restState.lapLeaderboard!;

        final player2Lap = leaderboard.firstWhereOrNull((e) => e.id == player2Id);

        if ((player2Lap != null && player2Lap.fastestLap != null && player2Lap.fastestLap! > player2FastestLap) ||
            (player2Lap == null)) {
          restState.postFastestLap(player2FastestLap, player2Id, player2CarId);
        }
      }
    } catch (e) {
      debugPrint('Error sending fastest laps: PLAYER 2 $e');
    }
    restState.fetchDriverStandings();
  }

  String getUserIdFromCarId(String carId) {
    return raceCarIds.entries.firstWhere((element) => element.value == carId).key;
  }

  String? getUserIdFromIndex(int index) {
    if (index - 1 >= gameState.racers.length) {
      return null;
    }
    return gameState.racers[index - 1].id;
  }

  String getCarIdFromIndex(int index) {
    return raceCarIds.entries.toList()[index - 1].value;
  }

  List<int>? getLapTimesFromIndex(int index) {
    final userId = getUserIdFromIndex(index);
    if (userId == null) {
      return null;
    }
    return getLapTimes(userId);
  }

  List<int>? getLapTimes(String carId) {
    return raceLapTimes[carId];
  }

  bool isInvalidated(int index) {
    final carId = getCarIdFromIndex(index);

    return invalidatedLaps.contains(carId);
  }

  int get averageLapTime {
    if (lapTimes.isEmpty || lapTimes.length < gameState.settings.practiceLaps) {
      return 0;
    }
    final x = lapTimes.sublist(gameState.settings.practiceLaps).reduce((value, element) => value + element) ~/
        (lapTimes.length - gameState.settings.practiceLaps);
    return x;
  }

  Future<void> sendLapTime() async {
    unawaited(router.pushReplacement(QualifyingFinishPage.name));
    if (fastestLap == null) {
      return;
    }
    await restState.postLap(fastestLap!, overallTime, carId);
    await restState.fetchDriverStandings();
    unawaited(restState.reset());
  }

  int get practiceLapsRemaining => gameState.settings.practiceLaps - lapTimes.length;

  String get practiceLapsRemainingString => practiceLapsRemaining.clamp(1, gameState.settings.practiceLaps).toString();

  double get averageSpeed {
    if (lapTimes.isEmpty) {
      return 0;
    }
    // Convert lap time from milliseconds to seconds for m/s
    return lapTimes.last == 0 ? 0 : gameState.settings.circuitLength / (lapTimes.last / 1000);
  }

  DateTime? _startTime;

  DateTime get startTime => _startTime ??= DateTime.now();

  set startTime(DateTime? value) {
    _startTime = value;
    notifyListeners();
  }

  int? get fastestLap => lapTimes.length <= gameState.settings.practiceLaps
      ? null
      : lapTimes.sublist(gameState.settings.practiceLaps).reduce((value, element) => value < element ? value : element);

  int get overallTime {
    final qualifyingLaps = lapTimes.length - gameState.settings.practiceLaps;
    if (qualifyingLaps <= 0) {
      return 0;
    }
    return lapTimes.skip(gameState.settings.practiceLaps).fold(0, (sum, time) => sum + time);
  }

  int get currentLap => restState.status == Status.race ? 0 : lapTimes.length - gameState.settings.practiceLaps + 1;

  int getCurrentLapFromIndex(int index) {
    final carId = getCarIdFromIndex(index);
    final lapTimes = getLapTimes(carId);
    if (lapTimes == null || lapTimes.isEmpty) {
      return 0;
    }
    return lapTimes.length;
  }

  double getAverageSpeedFromIndex(int index) {
    final carId = getCarIdFromIndex(index);
    final lapTimes = getLapTimes(carId);
    if (lapTimes == null || lapTimes.isEmpty || lapTimes.length == 1) {
      return 0;
    }

    return gameState.settings.circuitLength / (lapTimes.last / 1000);
  }

  int get currentLapTime {
    if (lapTimes.isEmpty) {
      return 0;
    }
    return lapTimes.last;
  }

  int get totalLaps =>
      restState.status == Status.race ? gameState.settings.raceLaps : gameState.settings.qualifyingLaps;

  String qualifyingLapTime(int lap) {
    if (lapTimes.length > (gameState.settings.practiceLaps - 1) + lap) {
      return lapTimes[lap + gameState.settings.practiceLaps - 1].toStringAsFixed(3);
    } else {
      return '';
    }
  }

  String raceLapTime(int lap, int index) {
    final carId = getCarIdFromIndex(index);
    final lapTimes = getLapTimes(carId);
    if (lapTimes == null || lapTimes.length <= lap) {
      return '';
    }
    return lapTimes[lap].toStringAsFixed(3);
  }

  int getFastestCurrantLap([int? index]) {
    if (index != null) {
      final carId = getCarIdFromIndex(index);
      final lapTimes = getLapTimes(carId);
      if (lapTimes == null || lapTimes.isEmpty) {
        return 0;
      }
      return lapTimes.reduce((value, element) => value < element ? value : element);
    } else if (restState.status == Status.race) {
      return raceLapTimes.entries
          .expand((element) => element.value)
          .reduce((value, element) => value < element ? value : element);
    } else {
      if (lapTimes.isEmpty || lapTimes.length < gameState.settings.practiceLaps + 1) {
        return 100000;
      }
      return lapTimes
          .slice(gameState.settings.practiceLaps)
          .reduce((value, element) => value < element ? value : element);
    }
  }

  int getFastestUserLap() {
    final baseLine = getFastestCurrantLap();
    final userLap = gameState.loggedInUser?.fastestLap ?? 0;
    if (userLap != 0 && userLap < baseLine) {
      return userLap;
    }
    return baseLine;
  }

  int getFastestLapFromIndex(int index) {
    final carId = getCarIdFromIndex(index);
    final lapTimes = getLapTimes(carId);
    if (lapTimes == null || lapTimes.isEmpty || lapTimes.length == 1) {
      return 0;
    }
    return lapTimes.reduce((value, element) => value < element ? value : element);
  }

  Color? getLapColor(String time, int lap, [int? index]) {
    if (time == getFastestCurrantLap(index).toStringAsFixed(3) && index != null ||
        time == getFastestUserLap().toStringAsFixed(3) && index == null) {
      return Colors.purple;
    } else if (index == null && double.tryParse(time) != null && double.parse(time).toInt() == fastestLap) {
      return Colors.green;
    } else if (index != null && isInvalidated(index) && lap == 1) {
      return Colors.red;
    }
    return null;
  }

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(gameState.settings.wsUrl);
      await _channel?.ready;
      debugPrint('Connected to: ${gameState.settings.wsUrl}');
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            debugPrint('Received: $data');
            addMessage(data.toString());
            notifyListeners();
          } catch (e) {
            debugPrint('Error parsing message 1: $data');
          }
        },
        onDone: () {
          clear();
          if (lapTimes.length < 13) {
            Fluttertoast.showToast(msg: 'Connection lost');
            router.go(LeaderBoardsPage.name);
          }
        },
        onError: (obj) {
          clear();

          if (lapTimes.length < 13) {
            Fluttertoast.showToast(msg: 'Connection lost');
            router.go(LeaderBoardsPage.name);
          }
        },
      );
    } catch (e) {
      debugPrint('Error connecting to: ${gameState.settings.wsUrl}');
    }
  }

  void fakeToggleJumpStart(int index) {
    final carId = getCarIdFromIndex(index);
    if (invalidatedLaps.contains(carId)) {
      invalidatedLaps.remove(carId);
    } else {
      invalidatedLaps.add(carId);
    }

    notifyListeners();
  }

  void fakeLapTime([int? index]) {
    final fakeLapTime = (5000 + (10000 - 5000) * (DateTime.now().millisecondsSinceEpoch % 1000) ~/ 1000) + 20000;
    // final fakeLapTime = 20;
    if (index != null) {
      final carId = getCarIdFromIndex(index);
      if (raceLapTimes[carId] == null) {
        raceLapTimes[carId] = [];
      } else {
        raceLapTimes[carId]!.add(fakeLapTime);
        addMessage(jsonEncode(raceLapTimes));
      }
    } else {
      final newLaptimes = lapTimes..add(fakeLapTime);

      addMessage('{"lapTimes" : ${jsonEncode(newLaptimes)}}');
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      debugPrint('Sending message: $message');
      _channel!.sink.add(message);
    }
  }

  void clear() {
    disconnect();
    clearData();
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void clearData() {
    lapTimes = [];
    raceLapTimes = {};
    carId = '';
    raceWinner = null;
    raceCarIds = {};
    _startTime = null;
    invalidatedLaps = [];
    reactionTimes = {};
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    clearData();
    super.dispose();
  }
}
