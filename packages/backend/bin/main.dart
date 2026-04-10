import 'dart:io';

import 'package:dart_server/db.dart';
import 'package:dart_server/ftp.dart';
import 'package:dart_server/mqtt.dart';
import 'package:dart_server/server.dart';
import 'package:dart_server/state.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();

  var env = DotEnv(includePlatformEnvironment: true)..load();

  final dbHost = env['DB_HOST'] ?? 'localhost';
  final dbPort = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
  final dbUser = env['DB_USER'] ?? 'zebra';
  final dbPassword = env['DB_PASSWORD'] ?? '';
  final dbName = env['DB_NAME'] ?? '';
  final serverPort = int.tryParse(env['SERVER_PORT'] ?? '3000') ?? 3000;

  final mqttUserName = env['MQTT_USERNAME'] ?? '';
  final mqttPassword = env['MQTT_PASSWORD'] ?? '';
  final mqttHost = env['MQTT_HOST'] ?? 'mosquitto';
  tableName = env['TABLE_NAME'] ?? 'zebra';

  getMQTTConnection(
    username: mqttUserName,
    password: mqttPassword,
    topic: '/rfid/#',
    host: mqttHost,
    identifier: 'backend',
  );

  final dbConnection = await getDBConnection(
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: dbPassword,
    database: dbName,
  );

  final app = shelf_router.Router();
  final cascade = Cascade().add(app.call);
  final server = await shelf_io.serve(cascade.handler, InternetAddress.anyIPv4, serverPort);

  print('SERVER: Serving at http://${server.address.host}:${server.port}');

  // Create WebSocket server
  final serverSocket = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print("WSS: running on ws://${serverSocket.address.host}:${serverSocket.port}");

  startServer(dbConnection, app, serverSocket);

  // Start file watcher for FTP uploads
  final watcher = DirectoryWatcher('/ftp/zebra');
  watcher.events.listen((event) {
    if (event.type == ChangeType.ADD) {
      final filename = p.basename(event.path);
      print('FTP: New file uploaded: $filename');
      processFile(event.path);
    }
  });
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
