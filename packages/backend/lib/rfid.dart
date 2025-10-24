import 'dart:convert';
import 'dart:io';
import 'package:dart_server/models/rfid_response.dart';
import 'package:dart_server/state.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:scalextric_shared/models/status.dart';
import 'package:scalextric_shared/models/user.dart';

String? webUsername = Platform.environment['WEB_USERNAME'] ?? '';
String? webPassword = Platform.environment['WEB_PASSWORD'] ?? '';

Future<void> rfidStart() async {
  print('INTERNAL: Starting RFID reader...');
  try {
    final builder =
        MqttClientPayloadBuilder()
          ..addString(jsonEncode({'command': 'start', 'command_id': DateTime.now().toIso8601String(), 'payload': {}}));

    client.publishMessage('/rfid/control', MqttQos.exactlyOnce, builder.payload!);
  } catch (err) {
    print('MQTT: Error: $err');
  }
}

Future<void> rfidStop() async {
  try {
    print('INTERNAL: Stopping RFID reader...');

    final builder =
        MqttClientPayloadBuilder()
          ..addString(jsonEncode({'command': 'stop', 'command_id': DateTime.now().toIso8601String(), 'payload': {}}));

    client.publishMessage('/rfid/control', MqttQos.exactlyOnce, builder.payload!);
  } catch (err) {
    print('MQTT: Error: $err');
  }
}

String rfidScannedCar(RFIDResponse response, WebSocket wss) {
  final scannedCarId = response.idHex;
  wss.add(jsonEncode({'message': 'Car scanned', 'carId': scannedCarId}));
  return scannedCarId;
}

List<int> rfidQualifyingLap(RFIDResponse current, DateTime previous, List<int> lapTimes) {
  final newTime = current.timestamp.millisecondsSinceEpoch;
  final oldTime = previous.millisecondsSinceEpoch;

  final lapTime = newTime - oldTime;

  if (lapTime > 0) {
    lapTimes.add(lapTime);
    print('MQTT: Laptimes: $lapTimes');
  }
  lastLegitimateLaps[current.idHex] = current.timestamp;
  return lapTimes;
}

List<int> rfidRaceLap(RFIDResponse current, DateTime previous, List<int> lapTimes) {
  final newTime = current.timestamp.millisecondsSinceEpoch;
  final oldTime = previous.millisecondsSinceEpoch;

  final lapTime = newTime - oldTime;

  if (lapTime > 0) {
    lapTimes.add(lapTime);
  }
  return lapTimes;
}

Map<String, RFIDResponse> rfidSaveData(List<RFIDResponse> responses, Map<String, RFIDResponse> lastData) {
  for (var response in responses) {
    final elementId = response.idHex;
    final newTime = response.timestamp.millisecondsSinceEpoch;

    if (!lastData.containsKey(elementId) || newTime > lastData[elementId]!.timestamp.millisecondsSinceEpoch) {
      lastData[elementId] = response;
    }
  }
  return lastData;
}

bool rfidCheckValidity(List<RFIDResponse> newResponses, List<User> users) {
  return users.isNotEmpty && newResponses.isNotEmpty && newResponses[0].idHex.isNotEmpty;
}

List<RFIDResponse>? rfidCompareToPrevious(Map<String, RFIDResponse> oldData, List<RFIDResponse> newResponses) {
  final newEntries =
      newResponses.where((response) {
        final elementId = response.idHex;
        return !oldData.containsKey(elementId) || oldData[elementId]!.timestamp.isBefore(response.timestamp);
      }).toList();

  if (newEntries.isEmpty) {
    return null;
  }

  return newEntries;
}

Future<void> rfidToggle(bool toggling) async {
  if (toggling) return;
  try {
    await rfidStop();
    rfidStart();
  } catch (err) {
    print('SERVER: Error: $err');
  }
}

void addToRFIDTimes(RFIDResponse response, Map<String, List<DateTime>> rfidTimes) {
  final userRfidTimes = rfidTimes[response.idHex] ?? [];
  userRfidTimes.add(response.timestamp);
  rfidTimes[response.idHex] = userRfidTimes;
}

Map<String, dynamic> rfidRaceMode(int minLapTime) {
  final raceConfigPath = File('consts/race_config.json');
  final raceConfig = jsonDecode(raceConfigPath.readAsStringSync());
  return {
    ...raceConfig,
    'reportFilter': {'duration': minLapTime, 'type': 'PER_ANTENNA'},
  };
}

Map<String, dynamic> rfidQualifyingMode(int minLapTime) {
  final qualifyingConfigPath = File('consts/qualifying_config.json');
  final qualifyingConfig = jsonDecode(qualifyingConfigPath.readAsStringSync());
  return {
    ...qualifyingConfig,
    'reportFilter': {'duration': minLapTime, 'type': 'PER_ANTENNA'},
  };
}

