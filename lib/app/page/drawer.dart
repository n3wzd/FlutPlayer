import 'package:flutbeat/app/collection/audio_playlist.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import './custom_list_select.dart';
import './equalizer.dart';
import '../component/dialog.dart';
import '../component/listtile.dart';
import '../component/text.dart';
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
          itemCount: 16,
          separatorBuilder: (BuildContext context, int index) => const Divider(
              color: ColorMaker.lightGreySeparator, height: 1, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            final widgetList = <Widget>[
              ListTileMaker.title(text: 'Custom Playlist'),
              ListTileMaker.content(
                  title: 'Export Playlist',
                  subtitle: 'creates new playlist from the current.',
                  onTap: () {
                    String listName = '';
                    bool showToolTip = false;
                    final textFieldStreamController =
                        StreamController<void>.broadcast();
                    DialogMaker.alertDialog(
                      context: context,
                      onPressed: () async {
                        bool? checkDBTableExist =
                            await audioPlayerKit.checkDBTableExist(listName);
                        if (checkDBTableExist != null) {
                          if (!checkDBTableExist) {
                            audioPlayerKit.exportCustomPlayList(listName);
                            return true;
                          }
                          showToolTip = true;
                          textFieldStreamController.add(null);
                          return false;
                        }
                        return true;
                      },
                      content: SizedBox(
                        height: 64,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 40,
                              child: TextField(
                                onChanged: (value) {
                                  listName = value;
                                  showToolTip = false;
                                  textFieldStreamController.add(null);
                                },
                                decoration: DecorationMaker.textField(),
                              ),
                            ),
                            StreamBuilder(
                              stream: textFieldStreamController.stream,
                              builder: (context, data) => SizedBox(
                                height: 24,
                                child: Center(
                                  child: TextMaker.normal(
                                      showToolTip
                                          ? 'This name already exists.'
                                          : '',
                                      fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ListTileMaker.content(
                  title: 'Import Playlist',
                  subtitle: 'loads playlist and place on the current.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return ListSelectPage(
                          audioPlayerKit: audioPlayerKit,
                        );
                      },
                    ));
                  }),
              ListTileMaker.content(
                  title: 'Export Database',
                  subtitle: 'export database file.',
                  onTap: () {
                    audioPlayerKit.exportDBFile();
                  }),
              ListTileMaker.title(text: 'Sort'),
              ListTileMaker.contentSwitch(
                title: 'Show Sort Button',
                subtitle: 'shows or hides sort button on play list sheet.',
                initialValue: Preference.showPlayListOrderButton,
                onChanged: (bool value) {
                  Preference.showPlayListOrderButton =
                      !Preference.showPlayListOrderButton;
                  Preference.save();
                },
              ),
              ListTileMaker.contentDropDownMenu<PlayListOrderMethod>(
                title: 'Sort Method',
                subtitle: 'sets how to sort play list.',
                initialSelection: Preference.playListOrderMethod,
                onSelected: (PlayListOrderMethod? value) {
                  if (value != null) {
                    Preference.playListOrderMethod = value;
                    Preference.save();
                  }
                },
                valueList: [
                  {'value': PlayListOrderMethod.title, 'label': 'title'},
                  {
                    'value': PlayListOrderMethod.modifiedDateTime,
                    'label': 'modifiedDateTime'
                  },
                ],
              ),
              ListTileMaker.title(text: 'Mashup'),
              ListTileMaker.contentSlider(
                title: 'Time to Transition',
                subtitle: 'changes time to transition next track.',
                initialValue: Preference.mashupTransitionTime.toDouble() / 1000,
                sliderMin: Preference.mashupTransitionTimeMin.toDouble() / 1000,
                sliderMax: Preference.mashupTransitionTimeMax.toDouble() / 1000,
                onChanged: (double value) {
                  Preference.mashupTransitionTime = value.toInt() * 1000;
                },
                onChangeEnd: (double value) {
                  Preference.save();
                },
                sliderDivisions: 10,
                sliderShowLabel: true,
              ),
              ListTileMaker.contentRangeSlider(
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
                onChangeEnd: (RangeValues values) {
                  Preference.save();
                },
                sliderDivisions: 10,
                sliderShowLabel: true,
              ),
              ListTileMaker.title(text: 'Equalizer'),
              ListTileMaker.content(
                  title: 'Equalizer',
                  subtitle: 'open equalizer page.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return EqualizerControls(
                            audioPlayerKit: audioPlayerKit);
                      },
                    ));
                  }),
              ListTileMaker.title(text: 'Other'),
              ListTileMaker.contentSwitch(
                title: 'Instantly Play',
                subtitle:
                    'plays first track instantly when first track loaded on play list.',
                initialValue: Preference.instantlyPlay,
                onChanged: (bool value) {
                  Preference.instantlyPlay = !Preference.instantlyPlay;
                  Preference.save();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'Shuffle Reload',
                subtitle: 'shuffles play list whenever play list updated.',
                initialValue: Preference.shuffleReload,
                onChanged: (bool value) {
                  Preference.shuffleReload = !Preference.shuffleReload;
                  Preference.save();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'Show List Delete Button',
                subtitle:
                    'shows or hides list delete button on play list sheet.',
                initialValue: Preference.showPlayListDeleteButton,
                onChanged: (bool value) {
                  Preference.showPlayListDeleteButton =
                      !Preference.showPlayListDeleteButton;
                  Preference.save();
                },
              ),
              ListTileMaker.contentSlider(
                title: 'Master Volumne',
                initialValue: Preference.volumeMasterRate,
                sliderMin: 0.0,
                sliderMax: 1.0,
                onChanged: (double value) {
                  audioPlayerKit.masterVolume = value;
                },
                onChangeEnd: (double value) {
                  Preference.save();
                },
              ),
            ];
            return widgetList[index];
          },
        ),
      );
}
