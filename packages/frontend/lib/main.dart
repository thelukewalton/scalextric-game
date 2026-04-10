import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/login/chose_mode_page.dart';
import 'package:scalextric/pages/login/qualifying_login.dart';
import 'package:scalextric/pages/login/race_login.dart';
import 'package:scalextric/pages/maintenance_page.dart';
import 'package:scalextric/pages/qualifying/practice_coutdown_page.dart';
import 'package:scalextric/pages/qualifying/practice_instructions_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_finish_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_scan_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_start_page.dart';
import 'package:scalextric/pages/race/race_countdown_page.dart';
import 'package:scalextric/pages/race/race_finish_page.dart';
import 'package:scalextric/pages/race/race_instructions_page.dart';
import 'package:scalextric/pages/race/race_page.dart';
import 'package:scalextric/pages/race/race_scan_page.dart';
import 'package:scalextric/pages/race/race_start_page.dart';
import 'package:scalextric/pages/settings/game_settings_page.dart';
import 'package:scalextric/pages/settings/settings_page.dart';
import 'package:scalextric/pages/settings/technical_settings_page.dart';
import 'package:scalextric/pages/settings/tools_page.dart';
import 'package:scalextric/state/dw_state.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:scalextric_shared/shared.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class DefaultBackground extends StatelessWidget {
  const DefaultBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: ColoredBox(color: Colors.black),
        ),
        Positioned(
          left: 0,
          top: -260,
          child: SvgPicture.asset(
            'assets/zebrahead.svg',
            height: 1460,
          ),
        ),
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final settings = await GameSettings.fromSavedPreferences();
  final GameState state;
  if (Platform.isAndroid) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    state = GameState(isEmulator: deviceInfo.isPhysicalDevice == false, settings: settings);
  } else {
    state = GameState(isEmulator: false, settings: settings);
  }

  runApp(MyApp(state: state));
}

CustomTransitionPage<void> wrapper(BuildContext context, GoRouterState state, Widget child, {double padding = 20}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder:
        (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      return FadeTransition(opacity: CurveTween(curve: Curves.easeInOut).animate(animation), child: child);
    },
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: context.watch<GameState>().settings.backgroundImage == ''
              ? const DefaultBackground()
              : Image.file(
                  File(context.watch<GameState>().settings.backgroundImage),
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
        ),
        Positioned(
          left: padding,
          right: padding,
          top: padding,
          bottom: padding,
          child: Scaffold(
            body: Center(child: child),
            backgroundColor: Colors.transparent,
          ),
        ),
        Positioned(
          left: 40,
          top: 40,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.watch<RestState>().status == Status.unknown ? Colors.red : Colors.green,
            ),
          ),
        ),
        Positioned(
          right: 40,
          top: 40,
          child: IconButton(
            onPressed: () {
              context.pushReplacement(LeaderBoardsPage.name);
              context.read<RestState>().fetchDriverStandings();
              context.read<RestState>().reset();
            },
            icon: const Icon(ZetaIcons.restart_alt),
            color: Colors.white.withAlpha(0.8 * 255 ~/ 1),
            iconSize: 60,
          ),
        ),
      ],
    ),
  );
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey();

// GoRouter configuration
final router = GoRouter(
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => SettingsPage.name,
      // pageBuilder: (context, state) => wrapper(context, state, const LeaderBoardsPage()),
    ),
    GoRoute(
      path: LeaderBoardsPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const LeaderBoardsPage()),
    ),
    GoRoute(
      path: QualifyingScanPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const QualifyingScanPage()),
    ),
    GoRoute(
      path: PracticeInstructionsPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const PracticeInstructionsPage()),
    ),
    GoRoute(
      path: QualifyingStartPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const QualifyingStartPage()),
    ),
    GoRoute(
      path: PracticeCountdownPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const PracticeCountdownPage()),
    ),
    GoRoute(
      path: QualifyingPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const QualifyingPage()),
    ),
    GoRoute(
      path: QualifyingFinishPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const QualifyingFinishPage()),
    ),
    GoRoute(
      path: SettingsPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const SettingsPage()),
    ),
    GoRoute(
      path: GameSettingsPage.name,
      pageBuilder: (context, state) =>
          wrapper(context, state, GameSettingsPage(settings: state.extra as GameSettings?)),
    ),
    GoRoute(
      path: TechnicalSettingsPage.name,
      pageBuilder: (context, state) =>
          wrapper(context, state, TechnicalSettingsPage(settings: state.extra as GameSettings?)),
    ),
    GoRoute(
      path: ToolsPage.name,
      pageBuilder: (context, state) => wrapper(context, state, ToolsPage(settings: state.extra as GameSettings?)),
    ),
    GoRoute(
      path: RaceScanPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RaceScanPage()),
    ),
    GoRoute(
      path: RaceStartPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RaceStartPage()),
    ),
    GoRoute(
      path: RaceCountdownPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RaceCountdownPage()),
    ),
    GoRoute(
      path: RacePage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RacePage()),
    ),
    GoRoute(
      path: RaceFinishPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RaceFinishPage()),
    ),
    GoRoute(
      path: RaceInstructionsPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RaceInstructionsPage()),
    ),
    GoRoute(
      path: ChooseModePage.name,
      pageBuilder: (context, state) => wrapper(context, state, const ChooseModePage()),
    ),
    GoRoute(
      path: QualifyingLoginPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const QualifyingLoginPage(), padding: 0),
    ),
    GoRoute(
      path: RaceLoginPage.name,
      pageBuilder: (context, state) => wrapper(context, state, const RaceLoginPage(), padding: 0),
    ),
    GoRoute(
      path: '/maintenance',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder:
            (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
          return FadeTransition(opacity: CurveTween(curve: Curves.easeInOut).animate(animation), child: child);
        },
        child: const MaintenancePage(),
      ),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.state});

  final GameState state;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => state),
        ChangeNotifierProvider(create: (context) => RestState(gameState: state)),
        ChangeNotifierProxyProvider<RestState, DataWedgeState>(
          create: (context) =>
              DataWedgeState(gameState: state, restState: Provider.of<RestState>(context, listen: false)),
          update: (context, restState, dwState) => dwState ?? DataWedgeState(gameState: state, restState: restState),
        ),
        ChangeNotifierProxyProvider2<RestState, GameState, WebSocketState>(
          create: (context) => WebSocketState(
            Provider.of<RestState>(context, listen: false),
            Provider.of<GameState>(context, listen: false),
          ),
          update: (context, restState, gameState, wsState) => wsState ?? WebSocketState(restState, gameState),
        ),
      ],
      child: ZetaProvider(
        initialThemeMode: ThemeMode.light,
        builder: (context, light, dark, themeMode) => MaterialApp.router(
          routerConfig: router,
          key: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'F1',
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(),
              bodyMedium: TextStyle(),
              bodySmall: TextStyle(),
            ).apply(bodyColor: Colors.white),
          ),
          builder: (_, child) => Scaffold(body: child ?? const Nothing()),
        ),
      ),
    );
  }
}
