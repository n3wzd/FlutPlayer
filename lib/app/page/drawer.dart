import 'package:flutbeat/app/collection/audio_playlist.dart';
import 'package:flutter/material.dart';

import './tag_select.dart';
import './tag_export_dialog.dart';
import './equalizer.dart';
import '../component/listtile.dart';
import '../collection/audio_player.dart';
import '../collection/preference.dart';
import '../style/color.dart';
import '../global.dart' as global;

class PageDrawer extends StatelessWidget {
  const PageDrawer({Key? key, required this.audioPlayerKit}) : super(key: key);
  final AudioPlayerKit audioPlayerKit;

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: ColorMaker.black,
        child: ListView.separated(
          itemCount: 24,
          separatorBuilder: (BuildContext context, int index) => const Divider(
              color: ColorMaker.lightGreySeparator, height: 1, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            final widgetList = <Widget>[
              ListTileMaker.title(text: 'Tag'),
              ListTileMaker.content(
                  title: 'Export Tag',
                  subtitle:
                      'creates new tag and add current tracks on the tag.',
                  onTap: () {
                    tagExportDialog(context, audioPlayerKit);
                  }),
              ListTileMaker.content(
                  title: 'Import Tag',
                  subtitle:
                      'loads tracks using by tag and place on the current list.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return TagSelectPage(
                          audioPlayerKit: audioPlayerKit,
                        );
                      },
                    ));
                  }),
              ListTileMaker.content(
                  title: '_Export Database_',
                  subtitle: 'export database file.',
                  onTap: () {
                    audioPlayerKit.exportDBFile();
                  }),
              ListTileMaker.content(
                  title: '_Import Database_',
                  subtitle:
                      'import database file. name of the file is must "audio_track.db".',
                  onTap: () {
                    audioPlayerKit.importDBFile();
                  }),
              ListTileMaker.content(
                  title: '_Export All Tag to csv_',
                  subtitle: 'export all tag to csv file.',
                  onTap: () {
                    audioPlayerKit.customTableDatabaseToCsv();
                  }),
              ListTileMaker.content(
                  title: '_Import Tag from csv_',
                  subtitle: 'import tag from csv file.',
                  onTap: () {
                    audioPlayerKit.customTableCsvToDatabase();
                  }),
              ListTileMaker.title(text: 'Sort'),
              ListTileMaker.contentSwitch(
                title: 'Show Sort Button',
                subtitle: 'shows or hides sort button on list sheet.',
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
                initialValue: Preference.mashupTransitionTime.toDouble(),
                sliderMin: Preference.mashupTransitionTimeMin.toDouble(),
                sliderMax: Preference.mashupTransitionTimeMax.toDouble(),
                onChanged: (double value) {
                  Preference.mashupTransitionTime = value.toInt();
                },
                onChangeEnd: (double value) {
                  Preference.save();
                },
                sliderDivisions: 9,
                sliderShowLabel: true,
              ),
              ListTileMaker.contentRangeSlider(
                title: 'Time to Trigger Next',
                subtitle: 'changes random time range to trigger next track.',
                initialValues: RangeValues(
                    Preference.mashupNextTriggerMinTime.toDouble(),
                    Preference.mashupNextTriggerMaxTime.toDouble()),
                sliderMin: Preference.mashupNextTriggerTimeRangeMin.toDouble(),
                sliderMax: Preference.mashupNextTriggerTimeRangeMax.toDouble(),
                onChanged: (RangeValues values) {
                  Preference.mashupNextTriggerMinTime = values.start.toInt();
                  Preference.mashupNextTriggerMaxTime = values.end.toInt();
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
              ListTileMaker.title(text: 'Visualizer'),
              ListTileMaker.contentSwitch(
                title: 'Visualizer',
                subtitle: 'enable visualizer.',
                initialValue: Preference.enableVisualizer,
                onChanged: (bool value) {
                  Preference.enableVisualizer = !Preference.enableVisualizer;
                  Preference.save();
                  global.rebuildAll();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'Background',
                subtitle: 'enable background.',
                initialValue: Preference.enableBackground,
                onChanged: (bool value) {
                  Preference.enableBackground = !Preference.enableBackground;
                  Preference.save();
                  global.rebuildAll();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'NCS Logo',
                subtitle: 'enable NCS Logo.',
                initialValue: Preference.enableNCSLogo,
                onChanged: (bool value) {
                  Preference.enableNCSLogo = !Preference.enableNCSLogo;
                  Preference.save();
                  global.rebuildAll();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'Full Screen',
                subtitle: 'enter full scrren.',
                initialValue: Preference.enableFullScreen,
                onChanged: (bool value) {
                  Preference.enableFullScreen = !Preference.enableFullScreen;
                  Preference.save();
                  global.rebuildAll();
                },
              ),
              ListTileMaker.title(text: 'Other'),
              ListTileMaker.contentSwitch(
                title: 'Instantly Play',
                subtitle:
                    'plays first track instantly when first track loaded on list.',
                initialValue: Preference.instantlyPlay,
                onChanged: (bool value) {
                  Preference.instantlyPlay = !Preference.instantlyPlay;
                  Preference.save();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'Shuffle Reload',
                subtitle: 'shuffles list whenever list updated.',
                initialValue: Preference.shuffleReload,
                onChanged: (bool value) {
                  Preference.shuffleReload = !Preference.shuffleReload;
                  Preference.save();
                },
              ),
              ListTileMaker.contentSwitch(
                title: 'Show Delete Button',
                subtitle: 'shows or hides list delete button on list sheet.',
                initialValue: Preference.showPlayListDeleteButton,
                onChanged: (bool value) {
                  Preference.showPlayListDeleteButton =
                      !Preference.showPlayListDeleteButton;
                  Preference.save();
                },
              ),
              /*ListTileMaker.contentSlider(
                title: 'Master Volume',
                initialValue: Preference.volumeMasterRate,
                sliderMin: 0.0,
                sliderMax: 1.0,
                onChanged: (double value) {
                  audioPlayerKit.masterVolume = value;
                },
                onChangeEnd: (double value) {
                  Preference.save();
                },
              ),*/
            ];
            return widgetList[index];
          },
        ),
      );
}