Future<void> parseRFIDRead(List<RFIDResponse> rfidData, WebSocket? wss) async {
  // Check if this is an RFID data response
  if (!rfidCheckValidity(rfidData, users)) {
    print('MQTT: Invalid RFID data: ${rfidData[0].idHex}, ${rfidData[0].timestamp}');
  } else {
    // Parse the JSON data, only return new data
    final jsonList = rfidCompareToPrevious(lastData, rfidData);

    if (jsonList != null && jsonList.isNotEmpty) {
      if (rfidToggleable) rfidToggle(toggling);
      for (final json in jsonList) {
        if (status != Status.race) {
          // Qualifying
          if (carIds.isNotEmpty && carIds[0] == json.idHex) {
            final userRfidTimes = rfidTimes[json.idHex];

            final lastRFIDTime =
                (userRfidTimes != null && userRfidTimes.isNotEmpty) ? userRfidTimes[userRfidTimes.length - 1] : null;

            if (lastRFIDTime != null) {
              if (lastRFIDTime.difference((json.timestamp)).inSeconds.abs() < minLapTime) {
                print("MQTT: Lap too quick: ${json.timestamp.toIso8601String().split('T').last}");
              } else {
                print("MQTT: Adding laptime: ${json.timestamp.toIso8601String().split('T').last}");

                lapTimes[json.idHex] = rfidQualifyingLap(
                  json,
                  lastLegitimateLaps[json.idHex] ?? lastRFIDTime,
                  lapTimes[json.idHex] ?? [],
                );
                if (wss != null) {
                  wss.add(jsonEncode(lapTimes));
                }
              }
            }
          } else if (carIds.isEmpty) {
            /// Scanning car login for the first time
            final id = json.idHex;

            if (RegExp(r'100\d$').hasMatch(id)) {
              if (wss != null) {
                rfidScannedCar(json, wss);
              }
              carIds.add(json.idHex);
              rfidTimes[json.idHex] = [json.timestamp];

              lastLegitimateLaps[json.idHex] = json.timestamp;
            } else {
              print("MQTT: Wrong car scanned - scan a car with a valid ID (1000-1010)");
              return;
            }
          } else {
            print('MQTT: Wrong car scanned - another car logged in already');
            return;
          }
        } else {
          // Race
          if (carIds.length < 2 && users.isNotEmpty && users.length < 3 && !carIds.contains(json.idHex)) {
            print("MQTT: Adding new car");
            if (wss != null) {
              rfidScannedCar(json, wss);
            }

            carIds.add(json.idHex);
            rfidTimes[json.idHex] = [json.timestamp];
            lastLegitimateLaps[json.idHex] = json.timestamp;
          } else if (carIds.length == 2 && users.length == 2 && carIds.contains(json.idHex)) {
            final userRfidTimes = rfidTimes[json.idHex];
            final lastRFIDTime = userRfidTimes != null ? userRfidTimes[userRfidTimes.length - 1] : null;
            if (raceStart) {
              if (lastRFIDTime != null) {
                if (lastRFIDTime.difference((json.timestamp)).inSeconds.abs() < minLapTime) {
                  print("MQTT: Lap too quick: ${json.timestamp.toIso8601String().split('T').last}");
                } else {
                  print("MQTT: Adding laptime: ${json.idHex}:  ${json.timestamp.toIso8601String().split('T').last}");
                  lapTimes[json.idHex] = rfidRaceLap(json, lastRFIDTime, lapTimes[json.idHex] ?? []);

                  wss?.add(jsonEncode(lapTimes));
                  checkReactionTime(wss);
                }
              } else {
                print("MQTT: No previous RFID time");
              }
            } else {
              //jump start - send notification to frontend
              if (isRaceReady) {
                wss?.add(jsonEncode({'message': "jump start detected", 'carId': json.idHex}));
              }
            }
          }
        }

        addToRFIDTimes(json, rfidTimes);
      }
    }
  }
  lastData = rfidSaveData(rfidData, lastData);
}

getRaceStartTimeServer() {
  final builder =
      MqttClientPayloadBuilder()..addString(
        jsonEncode({'command': 'get_status', 'command_id': DateTime.now().toIso8601String(), 'payload': {}}),
      );

  client.publishMessage('/rfid/management', MqttQos.exactlyOnce, builder.payload!);
}

void checkReactionTime(WebSocket? wss) {
  if (raceStartTimeServer != null && lapTimes.isNotEmpty) {
    for (var carId in carIds) {
      try {
        if (reactionTime[carId] == null &&
            rfidTimes[carId] != null &&
            rfidTimes[carId]!.isNotEmpty &&
            rfidTimes[carId]!.length > 1) {
          final firstRFIDTimeAfterStart = rfidTimes[carId]!.firstWhere(
            (time) => time.isAfter(raceStartTimeServer!),
            orElse: () => rfidTimes[carId]![1],
          );

          reactionTime[carId] =
              (firstRFIDTimeAfterStart.millisecondsSinceEpoch - raceStartTimeServer!.millisecondsSinceEpoch).abs();

          wss?.add(jsonEncode({'carId': carId, 'reactionTime': reactionTime[carId]}));
        }
      } catch (e) {
        print("MQTT: Error checking reaction time for $carId: $e");
      }
    }
  }
}
