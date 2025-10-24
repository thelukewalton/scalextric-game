import 'package:postgres/postgres.dart';

Future<Connection> getDBConnection({
  required String host,
  required int port,
  required String user,
  required String password,
  required String database,
}) async {
  try {
    print('DB: Connecting to the database: $host:$port');

    return await Connection.open(
      settings: ConnectionSettings(sslMode: SslMode.disable),
      Endpoint(host: host, port: port, database: database, username: user, password: password),
    );
  } catch (err) {
    print('DB: Error connecting to the database: $err');
    print('DB: Retrying in 5 seconds...');
    await Future.delayed(Duration(seconds: 5));
    return await getDBConnection(host: host, port: port, user: user, password: password, database: database);
  }
}
