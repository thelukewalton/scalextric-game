import 'dart:io';
import 'package:dart_server/ftp.dart';
import 'package:dart_server/models/rfid_response.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:postgres/postgres.dart';
import 'package:scalextric_shared/shared.dart';

bool isRaceReady = false;
int minLapTime = 2;
String rfidAddress = "192.168.0.103";
bool rfidToggleable = false;
Status status = Status.qualifying;
bool toggling = false;
List<String> carIds = [];
List<User> users = [];
bool raceStart = false;
DateTime? raceStartTime;
DateTime? raceStartTimeServer;
Map<String, List<int>> lapTimes = {};
Map<String, List<DateTime>> rfidTimes = {};
Map<String, RFIDResponse> lastData = {};
Map<String, DateTime> lastLegitimateLaps = {};
Map<String, int> reactionTime = {};
late String tableName;
late MqttServerClient client;
WebSocket? wss;
bool rfidReaderStarted = false;
Status? serverStatusGot;
int ftpDelayTimeMS = 10;

void reset() {
  users = [];
  rfidTimes = {};
  lapTimes = {};
  raceStart = false;
  carIds = [];
  isRaceReady = false;
  raceStartTime = null;
  raceStartTimeServer = null;
  reactionTime = {};
  cleanupOldImages();
}

class TopValues {
  int fastestLap;
  int fastestOverall;
  int mostAttempts;

  TopValues({required this.fastestLap, required this.fastestOverall, required this.mostAttempts});
}

Future<TopValues?> getTopValues(Connection pool) async {
  try {
    final fastestLap =
        ((await pool.execute("SELECT lap_time FROM $tableName ORDER BY lap_time ASC LIMIT 1")).first).first as int? ??
        0;

    final fastestOverall =
        ((await pool.execute("SELECT overall_time FROM $tableName ORDER BY overall_time ASC LIMIT 1")).first).first
            as int? ??
        0;

    final mostAttempts =
        ((await pool.execute("SELECT attempts FROM $tableName ORDER BY attempts ASC LIMIT 1")).first).first as int? ??
        0;

    return TopValues(fastestLap: fastestLap, fastestOverall: fastestOverall, mostAttempts: mostAttempts);
  } catch (err) {
    print('SERVER: Error: $err');
  }
  return null;
}
