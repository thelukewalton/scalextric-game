import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/card.dart';
import 'package:scalextric/components/formatted_duration.dart';
import 'package:scalextric/components/leaderboard_row.dart';

import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/models/user.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

enum LapType { lap, overall }

extension on PlaceChange {
  Color get arrowColor => this == PlaceChange.up
      ? Colors.green
      : this == PlaceChange.down
          ? Colors.red
          : Colors.black;
}

extension on LapType {
  Color get color => this == LapType.lap ? Colors.purple : Colors.white;
}

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key, this.lapType = LapType.overall});
  final LapType lapType;

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> scroll({bool down = true}) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (mounted) {
      await _scrollController.animateTo(
        down ? _scrollController.position.maxScrollExtent : 0,
        duration: context.read<RestState>().lapLeaderboard != null
            ? Duration(seconds: context.read<RestState>().lapLeaderboard!.length - 8)
            : Duration.zero,
        curve: Curves.linear,
      );
    }
    unawaited(scroll(down: !down));
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      fontFamily: 'Titillium',
      color: Colors.white,
    );
    return Hero(
      tag: widget.lapType.name,
      child: Consumer<RestState>(
        builder: (context, state, child) {
          late final int fastest;

          if (widget.lapType == LapType.overall) {
            fastest = state.overallLeaderboard == null || state.overallLeaderboard!.isEmpty
                ? 0
                : state.overallLeaderboard!.first.overallTime ?? 0;
          } else {
            fastest = state.lapLeaderboard == null || state.lapLeaderboard!.isEmpty
                ? 0
                : state.lapLeaderboard!.first.fastestLap ?? 0;
          }

          return TranslucentCard(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.lapType == LapType.overall ? 'Driver Standings' : 'Fastest Lap',
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w400, color: Colors.white),
                      ),
                      Row(
                        children: [
                          if (widget.lapType == LapType.overall)
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: Text(
                                  'TRIES',
                                  style: textStyle.apply(fontStyle: FontStyle.italic, color: Colors.white),
                                ),
                              ),
                            ),
                          if (widget.lapType == LapType.overall)
                            SizedBox(
                              width: 50,
                              child: Center(
                                child: Text(
                                  'GAP',
                                  style: textStyle.apply(fontStyle: FontStyle.italic, color: Colors.white),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 120,
                            child: Center(
                              child: Text(
                                'TIME',
                                style: textStyle.apply(fontStyle: FontStyle.italic, color: Colors.white),
                              ),
                            ),
                          ),
                        ].gap(24),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.lapType == LapType.overall
                          ? state.overallLeaderboard?.length
                          : state.lapLeaderboard?.length,
                      shrinkWrap: true,
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        final element = widget.lapType == LapType.overall
                            ? state.overallLeaderboard![index]
                            : state.lapLeaderboard![index];

                        final dataToShow = widget.lapType == LapType.overall ? element.overallTime : element.fastestLap;

                        final isCurrentUser = element.id == context.read<GameState>().loggedInUser?.id;
                        late final int gap;
                        if (dataToShow != null && index != 0) {
                          gap = dataToShow - fastest;
                        } else {
                          gap = 0;
                        }

                        final highlightColor = isCurrentUser
                            ? (element.change ?? PlaceChange.none).arrowColor
                            : index == 0
                                ? widget.lapType.color
                                : null;
                        return Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  context.read<RestState>().setSelectedUser(element);
                                  Navigator.of(context).pushNamed('/user');
                                },
                                onLongPress: () {
                                  showZetaDialog(
                                    context,
                                    message: 'Delete user?',
                                    primaryButtonLabel: 'Confirm',
                                    secondaryButtonLabel: 'Cancel',
                                    onPrimaryButtonPressed: () async {
                                      await context.read<RestState>().removeUser(element.id);
                                      if (context.mounted) Navigator.of(context).pop();
                                    },
                                    onSecondaryButtonPressed: () => Navigator.of(context).pop(),
                                  );
                                },
                                child: LeaderboardRow(
                                  index: index + 1,
                                  highlightColor: highlightColor,
                                  time: dataToShow ?? 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            element.name.trim().toUpperCase(),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: element.change != null && element.change != PlaceChange.none
                                                ? RotatedBox(
                                                    quarterTurns: element.change == PlaceChange.up ? 3 : 1,
                                                    child: Icon(
                                                      ZetaIcons.chevron_right,
                                                      size: 38,
                                                      color: isCurrentUser ? Colors.white : element.change?.arrowColor,
                                                    ),
                                                  )
                                                : const Nothing(),
                                          ),
                                          if (widget.lapType == LapType.overall)
                                            SizedBox(
                                              width: 70,
                                              child: Center(
                                                child: Text(
                                                  '${element.attempts}',
                                                  style: textStyle.copyWith(
                                                    color: highlightColor?.onColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (widget.lapType == LapType.overall)
                                            SizedBox(
                                              width: 100,
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: dataToShow != null && (index == 0)
                                                    ? Text(
                                                        'LEADER',
                                                        style: textStyle.copyWith(
                                                          color: highlightColor?.onColor,
                                                        ),
                                                      )
                                                    : dataToShow != null && index != 0
                                                        ? FormattedGap(
                                                            Duration(milliseconds: gap),
                                                            style: textStyle.copyWith(
                                                              color: Zeta.of(context).colors.primitives.warm.shade50,
                                                            ),
                                                          )
                                                        : const Nothing(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ].gap(2),
                        ).paddingBottom(8);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
