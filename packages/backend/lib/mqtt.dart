/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

// Edited heavily

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_server/models/rfid_response.dart';
import 'package:dart_server/rfid.dart';
import 'package:dart_server/state.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<void> getMQTTConnection({
  required String username,
  required String password,
  required String topic,
  required String host,
  required String identifier,
}) async {
  try {
    print('MQTT: Connecting to broker.');
    await _mqtt(host: host, password: password, topic: topic, username: username, identifier: identifier);
  } catch (e) {
    print('MQTT: Error connecting to broker - $e');
    print('MQTT: Retrying in 5 seconds...');
    await Future.delayed(Duration(seconds: 5));
    return await getMQTTConnection(
      host: host,
      password: password,
      topic: topic,
      username: username,
      identifier: identifier,
    );
  }
}

Future<void> _mqtt({
  required String username,
  required String password,
  required String topic,
  required String host,
  required String identifier,
}) async {
  client = MqttServerClient(host, identifier);
  try {
    client.onDisconnected = (() {
      print('MQTT: disconnected');
      throw Exception('MQTT: Disconnected');
    });
  } catch (e) {
    rethrow;
  }
  client
    ..setProtocolV311()
    ..keepAlivePeriod = 20
    ..connectTimeoutPeriod = 2000
    ..onConnected = (() => print('MQTT: client connected'))
    ..onSubscribed = ((topic) => print('MQTT: client subscribed to topic $topic'));

  final connectionMessage = MqttConnectMessage()
      .withClientIdentifier('backend')
      .withWillTopic('willtopic')
      .withWillMessage('will message')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  print('MQTT: lient connecting....');
  client.connectionMessage = connectionMessage;

  try {
    await client.connect(username, password);
  } on NoConnectionException catch (e) {
    // Raised by the client when connection fails.
    print('MQTT: client exception - $e');
    client.disconnect();
  } on SocketException catch (e) {
    // Raised by the socket layer
    print('MQTT: socket exception - $e');
    client.disconnect();
  }

  if (client.connectionStatus?.state == MqttConnectionState.connected) {
    print('MQTT: client connected');
  } else {
    print('MQTT: client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  print('MQTT: subscribing to the topic $topic');
  client.subscribe(topic, MqttQos.atMostOnce);

  client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    try {
      if (c[0].topic == '/rfid/control-resp') {
        final obj = jsonDecode(pt);
        if (obj['command'] == 'start' && obj['response'] == 'success') {
          print('MQTT:  RFID reader started');
          rfidReaderStarted = true;
        } else if (obj['command'] == 'stop' && obj['response'] == 'success') {
          print('MQTT: RFID reader stopped');
          rfidReaderStarted = false;
        }
      } else if (c[0].topic == '/rfid') {
        final rfidRead = RFIDResponse.fromJson(jsonDecode(pt));
        parseRFIDRead([rfidRead], wss);
      } else if (c[0].topic == '/rfid/management-resp') {
        final obj = jsonDecode(pt);
        if (obj['command'] == 'get_status' &&
            obj['response'] == 'success' &&
            obj['payload'] != null &&
            obj['payload'] != {} &&
            obj['payload']['systemTime'] != null) {
          print('MQTT: Received management message with system time');
          final payload = obj['payload'];
          raceStartTimeServer ??= DateTime.parse(payload['systemTime']);
          checkReactionTime(wss);
        }
      }
    } catch (e) {
      print('MQTT: Error parsing JSON: $e');
    }
  });
}
