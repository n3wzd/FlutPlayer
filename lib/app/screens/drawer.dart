import 'package:flutter/material.dart';
import '../global.dart' as global;
import './tag_select.dart';
import './background_group_list.dart';
import './mix_select.dart';
import '../components/tag_export_dialog.dart';
import '../models/api.dart';
import '../widgets/listtile.dart';
import '../widgets/text.dart';
import '../widgets/dialog.dart';
import '../utils/database_manager.dart';
import '../utils/preference.dart';
import '../utils/stream_controller.dart';
import '../utils/background_manager.dart';
import '../models/color.dart';
import '../models/enum.dart';

class PageDrawer extends StatelessWidget {
  const PageDrawer({Key? key}) : super(key: key);

  void apiProcess(
      BuildContext context, Future<APIResult> Function() process) async {
    APIResult res = await process();
    if (context.mounted) {
      DialogFactory.alertDialog(
        context: context,
        onPressed: () async {
          return true;
        },
        content: TextFactory.text(
            res.success ? 'Success!' : 'Failed!\n${res.msg}',
            allowLineBreak: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: ColorPalette.black,
        child: ListView.separated(
          itemCount: 27,
          separatorBuilder: (BuildContext context, int index) => const Divider(
              color: ColorPalette.lightGreySeparator, height: 1, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            final widgetList = <Widget>[
              ListTileFactory.title(text: 'Tag & Mix'),
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
              ListTileFactory.content(
                  title: 'Import Custom Mix',
                  subtitle:
                      'import custom mix json data and play it.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const MixSelectPage();
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
                sliderDivisions: 8,
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
              ListTileFactory.title(text: 'Background'),
              ListTileFactory.contentSwitch(
                title: 'Enable Background',
                subtitle: 'enable background.',
                initialValue: Preference.enableBackground,
                onChanged: (bool value) {
                  Preference.enableBackground = !Preference.enableBackground;
                  Preference.save('enableBackground');
                  AudioStreamController.enabledBackground.add(null);
                },
              ),
              ListTileFactory.contentDropDownMenu<BackgroundMethod>(
                title: 'Background Method',
                subtitle:
                    'normal: show default background.\nrandom: show random background in the directory.\nspecific: show custom background each track.',
                initialSelection: Preference.backgroundMethod,
                onSelected: (BackgroundMethod? value) {
                  if (value != null) {
                    Preference.backgroundMethod = value;
                    Preference.save('backgroundMethod');
                    AudioStreamController.backgroundFile.add(null);
                  }
                },
                valueList: [
                  {'value': BackgroundMethod.normal, 'label': 'normal'},
                  {'value': BackgroundMethod.random, 'label': 'random'},
                  {'value': BackgroundMethod.specific, 'label': 'specific'},
                ],
              ),
              ListTileFactory.content(
                title: 'Directory Path',
                subtitle: 'open background directory page.',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const BackgroundGroupPage();
                      })
                  );
                }
              ),
              ListTileFactory.contentSwitch(
                title: 'Enable Background Transition',
                subtitle: 'background changes regardless of the currently playing track.',
                initialValue: Preference.enableBackgroundTransition,
                onChanged: (bool value) {
                  Preference.enableBackgroundTransition = !Preference.enableBackgroundTransition;
                  Preference.save('enableBackgroundTransition');
                  BackgroundTransitionTimer.instance.update(value);
                },
              ),
              ListTileFactory.contentRangeSlider(
                title: 'Time to Trigger Next',
                subtitle: 'changes random time range to trigger next background.',
                initialValues: RangeValues(
                    Preference.backgroundNextTriggerMinTime.toDouble(),
                    Preference.backgroundNextTriggerMaxTime.toDouble()),
                sliderMin:
                    PreferenceConstant.backgroundNextTriggerTimeRangeMin.toDouble(),
                sliderMax:
                    PreferenceConstant.backgroundNextTriggerTimeRangeMax.toDouble(),
                onChanged: (RangeValues values) {
                  Preference.backgroundNextTriggerMinTime = values.start.toInt();
                  Preference.backgroundNextTriggerMaxTime = values.end.toInt();
                },
                onChangeEnd: (RangeValues values) {
                  Preference.save('backgroundNextTriggerMinTime');
                  Preference.save('backgroundNextTriggerMaxTime');
                },
                sliderDivisions: 8,
                sliderShowLabel: true,
              ),
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
                title: 'Random Visualizer Color',
                subtitle: 'visualizer is updated random color when reloaded.',
                initialValue: Preference.randomColorVisualizer,
                onChanged: (bool value) {
                  Preference.randomColorVisualizer = !Preference.randomColorVisualizer;
                  Preference.save('randomColorVisualizer');
                  global.setVisualizerColor();
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
                  apiProcess(context, DatabaseManager.instance.exportDBFile);
                },
              ),
              ListTileFactory.content(
                title: 'Import Database',
                subtitle: 'import database file.',
                onTap: () {
                  apiProcess(context, DatabaseManager.instance.importDBFile);
                },
              ),
              ListTileFactory.content(
                title: 'Export All Tag to csv',
                subtitle: 'export all tag to csv file.',
                onTap: () {
                  apiProcess(context, DatabaseManager.instance.tagDBToCsv);
                },
              ),
              ListTileFactory.content(
                title: 'Import Tags from csv',
                subtitle: 'import tag from csv file.',
                onTap: () {
                  apiProcess(context, DatabaseManager.instance.tagCsvToDB);
                },
              )
            ];
            return widgetList[index];
          },
        ),
      );
}
