import 'package:flutter/material.dart';

import '../app_state.dart';
import './background_group_list.dart';
import './equalizer.dart';
import './mix_select.dart';
import './tag_select.dart';
import '../models/api.dart';
import '../models/color.dart';
import '../models/enum.dart';
import '../utils/database_manager.dart';
import '../utils/preference.dart';
import '../utils/stream_controller.dart';
import '../widgets/dialog.dart';
import '../widgets/listtile.dart';
import '../widgets/text.dart';

class PageDrawer extends StatelessWidget {
  const PageDrawer({super.key});

  void apiProcess(
    BuildContext context,
    Future<APIResult> Function() process,
  ) async {
    APIResult res = await process();
    if (context.mounted) {
      DialogFactory.alertDialog(
        context: context,
        onPressed: () async {
          return true;
        },
        content: TextFactory.text(
          res.success ? 'Success!\n${res.msg}' : 'Failed!\n${res.msg}',
          allowLineBreak: true,
        ),
      );
    }
  }

  List<Widget> _drawerItems(BuildContext context) => [
    ListTileFactory.title(text: 'Tag & Mix'),
    ListTileFactory.content(
      title: 'Tag Root Path',
      subtitle: Preference.tagRootPath.isEmpty
          ? 'select tag csv root path.'
          : Preference.tagRootPath,
      onTap: () {
        apiProcess(context, DatabaseManager.instance.selectTagRootPath);
      },
    ),
    ListTileFactory.content(
      title: 'Resource Root Path',
      subtitle: Preference.resourceRootPath.isEmpty
          ? 'select music resource root path.'
          : Preference.resourceRootPath,
      onTap: () {
        apiProcess(context, DatabaseManager.instance.selectResourceRootPath);
      },
    ),
    ListTileFactory.content(
      title: 'Sync Resource Database',
      subtitle: 'scan resource root and update track database.',
      onTap: () {
        apiProcess(context, DatabaseManager.instance.syncResourceDatabase);
      },
    ),
    ListTileFactory.content(
      title: 'Load Tag',
      subtitle: 'loads tracks from tag csv files.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return const TagSelectPage();
            },
          ),
        );
      },
    ),
    ListTileFactory.content(
      title: 'Import Custom Mix',
      subtitle: 'import custom mix json data and play it.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return const MixSelectPage();
            },
          ),
        );
      },
    ),
    ListTileFactory.title(text: 'Sort'),
    ListTileFactory.contentSwitch(
      title: 'Show Sort Button',
      subtitle: 'shows or hides sort button on list sheet.',
      initialValue: Preference.showPlayListOrderButton,
      onChanged: (bool value) {
        Preference.showPlayListOrderButton =
            !Preference.showPlayListOrderButton;
        Preference.save(PreferenceKey.showPlayListOrderButton);
      },
    ),
    ListTileFactory.contentDropDownMenu<PlayListOrderMethod>(
      title: 'Sort Method',
      subtitle: 'sets how to sort play list.',
      initialSelection: Preference.playListOrderMethod,
      onSelected: (PlayListOrderMethod? value) {
        if (value != null) {
          Preference.playListOrderMethod = value;
          Preference.save(PreferenceKey.playListOrderMethod);
        }
      },
      valueList: [
        {'value': PlayListOrderMethod.title, 'label': 'title'},
        {
          'value': PlayListOrderMethod.modifiedDateTime,
          'label': 'modifiedDateTime',
        },
      ],
    ),
    ListTileFactory.title(text: 'Mashup'),
    ListTileFactory.contentSlider(
      title: 'Time to Transition',
      subtitle: 'changes time to transition next track.',
      initialValue: Preference.mashupTransitionTime.toDouble(),
      sliderMin: PreferenceConstant.mashupTransitionTimeMin.toDouble(),
      sliderMax: PreferenceConstant.mashupTransitionTimeMax.toDouble(),
      onChanged: (double value) {
        Preference.mashupTransitionTime = value.toInt();
      },
      onChangeEnd: (double value) {
        Preference.save(PreferenceKey.mashupTransitionTime);
      },
      sliderDivisions: 8,
      sliderShowLabel: true,
    ),
    ListTileFactory.contentRangeSlider(
      title: 'Time to Trigger Next',
      subtitle: 'changes random time range to trigger next track.',
      initialValues: RangeValues(
        Preference.mashupNextTriggerMinTime.toDouble(),
        Preference.mashupNextTriggerMaxTime.toDouble(),
      ),
      sliderMin: PreferenceConstant.mashupNextTriggerTimeRangeMin.toDouble(),
      sliderMax: PreferenceConstant.mashupNextTriggerTimeRangeMax.toDouble(),
      onChanged: (RangeValues values) {
        Preference.mashupNextTriggerMinTime = values.start.toInt();
        Preference.mashupNextTriggerMaxTime = values.end.toInt();
      },
      onChangeEnd: (RangeValues values) {
        Preference.save(PreferenceKey.mashupNextTriggerMinTime);
        Preference.save(PreferenceKey.mashupNextTriggerMaxTime);
      },
      sliderDivisions: 10,
      sliderShowLabel: true,
    ),
    ListTileFactory.title(text: 'Equalizer'),
    ListTileFactory.content(
      title: 'Equalizer',
      subtitle: 'open equalizer page.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return const EqualizerControls();
            },
          ),
        );
      },
    ),
    ListTileFactory.title(text: 'Background'),
    ListTileFactory.contentSwitch(
      title: 'Enable Background',
      subtitle: 'enable background.',
      initialValue: Preference.enableBackground,
      onChanged: (bool value) {
        Preference.enableBackground = !Preference.enableBackground;
        Preference.save(PreferenceKey.enableBackground);
        AudioStreamController.emitEnabledBackgroundChanged();
      },
    ),
    ListTileFactory.content(
      title: 'Directory Path',
      subtitle: 'open background directory page.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return const BackgroundGroupPage();
            },
          ),
        );
      },
    ),
    ListTileFactory.title(text: 'Visualizer'),
    ListTileFactory.contentSwitch(
      title: 'Visualizer',
      subtitle: 'enable visualizer.',
      initialValue: Preference.enableVisualizer,
      onChanged: (bool value) {
        Preference.enableVisualizer = !Preference.enableVisualizer;
        Preference.save(PreferenceKey.enableVisualizer);
        AudioStreamController.emitEnabledVisualizerChanged();
      },
    ),
    ListTileFactory.contentSwitch(
      title: 'Random Visualizer Color',
      subtitle: 'visualizer is updated random color when reloaded.',
      initialValue: Preference.randomColorVisualizer,
      onChanged: (bool value) {
        Preference.randomColorVisualizer = !Preference.randomColorVisualizer;
        Preference.save(PreferenceKey.randomColorVisualizer);
        AppState.instance.updateVisualizerColor();
      },
    ),
    ListTileFactory.contentSwitch(
      title: 'NCS Logo',
      subtitle: 'enable NCS Logo.',
      initialValue: Preference.enableNCSLogo,
      onChanged: (bool value) {
        Preference.enableNCSLogo = !Preference.enableNCSLogo;
        Preference.save(PreferenceKey.enableNCSLogo);
        AudioStreamController.emitEnabledNCSLogoChanged();
      },
    ),
    ListTileFactory.title(text: 'Other'),
    ListTileFactory.contentSwitch(
      title: 'Instantly Play',
      subtitle: 'plays first track instantly when first track loaded on list.',
      initialValue: Preference.instantlyPlay,
      onChanged: (bool value) {
        Preference.instantlyPlay = !Preference.instantlyPlay;
        Preference.save(PreferenceKey.instantlyPlay);
      },
    ),
    ListTileFactory.contentSwitch(
      title: 'Shuffle Reload',
      subtitle: 'shuffles list whenever list updated.',
      initialValue: Preference.shuffleReload,
      onChanged: (bool value) {
        Preference.shuffleReload = !Preference.shuffleReload;
        Preference.save(PreferenceKey.shuffleReload);
      },
    ),
    ListTileFactory.contentSwitch(
      title: 'Show Delete Button',
      subtitle: 'shows or hides list delete button on list sheet.',
      initialValue: Preference.showPlayListDeleteButton,
      onChanged: (bool value) {
        Preference.showPlayListDeleteButton =
            !Preference.showPlayListDeleteButton;
        Preference.save(PreferenceKey.showPlayListDeleteButton);
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
  ];

  @override
  Widget build(BuildContext context) {
    final widgetList = _drawerItems(context);
    return Drawer(
      backgroundColor: ColorPalette.black,
      child: ListView.separated(
        itemCount: widgetList.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(
          color: ColorPalette.lightGreySeparator,
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (BuildContext context, int index) => widgetList[index],
      ),
    );
  }
}
