import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scalextric/main.dart';
import 'package:scalextric/models/scan_user_body.dart';
import 'package:scalextric/pages/qualifying/qualifying_scan_page.dart';
import 'package:scalextric/pages/race/race_scan_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/shared.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class DataWedgeState with ChangeNotifier {
  DataWedgeState({required this.gameState, required this.restState});

  final GameState gameState;
  final RestState restState;

  FlutterDataWedge? fdw;
  String? error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> initScanner({bool redirect = false}) async {
    try {
      if (Platform.isAndroid && gameState.settings.useBarcodesForUsers && !gameState.isEmulator) {
        fdw = FlutterDataWedge();
        await fdw?.initialize();
        await fdw?.createDefaultProfile(profileName: 'f1');
        await fdw?.enableScanner(true);
        await fdw?.activateScanner(true);
        await scanBarcode(redirect: redirect);
      } else {
        error = gameState.isEmulator
            ? 'DataWedge is not available on emulator. Use physical Zebra device for scanner functionality.'
            : 'DataWedge is not supported on this platform or barcodes are not enabled.';
        await fdw?.scannerControl(false);
        await fdw?.enableScanner(false);
        await fdw?.activateScanner(false);
        debugPrint('DW OFF - ${gameState.isEmulator ? "Emulator detected" : "Platform not supported"}');
      }
    } catch (e) {
      error = e.toString();
      debugPrint('DataWedge initialization error: $e');
    }
  }

  Future<void> scanBarcode({bool redirect = false}) async {
    try {
      if (gameState.settings.useBarcodesForUsers && !gameState.isEmulator) {
        await fdw?.scannerControl(true);
      } else {
        await fdw?.activateScanner(false);
        await fdw?.scannerControl(false);
        await fdw?.enableScanner(false);
      }
      if (!gameState.isEmulator) {
        listener(redirect: redirect);
      }
    } catch (e) {
      debugPrint('Barcode scan error: $e');
    }
  }

  Future<void> parseScanResult(ScanResult result, {required bool redirect}) async {
    if (isLoading) return;
    isLoading = true;
    clear();

    try {
      final body = ScanUserBody.fromJsonString(result.data);
      await restState.postUser(body);
      if (redirect && restState.status == Status.qualifying) {
        router.go(QualifyingScanPage.name);
      } else if (restState.status == Status.race) {
        router.go(RaceScanPage.name);
        if (gameState.racers.length < 2) {
          unawaited(initScanner());
        }
      }
    } catch (e) {
      unawaited(initScanner());
      if (e is FormatException) {
        unawaited(
          Fluttertoast.showToast(
            msg: 'Error with badge format',
            backgroundColor: const ZetaPrimitivesDark().red,
            textColor: Colors.white,
          ),
        );
        rethrow;
      }
    }
    isLoading = false;
  }

  void listener({bool redirect = false}) {
    fdw?.onScanResult.listen((ScanResult result) async {
      unawaited(parseScanResult(result, redirect: redirect));
    });
  }

  void clear() {
    fdw?.scannerControl(false);
    fdw?.enableScanner(false);
    fdw = null;
    error = null;
    isLoading = false;

    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
