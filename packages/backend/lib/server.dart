import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_server/models/rfid_response.dart';
import 'package:dart_server/state.dart';
import 'package:postgres/postgres.dart';
import 'package:scalextric_shared/shared.dart';
import 'rfid.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart' as shelf_router;

Future<void> startServer(Connection pool, shelf_router.Router app, HttpServer serverSocket) async {
  serverSocket.transform(WebSocketTransformer()).listen((WebSocket ws) {
    print("WSS: Client connected");
    wss = ws;
    rfidStart();
    ws.done.then((_) {
      print("WSS: Client disconnected");
      reset();
    });
  });

  // Returns all entries in the database
  app.get('/', (Request request) async {
    print('SERVER: GET / ');
    try {
      final data = await pool.execute("SELECT * FROM $tableName");

      final dataMap = data.map((row) => User.fromSQL(row.toColumnMap()).toJson()).toList();
      return Response.ok(jsonEncode(dataMap));
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Clear db table
  app.get('/removeAllEntries', (Request request) async {
    print('SERVER: GET /removeAllEntries');

    try {
      await pool.execute("DELETE FROM $tableName");
      return Response.ok("Successfully deleted all entries, but maintained the table structure");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Remove table from db
  app.get('/removeTableFromDb', (Request request) async {
    print('SERVER: GET /removeTableFromDb');

    try {
      await pool.execute("DROP TABLE $tableName");
      return Response.ok("Successfully deleted $tableName from db");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Create table in db
  app.get('/setup', (Request request) async {
    print('SERVER: GET /setup');

    try {
      await pool.execute(
        "CREATE TABLE $tableName( uid SERIAL, name VARCHAR(100), overall_time INT, lap_time INT, car_id VARCHAR(100), attempts INT DEFAULT 0, id VARCHAR(100) PRIMARY KEY )",
      );
      return Response.ok("Successfully created table");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Start RFID Reader
  app.get('/start', (Request request) async {
    print('SERVER: GET /start');
    try {
      await rfidStart();
      return Response.ok("Successfully started RFID reader");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Stop RFID Reader
  app.get('/stop', (Request request) async {
    print('SERVER: GET /stop');
    try {
      rfidStop();
      return Response.ok("Successfully stopped RFID reader");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Returns if we are race ready
  app.get('/raceReady', (Request request) async {
    print('SERVER: GET /stop');

    try {
      isRaceReady = true;
      rfidStart();
      return Response.ok('Is Race Ready');
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Returns the status of the game
  app.get('/status', (Request request) async {
    if (serverStatusGot != status) {
      print('SERVER: GET /status (changed)');
      serverStatusGot = status;
    }
    try {
      if (status == Status.error || status == Status.unknown) {
        status = Status.qualifying;
      }
    } catch (err) {
      status = Status.error;
    }
    return Response.ok(status.index.toString());
  });

  // Returns the lap time leaderboard
  app.get('/getLeaderboard', (Request request) async {
    print('SERVER: GET /getLeaderboard');

    try {
      final data = await pool.execute("SELECT * FROM $tableName WHERE lap_time IS NOT NULL ORDER BY lap_time::int ASC");
      final dataMap = data.map((row) => User.fromSQL(row.toColumnMap()).toJson()).toList();
      return Response.ok(jsonEncode(dataMap));
    } catch (err) {
      print('SERVER: Error: $err');

      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Returns the overall time leaderboard
  app.get('/getOverallLeaderboard', (Request request) async {
    print('SERVER: GET /getOverallLeaderboard');

    try {
      final data = await pool.execute(
        "SELECT * FROM $tableName WHERE overall_time IS NOT NULL ORDER BY overall_time::int ASC",
      );
      final dataMap = data.map((row) => User.fromSQL(row.toColumnMap()).toJson()).toList();
      return Response.ok(jsonEncode(dataMap));
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Post RFID data
  app.post('/rfid', (Request request) async {
    print('SERVER: POST /rfid');

    final List<RFIDResponse> rfidData =
        jsonDecode(await request.readAsString()).map<RFIDResponse>((e) => RFIDResponse.fromJson(e)).toList();

    try {
      await parseRFIDRead(rfidData, wss);
    } catch (err) {
      print('SERVER: Error: $err');

      return Response.badRequest(body: jsonEncode({'message': err}));
    }
    return Response.ok("RFID data received");
  });

  // Reset RFID reader
  app.post('/resetRFID', (Request request) async {
    print('SERVER: POST /resetRFID');

    rfidToggle(toggling);
    return Response.ok("Successfully reset RFID reader");
  });

  // Reset current state
  app.post('/reset', (Request request) async {
    print('SERVER: POST /reset');
    rfidStop();
    reset();
    return Response.ok("Successfully reset");
  });

  // Clear lap times for a specific user
  app.post('/clearLapTimes', (Request request) async {
    print('SERVER: POST /clearLapTimes');

    final data = await request.readAsString();
    final Map<String, dynamic> jsonData = jsonDecode(data);
    final String id = jsonData['id'];
    try {
      final data = await pool.execute("SELECT * FROM $tableName WHERE id = '$id'");
      if (data.isNotEmpty) {
        await pool.execute("UPDATE $tableName SET lap_time = NULL, overall_time = NULL WHERE id = '$id'");

        return Response.ok("Lap times cleared for user $id");
      } else {
        return Response.notFound('User not found');
      }
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Clear lap times for a specific user
  app.delete('/user', (Request request) async {
    print('SERVER: DELETE /user');

    final data = await request.readAsString();
    final Map<String, dynamic> jsonData = jsonDecode(data);
    final String id = jsonData['id'];
    try {
      await pool.execute("DELETE FROM $tableName WHERE id = '$id'");
      return Response.ok("User $id deleted");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Set the fastest lap  for a user
  app.post('/lap', (Request request) async {
    print('SERVER: POST /lap');
    rfidStop();

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final lapResponse = LapResponse.fromJson(data);
      final topValues = await getTopValues(pool);

      bool newFastestLap = false;
      bool newFastestOverall = false;
      bool newMostAttempts = false;
      try {
        if (topValues != null) {
          if (topValues.fastestLap == 0 || lapResponse.fastestLap < topValues.fastestLap) {
            if (RegExp(r'100\d$').hasMatch(carIds[0])) {
              newFastestOverall = true;
            }
          }
          if (topValues.fastestOverall == 0 || lapResponse.overallTime < topValues.fastestOverall) {
            if (RegExp(r'100\d$').hasMatch(carIds[0])) {
              newFastestOverall = true;
            }
          }

          if (lapResponse.attempts > topValues.mostAttempts) {
            newMostAttempts = true;
          }
        }
      } catch (err) {
        print('SERVER: Error: $err');
      }
      if (status != Status.race) {
        final sql =
            "INSERT INTO $tableName (name, lap_time, id, attempts, overall_time, car_id) "
            "VALUES ('${users[0].name}', ${lapResponse.fastestLap},  '${users[0].id}', ${lapResponse.attempts}, ${lapResponse.overallTime}, '${carIds.first}') "
            "ON CONFLICT (id) "
            "DO UPDATE SET "
            "lap_time = ${lapResponse.fastestLap}, "
            "attempts = ${lapResponse.attempts}, "
            "car_id = ${carIds.first}, "
            "overall_time = ${lapResponse.overallTime} ";
        await pool.execute(sql);
      }
      reset();
      rfidStop();
      return Response.ok(
        jsonEncode({
          'message': "Successfully inserted entry into $tableName",
          'newFastestLap': newFastestLap,
          'newFastestOverall': newFastestOverall,
          'newMostAttempts': newMostAttempts,
        }),
      );
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Post in new user data
  app.post('/scanUser', (Request request) async {
    print('SERVER: POST /scanUser');

    try {
      final response = await request.readAsString();
      final Map<String, dynamic> responseData = jsonDecode(response);
      final String name = responseData['name'];
      final String id = responseData['id'];
      final maxUsers = status == Status.race ? 2 : 1;
      late final User user;

      if (!users.any((user) => user.id == id) || users.length < maxUsers) {
        final data = await pool.execute("SELECT * FROM $tableName WHERE id = '$id' LIMIT 1");
        if (data.isNotEmpty) {
          final userRow = data.first.toColumnMap();
          user = User.fromJson(userRow);

          users.add(user);
        } else {
          user = User(id: id, name: name, attempts: 0);
          users.add(user);
          final sql =
              "INSERT INTO $tableName (name, id, attempts) "
              "VALUES ('${user.name}', '${user.id}', 0) "
              "ON CONFLICT (id) "
              "DO UPDATE SET "
              "attempts = 0 ";
          await pool.execute(sql);
        }
        rfidToggle(toggling);
        final toReturn = jsonEncode(user.toJson());

        if (users.length == maxUsers) {
          rfidStart();
        }
        return Response.ok(toReturn);
      } else if (users.any((user) => user.id == id)) {
        return Response.badRequest(body: 'User already scanned');
      } else if (users.length >= maxUsers) {
        return Response.badRequest(
          body: jsonEncode({'body': 'Maximum users scanned', 'status': status.index, 'maxUsers': maxUsers}),
        );
      }
    } catch (err) {
      print('SERVER: Error: $err');

      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Post new status
  app.post('/status', (Request request) async {
    print('SERVER: POST /status');

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    try {
      Status newStatus = Status.values[data['status']];

      status = newStatus;
      reset();
      return Response.ok("Status updated to $newStatus");
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Start the race
  app.post('/startRace', (Request request) async {
    print('SERVER: POST /startRace');

    if (status == Status.race && users.length == 2 && carIds.length == 2) {
      raceStart = true;
      raceStartTime = DateTime.now();
      getRaceStartTimeServer();
      return Response.ok('Race started');
    } else {
      return Response.badRequest(
        body: jsonEncode({
          'message': 'Status not correct or not enough users or cars scanned',
          'users': users.length,
          'carIds': carIds.length,
          'status': status,
        }),
      );
    }
  });

  // Remove entry from the database
  app.post('/removeEntry', (Request request) async {
    print('SERVER: POST /removeEntry');

    try {
      final body = await request.readAsString();
      final data1 = jsonDecode(body) as Map<String, dynamic>;
      final String id = data1['id'];

      final data = await pool.execute("SELECT * FROM $tableName WHERE id = $id LIMIT 1");

      data.first.toColumnMap();
      final User user = User.fromJson(data.first.toColumnMap());

      await pool.execute(
        "INSERT INTO $tableName (name, lap_time, id, overall_time, car_id) "
        "VALUES ('${user.name}', NULL, '${user.id}', NULL, NULL, ) "
        "ON CONFLICT (id) "
        "DO UPDATE SET "
        "lap_time = NULL "
        "overall_time = NULL"
        "car_id = NULL",
      );
      return Response.ok("Successfully removed entry from $tableName");
    } catch (err) {
      print('SERVER: Error: $err');

      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Testing only. Adds fake laps to the state
  app.post('/fakeLaps', (Request request) async {
    print('SERVER: POST /fakeLaps');

    carIds[0] = "1";

    final cadence = int.tryParse(request.url.queryParameters['cadence'] ?? '1') ?? 1;
    Timer.periodic(Duration(seconds: cadence), (timer) {
      final existingLaps = lapTimes["1"] ?? [];
      lapTimes["1"] = [
        ...existingLaps,
        (5000 + (3000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt(),
      ];

      if (lapTimes["1"]?.length == 13) {
        timer.cancel();
      }
    });

    return Response.ok('Fake laps set');
    // const intervalId = setInterval(() => {
    //   const existingLaps = lapTimes.get("1") ?? [];
    //   lapTimes.set("1", [...existingLaps, Math.floor(Math.random() * 3000) + 5000]);
    //   mockLapWS(lapTimes);
    //   if (lapTimes.get("1")?.length === 13) {
    //     res.sendStatus(200);
    //     clearInterval(intervalId);
    //   }
    // }, req.body.cadence * 1000);
  });

  // Set the RFID reader URL
  app.post('/setRfidUrl', (Request request) async {
    print('SERVER: POST /setRfidUrl');

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final ip = data['ip'];

    if (ip == null || ip.isEmpty) {
      return Response.badRequest(body: 'Invalid RFID URL');
    }
    if (ip == rfidAddress) {
      return Response.ok('RFID URL already set to $ip');
    }
    rfidAddress = ip;
    return Response.ok('RFID URL set to $ip');
  });

  // Set the min lap time variable
  app.post('/setMinLapTime', (Request request) async {
    print('SERVER: POST /setMinLapTime');

    try {
      final body = await request.readAsString();
      final req = jsonDecode(body) as Map<String, dynamic>;
      if (req['status'] == null || req['status'].isEmpty) {
        return Response.badRequest(body: 'Invalid status');
      }
      if (req['time'] == null || req['time'].isEmpty) {
        return Response.badRequest(body: 'Invalid time');
      }

      final time = req['time'];

      minLapTime = time;
      reset();
      return Response.ok('Min lap time set to $time');
    } catch (err) {
      print('SERVER: Error: $err');

      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Set whether the RFID reader is toggleable
  app.post('/setToggleable', (Request request) async {
    print('SERVER: POST /setToggleable');

    final body = await request.readAsString();
    final req = jsonDecode(body) as Map<String, dynamic>;
    if (req['toggleabsle'] == null || !req['toggleable']) {
      return Response.badRequest(body: 'Invalid toggleable');
    }
    if (req['toggleable'] == rfidToggleable) {
      return Response.ok('Toggleable already set to ${req['toggleable']}');
    }
    rfidToggleable = req['toggleable'];
    return Response.ok('Toggleable set to ${req['toggleable']}');
  });

  // Returns a list of all users without their laptimes
  app.get('/getAllUsers', (Request request) async {
    print('SERVER: GET /getAllUsers');
    try {
      final data = await pool.execute("SELECT name, id, attempts FROM $tableName ORDER BY name ASC");
      final dataMap = data.map((row) => User.fromSQL(row.toColumnMap()).toJson()).toList();
      return Response.ok(jsonEncode(dataMap));
    } catch (err) {
      print('SERVER: Error: $err');
      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });

  // Sets the fastest lap for a user
  app.post('/fastestLap', (Request request) async {
    print('SERVER: POST /fastestLap');
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final lapTime = data['lap'] as int;
      final userId = data['userId'] as String;
      final carId = data['carId'] as String;
      final sql =
          "INSERT INTO $tableName ( lap_time, id, car_id) "
          "VALUES ($lapTime, '$userId', '$carId' ) "
          "ON CONFLICT (id) "
          "DO UPDATE SET "
          "lap_time = $lapTime, "
          "car_id = '$carId'";
      await pool.execute(sql);

      return Response.ok('Fastest lap for $userId set to $lapTime');
    } catch (err) {
      print('SERVER: Error: $err');

      return Response.internalServerError(body: 'Internal Server Error: $err');
    }
  });
}
