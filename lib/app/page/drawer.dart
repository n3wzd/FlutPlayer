import 'package:flutbeat/app/collection/audio_playlist.dart';
import 'package:flutter/material.dart';

import '../page/list_select_page.dart';
import '../component/dialog.dart';
import '../component/listtile.dart';
import '../collection/audio_player.dart';
import '../collection/preference.dart';
import '../style/decoration.dart';
import '../style/color.dart';

class PageDrawer extends StatelessWidget {
  const PageDrawer({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: ColorMaker.black,
        child: ListView.separated(
          itemCount: 12,
          separatorBuilder: (BuildContext context, int index) => const Divider(
              color: ColorMaker.lightGreySeparator, height: 1, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return ListTileMaker.title(text: 'Play List');
            } else if (index == 1) {
              return ListTileMaker.content(
                  title: 'Export',
                  subtitle: 'creates new playlist from the current.',
                  onTap: () {
                    String listName = '';
                    DialogMaker.alertDialog(
                      context: context,
                      onPressed: () {
                        audioPlayerKit.exportCustomPlayList(listName);
                      },
                      content: TextField(
                        onChanged: (value) {
                          listName = value;
                        },
                        decoration: DecorationMaker.textField(),
                      ),
                    );
                  });
            } else if (index == 2) {
              return ListTileMaker.content(
                  title: 'Import',
                  subtitle: 'loads playlist and place on the current.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return ListSelectPage(
                          audioPlayerKit: audioPlayerKit,
                        );
                      },
                    ));
                  });
            } else if (index == 3) {
              return ListTileMaker.title(text: 'Sort');
            } else if (index == 4) {
              return ListTileMaker.contentSwitch(
                title: 'Show Sort Button',
                subtitle: 'shows or hides sort button on play list sheet.',
                initialValue: Preference.showPlayListOrderButton,
                onChanged: (bool value) {
                  Preference.showPlayListOrderButton =
                      !Preference.showPlayListOrderButton;
                },
              );
            } else if (index == 5) {
              return ListTileMaker.contentDropDownMenu<PlayListOrderMethod>(
                title: 'Sort Method',
                subtitle: 'sets how to sort play list.',
                initialSelection: Preference.playListOrderMethod,
                onSelected: (PlayListOrderMethod? value) {
                  if (value != null) {
                    Preference.playListOrderMethod = value;
                  }
                },
                valueList: [
                  {'value': PlayListOrderMethod.title, 'label': 'title'},
                  {
                    'value': PlayListOrderMethod.modifiedDateTime,
                    'label': 'modifiedDateTime'
                  },
                ],
              );
            } else if (index == 6) {
              return ListTileMaker.title(text: 'Mashup');
            } else if (index == 7) {
              return ListTileMaker.contentSlider(
                title: 'Time to Transition',
                subtitle: 'changes time to transition next track.',
                initialValue: Preference.mashupTransitionTime.toDouble() / 1000,
                sliderMin: Preference.mashupTransitionTimeMin.toDouble() / 1000,
                sliderMax: Preference.mashupTransitionTimeMax.toDouble() / 1000,
                onChanged: (double value) {
                  Preference.mashupTransitionTime = value.toInt() * 1000;
                },
                sliderDivisions: 10,
                sliderShowLabel: true,
              );
            } else if (index == 8) {
              return ListTileMaker.contentRangeSlider(
                title: 'Time to Trigger Next',
                subtitle: 'changes random time range to trigger next track.',
                initialValues: RangeValues(
                    Preference.mashupNextTriggerMinTime.toDouble() / 1000,
                    Preference.mashupNextTriggerMaxTime.toDouble() / 1000),
                sliderMin:
                    Preference.mashupNextTriggerTimeRangeMin.toDouble() / 1000,
                sliderMax:
                    Preference.mashupNextTriggerTimeRangeMax.toDouble() / 1000,
                onChanged: (RangeValues values) {
                  Preference.mashupNextTriggerMinTime =
                      values.start.toInt() * 1000;
                  Preference.mashupNextTriggerMaxTime =
                      values.end.toInt() * 1000;
                },
                sliderDivisions: 10,
                sliderShowLabel: true,
              );
            } else if (index == 9) {
              return ListTileMaker.title(text: 'Other');
            } else if (index == 10) {
              return ListTileMaker.contentSwitch(
                title: 'Instantly Play',
                subtitle:
                    'plays first track instantly when first track loaded on play list.',
                initialValue: Preference.instantlyPlay,
                onChanged: (bool value) {
                  Preference.instantlyPlay = !Preference.instantlyPlay;
                },
              );
            } else {
              return ListTileMaker.contentSwitch(
                title: 'Shuffle Reload',
                subtitle: 'shuffles play list whenever play list updated.',
                initialValue: Preference.shuffleReload,
                onChanged: (bool value) {
                  Preference.shuffleReload = !Preference.shuffleReload;
                },
              );
            }
          },
        ),
      );
}
