import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:scalextric/main.dart';
import 'package:scalextric/models/scan_user_body.dart';

import 'package:scalextric/pages/qualifying/qualifying_scan_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_start_page.dart';
import 'package:scalextric/pages/race/race_start_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric_shared/shared.dart';

class RestState with ChangeNotifier {
  RestState({required this.gameState}) {
    initState();
  }
  static const fakeCarId1 = '1234567890';
  static const fakeCarId2 = '0987654321';

  bool _rfidResetting = false;

  bool get rfidResetting => _rfidResetting;

  set rfidResetting(bool value) {
    _rfidResetting = value;
    notifyListeners();
  }

  final GameState gameState;
  List<User>? lapLeaderboard;
  List<User>? overallLeaderboard;

  List<User> allUsers = [];

  Status _status = Status.unknown;
  Status get status => _status;
  set status(Status value) {
    if (value != status) {
      debugPrint('Status changed: $value');
      _status = value;
      notifyListeners();
    }
  }

  void initState() {
    getStatus(retry: true);
  }

  Future<void> postLap(int fastestLap, int overallTime, String carId) async {
    final lapResponse = LapResponse(
      fastestLap: fastestLap,
      overallTime: overallTime,
      attempts: (gameState.loggedInUser?.attempts ?? 0) + 1,
      carId: carId,
    );
    await http.post(
      Uri.parse('${gameState.settings.restUrl}/lap'),
      body: jsonEncode(lapResponse.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<void> postFastestLap(int fastestLap, String userId, String carId) async {
    try {
      await http.post(
        Uri.parse('${gameState.settings.restUrl}/fastestLap'),
        body: jsonEncode({
          'lap': fastestLap,
          'userId': userId,
          'carId': carId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchDriverStandings() async {
    final futures = [
      getLapLeaderboard,
      getOverallLeaderboard,
    ];

    try {
      await Future.wait(futures.map((e) => e()));
    } catch (e) {
      debugPrint(e.toString());
    }
    notifyListeners();
  }

  void setSelectedUser(User user) {
    gameState.loggedInUser = user;
    notifyListeners();
  }

  Future<List<User>> getLapLeaderboard() {
    return http.get(Uri.parse('${gameState.settings.restUrl}/getLeaderboard')).then((response) {
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final users = list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
        lapLeaderboard = users;
        return users;
      } else {
        throw Exception('Failed to get lap leaderboard');
      }
    });
  }

  Future<List<User>> getOverallLeaderboard() {
    return http.get(Uri.parse('${gameState.settings.restUrl}/getOverallLeaderboard')).then((response) {
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        var users = <User>[];

        try {
          users = list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('Error parsing overall leaderboard: $e');
        }
        final newIndex = users.indexWhere((element) => element.id == gameState.loggedInUser?.id);

        if (gameState.loggedInUser != null &&
            overallLeaderboard != null &&
            overallLeaderboard!.any((element) => element.id == gameState.loggedInUser!.id)) {
          final formerIndex = overallLeaderboard!.indexWhere((element) => element.id == gameState.loggedInUser!.id);

          if (newIndex != formerIndex) {
            users = users.mapIndexed((index, e) {
              if (newIndex < formerIndex) {
                // User moved up
                if (index == newIndex) {
                  return e.copyWith(change: PlaceChange.up);
                } else if (index > newIndex && index <= formerIndex) {
                  return e.copyWith(change: PlaceChange.down);
                } else {
                  return e;
                }
              } else {
                // User moved down
                if (index == newIndex) {
                  return e.copyWith(change: PlaceChange.down);
                } else if (index < newIndex && index >= formerIndex) {
                  return e.copyWith(change: PlaceChange.up);
                } else {
                  return e;
                }
              }
            }).toList();
          }
        } else if (gameState.loggedInUser != null && overallLeaderboard != null) {
          users = users.mapIndexed((index, e) {
            if (index == newIndex) {
              return e.copyWith(change: PlaceChange.up);
            } else if (index > newIndex) {
              return e.copyWith(change: PlaceChange.down);
            } else {
              return e;
            }
          }).toList();
        }
        overallLeaderboard = users;
        return users;
      } else {
        throw Exception('Failed to get overall leaderboard');
      }
    });
  }

  Future<Status> getStatus({bool retry = false}) async {
    try {
      final response =
          await http.get(Uri.parse('${gameState.settings.restUrl}/status')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final n = int.parse(response.body);
        if (n < 0 || n >= Status.values.length) {
          throw Exception('Invalid status index: $n');
        }
        if (lapLeaderboard == null || overallLeaderboard == null) {
          await fetchDriverStandings();
        }
        if (status == Status.unknown) {
          gameState.sendProperties();
        }
        final newStatus = Status.values[n];
        if (status != newStatus) {
          status = newStatus;
          debugPrint('Status changed: $status');
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      if (status != Status.unknown) {
        status = Status.unknown;
      }
    }
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2)).then((_) {
        unawaited(getStatus(retry: true));
      }),
    );

    return status;
  }

  Future<void> resetStatus({Status status = Status.qualifying}) async {
    debugPrint('Resetting status');
    try {
      final response = await http.post(
        Uri.parse('${gameState.settings.restUrl}/status'),
        body: jsonEncode({'status': status.index}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        this.status = status;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> postUser(ScanUserBody body) async {
    try {
      final b2 = jsonEncode(body.toJson());
      final res = await http.post(
        Uri.parse('${gameState.settings.restUrl}/scanUser'),
        body: b2,
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        if (res.body.isEmpty) {
          final newUser = User(
            name: '${body.firstName} ${body.surname}',
            attempts: 0,
            id: body.email,
          );
          if (status == Status.race) {
            gameState.addRacer(newUser);
            notifyListeners();
            if (gameState.racers.length == 2) {
              unawaited(
                Future<void>.delayed(const Duration(milliseconds: 1500)).then((value) {
                  router.pushReplacement(RaceStartPage.name);
                }),
              );
            }
          } else {
            gameState.loggedInUser = newUser;
          }
          return;
        }
        final userObj = jsonDecode(res.body) as Map<String, dynamic>;
        final user = User.fromJson(userObj);
        if (status == Status.race) {
          gameState.addRacer(user);
          if (gameState.racers.length == 2) {
            unawaited(
              Future<void>.delayed(const Duration(milliseconds: 1500)).then((value) {
                router.pushReplacement(RaceStartPage.name);
              }),
            );
          }
        } else {
          gameState.loggedInUser = user;
        }

        if (MyApp.navigatorKey.currentContext != null &&
            ModalRoute.of(MyApp.navigatorKey.currentContext!)?.settings.name != QualifyingScanPage.name &&
            status != Status.race) {
          router.go(QualifyingScanPage.name);
        }
      } else if (res.statusCode == 400 && res.body.contains('User already scanned')) {
        unawaited(
          Fluttertoast.showToast(
            msg: 'User already scanned',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 32,
          ),
        );
      } else {
        throw Exception('Failed to scan user');
      }
    } catch (e) {
      unawaited(
        Fluttertoast.showToast(
          msg: 'Unable to connect to server',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 32,
        ),
      );
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> startRace() async {
    final res = await http.post(
      Uri.parse('${gameState.settings.restUrl}/startRace'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      return;
    } else {
      debugPrint(res.body);
      unawaited(Fluttertoast.showToast(msg: 'Unable to start race. Please try again', toastLength: Toast.LENGTH_SHORT));
      throw Exception('Failed to start race');
    }
  }

  Future<void> resetRFID() async {
    rfidResetting = true;
    try {
      final res = await http.post(
        Uri.parse('${gameState.settings.restUrl}/resetRFID'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode != 200) {
        debugPrint(res.body);
        unawaited(
          Fluttertoast.showToast(msg: 'Unable to reset RFID. Please try again', toastLength: Toast.LENGTH_SHORT),
        );
        throw Exception('Failed to reset RFID');
      } else {
        unawaited(
          Fluttertoast.showToast(msg: 'RFID Reset', toastLength: Toast.LENGTH_SHORT),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      rfidResetting = false;
    }
  }

  Future<void> reset() async {
    await http.post(
      Uri.parse('${gameState.settings.restUrl}/reset'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<void> removeUser(String id) async {
    final res = await http.post(
      Uri.parse('${gameState.settings.restUrl}/clearLapTimes'),
      body: jsonEncode({
        'id': id,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      unawaited(Fluttertoast.showToast(msg: 'Lap times removed'));
    } else {
      unawaited(Fluttertoast.showToast(msg: 'Server error'));
    }

    await fetchDriverStandings();
  }

  Future<void> raceReady() async => http.get(Uri.parse('${gameState.settings.restUrl}/raceReady'));

  void fakeRFID(String fakeCarId, [DateTime? time]) {
    final timeString = ((time ?? DateTime.now()).toIso8601String().split('.')..removeLast()).join('.');

    http.post(
      Uri.parse('${gameState.settings.restUrl}/rfid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode([
        {
          'timestamp': timeString,
          'data': {
            'idHex': fakeCarId,
          },
        }
      ]),
    );
  }

  void clear() {
    resetStatus();

    notifyListeners();
  }

  Future<void> startRFID() {
    return http.get(
      Uri.parse('${gameState.settings.restUrl}/start'),
      headers: {'Content-Type': 'application/json'},
    ).then((response) {
      if (response.statusCode == 200) {
        debugPrint('RFID started');
      } else {
        debugPrint('Failed to start RFID: ${response.body}');
      }
    });
  }

  Future<void> stopRFID() {
    return http.get(
      Uri.parse('${gameState.settings.restUrl}/stop'),
      headers: {'Content-Type': 'application/json'},
    ).then((response) {
      if (response.statusCode == 200) {
        debugPrint('RFID started');
      } else {
        debugPrint('Failed to start RFID: ${response.body}');
      }
    });
  }

  Future<void> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('${gameState.settings.restUrl}/getAllUsers'));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;

        allUsers = list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to get all users');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> loginUser(User user, {bool skipToPlay = false}) async {
    try {
      final res = await http.post(
        Uri.parse('${gameState.settings.restUrl}/scanUser'),
        body: jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        if (res.body.isEmpty) {
          if (status == Status.race) {
            gameState.addRacer(user);
            notifyListeners();
            if (gameState.racers.length == 2) {
              unawaited(
                Future<void>.delayed(const Duration(milliseconds: 1500)).then((value) {
                  router.pushReplacement(RaceStartPage.name);
                }),
              );
            }
          } else {
            gameState.loggedInUser = user;
          }
          return true;
        }
        final userObj = jsonDecode(res.body) as Map<String, dynamic>;
        final newUser = User.fromJson(userObj);
        if (status == Status.race) {
          gameState.addRacer(newUser);
          if (gameState.racers.length == 2) {
            unawaited(
              Future<void>.delayed(const Duration(milliseconds: 1500)).then((value) {
                router.pushReplacement(RaceStartPage.name);
              }),
            );
          }
        } else {
          gameState.loggedInUser = newUser;
        }

        if (!skipToPlay &&
            MyApp.navigatorKey.currentContext != null &&
            ModalRoute.of(MyApp.navigatorKey.currentContext!)?.settings.name != QualifyingScanPage.name &&
            status != Status.race) {
          router.go(QualifyingScanPage.name);
        } else if (skipToPlay) {
          router.go(QualifyingStartPage.name);
        }
      } else if (res.statusCode == 400 && res.body.contains('User already scanned')) {
        unawaited(
          Fluttertoast.showToast(
            msg: 'User already logged in',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 32,
          ),
        );
      } else {
        throw Exception('Failed to log user in');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }
}
