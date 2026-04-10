import 'dart:convert';
import 'dart:io';

import 'package:dart_server/state.dart';

File? lastImage;

Future<void> processFile(String filePath) async {
  lastImage = File(filePath);
  if (!await lastImage!.exists()) {
    print('File does not exist: $filePath');
    return;
  }
  int previousSize = 0;
  while (true) {
    await Future.delayed(Duration(milliseconds: ftpDelayTimeMS));
    final currentSize = await lastImage!.length();
    if (currentSize == previousSize && currentSize > 0) {
      break;
    }
    previousSize = currentSize;
  }

  final bytes = await lastImage!.readAsBytes();
  final contents = base64Encode(bytes);
  if (wss != null) {
    wss?.add(jsonEncode({'message': 'New Image', 'filePath': filePath, 'imageData': contents}));
  } else {
    print('FTP: WebSocket not connected. Cannot send image data: $filePath');
  }
}

Future<void> cleanupOldImages() async {
  print('FTP: Deleting images');
  try {
    const directory = '/ftp/zebra/upload';
    final dir = Directory(directory);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      print('FTP: Deleted directory: $directory');
    } else {
      print('FTP: Directory does not exist: $directory');
    }
  } catch (e) {
    print('ERROR: FTP cant delete dir');
  }
}
