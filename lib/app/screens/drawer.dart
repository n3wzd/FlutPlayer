import 'package:flutbeat/app/utils/stream_controller.dart';
import 'package:flutter/material.dart';

import './tag_select.dart';
import './equalizer.dart';
import '../components/tag_export_dialog.dart';
import '../widgets/listtile.dart';
import '../utils/database_manager.dart';
import '../utils/preference.dart';
import '../models/color.dart';
import '../models/play_list_order.dart';

class PageDrawer extends StatelessWidget {
  const PageDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: ColorPalette.black,
        child: ListView.separated(
          itemCount: 24,
          separatorBuilder: (BuildContext context, int index) => const Divider(
              color: ColorPalette.lightGreySeparator, height: 1, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            final widgetList = <Widget>[
              ListTileFactory.title(text: 'Tag'),
              ListTileFactory.content(
                  title: 'Export Tag',
                  subtitle:
                      'creates new tag and add current tracks on the tag.',
                  onTap: () {
                    tagExportDialog(context);
                  }),
              ListTileFactory.content(
                  title: 'Import Tag',
                  subtitle:
                      'loads tracks using by tag and place on the current list.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const TagSelectPage();
                      },
                    ));
                  }),
              ListTileFactory.title(text: 'Sort'),
              ListTileFactory.contentSwitch(
                title: 'Show Sort Button',
                subtitle: 'shows or hides sort button on list sheet.',
                initialValue: Preference.showPlayListOrderButton,
                onChanged: (bool value) {
                  Preference.showPlayListOrderButton =
                      !Preference.showPlayListOrderButton;
                  Preference.save('showPlayListOrderButton');
                },
              ),
              ListTileFactory.contentDropDownMenu<PlayListOrderMethod>(
                title: 'Sort Method',
                subtitle: 'sets how to sort play list.',
                initialSelection: Preference.playListOrderMethod,
                onSelected: (PlayListOrderMethod? value) {
                  if (value != null) {
                    Preference.playListOrderMethod = value;
                    Preference.save('playListOrderMethod');
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
              ListTileFactory.title(text: 'Mashup'),
              ListTileFactory.contentSlider(
                title: 'Time to Transition',
                subtitle: 'changes time to transition next track.',
                initialValue: Preference.mashupTransitionTime.toDouble(),
                sliderMin:
                    PreferenceConstant.mashupTransitionTimeMin.toDouble(),
                sliderMax:
                    PreferenceConstant.mashupTransitionTimeMax.toDouble(),
                onChanged: (double value) {
                  Preference.mashupTransitionTime = value.toInt();
                },
                onChangeEnd: (double value) {
                  Preference.save('mashupTransitionTime');
                },
                sliderDivisions: 9,
                sliderShowLabel: true,
              ),
              ListTileFactory.contentRangeSlider(
                title: 'Time to Trigger Next',
                subtitle: 'changes random time range to trigger next track.',
                initialValues: RangeValues(
                    Preference.mashupNextTriggerMinTime.toDouble(),
                    Preference.mashupNextTriggerMaxTime.toDouble()),
                sliderMin:
                    PreferenceConstant.mashupNextTriggerTimeRangeMin.toDouble(),
                sliderMax:
                    PreferenceConstant.mashupNextTriggerTimeRangeMax.toDouble(),
                onChanged: (RangeValues values) {
                  Preference.mashupNextTriggerMinTime = values.start.toInt();
                  Preference.mashupNextTriggerMaxTime = values.end.toInt();
                },
                onChangeEnd: (RangeValues values) {
                  Preference.save('mashupNextTriggerMinTime');
                  Preference.save('mashupNextTriggerMaxTime');
                },
                sliderDivisions: 10,
                sliderShowLabel: true,
              ),
              ListTileFactory.title(text: 'Equalizer'),
              ListTileFactory.content(
                  title: 'Equalizer',
                  subtitle: 'open equalizer page.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const EqualizerControls();
                      },
                    ));
                  }),
              ListTileFactory.title(text: 'Visualizer'),
              ListTileFactory.contentSwitch(
                title: 'Visualizer',
                subtitle: 'enable visualizer.',
                initialValue: Preference.enableVisualizer,
                onChanged: (bool value) {
                  Preference.enableVisualizer = !Preference.enableVisualizer;
                  Preference.save('enableVisualizer');
                  AudioStreamController.enabledVisualizer.add(null);
                },
              ),
              ListTileFactory.contentSwitch(
                title: 'Background',
                subtitle: 'enable background.',
                initialValue: Preference.enableBackground,
                onChanged: (bool value) {
                  Preference.enableBackground = !Preference.enableBackground;
                  Preference.save('enableBackground');
                  AudioStreamController.enabledBackground.add(null);
                },
              ),
              ListTileFactory.contentSwitch(
                title: 'NCS Logo',
                subtitle: 'enable NCS Logo.',
                initialValue: Preference.enableNCSLogo,
                onChanged: (bool value) {
                  Preference.enableNCSLogo = !Preference.enableNCSLogo;
                  Preference.save('enableNCSLogo');
                  AudioStreamController.enabledNCSLogo.add(null);
                },
              ),
              ListTileFactory.title(text: 'Other'),
              ListTileFactory.contentSwitch(
                title: 'Instantly Play',
                subtitle:
                    'plays first track instantly when first track loaded on list.',
                initialValue: Preference.instantlyPlay,
                onChanged: (bool value) {
                  Preference.instantlyPlay = !Preference.instantlyPlay;
                  Preference.save('instantlyPlay');
                },
              ),
              ListTileFactory.contentSwitch(
                title: 'Shuffle Reload',
                subtitle: 'shuffles list whenever list updated.',
                initialValue: Preference.shuffleReload,
                onChanged: (bool value) {
                  Preference.shuffleReload = !Preference.shuffleReload;
                  Preference.save('shuffleReload');
                },
              ),
              ListTileFactory.contentSwitch(
                title: 'Show Delete Button',
                subtitle: 'shows or hides list delete button on list sheet.',
                initialValue: Preference.showPlayListDeleteButton,
                onChanged: (bool value) {
                  Preference.showPlayListDeleteButton =
                      !Preference.showPlayListDeleteButton;
                  Preference.save('showPlayListDeleteButton');
                },
              ),
              ListTileFactory.title(text: 'Advance'),
              ListTileFactory.content(
                  title: 'Export Database',
                  subtitle: 'export database file.',
                  onTap: () {
                    DatabaseManager.instance.exportDBFile();
                  }),
              ListTileFactory.content(
                  title: 'Import Database',
                  subtitle:
                      'import database file. name of the file is must "audio_track.db".',
                  onTap: () {
                    DatabaseManager.instance.importDBFile();
                  }),
              ListTileFactory.content(
                  title: 'Export All Tag to csv',
                  subtitle: 'export all tag to csv file.',
                  onTap: () {
                    DatabaseManager.instance.tagDBToCsv();
                  }),
              ListTileFactory.content(
                  title: 'Import Tag from csv',
                  subtitle: 'import tag from csv file.',
                  onTap: () {
                    DatabaseManager.instance.tagCsvToDB();
                  }),
              /*ListTileFactory.contentSlider(
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