import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './app_initializer.dart';
import './app_state.dart';
import './screens/top_menu.dart';
import './screens/center.dart';
import './screens/bottom.dart';
import './screens/list_sheet.dart';
import './screens/drawer.dart';
import './components/background.dart';
import './components/optional_visibility.dart';
import './components/action_button.dart';
import './components/stream_builder.dart';
import './components/fade_inout_widget.dart';
import './utils/audio_manager.dart';
import './widgets/dialog.dart';
import './widgets/text.dart';
import './models/color.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AppInitializer.initialize(
      onPreferenceLoaded: () {
        if (!mounted || _initialized) {
          return;
        }
        setState(() {
          _initialized = true;
        });
      },
    );
    if (mounted && !_initialized) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    unawaited(VideoBackgroundManager.instance.dispose());
    unawaited(AudioManager.instance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(color: ColorPalette.black);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: AudioStreamBuilder.enabledFullscreen(
        (context, value) => Scaffold(
          key: _scaffoldKey,
          appBar: !AppState.instance.isFullScreen
              ? AppBar(
                  automaticallyImplyLeading: false,
                  title: TopMenu(
                    onDrawTap: () {
                      _scaffoldKey.currentState!.openDrawer();
                    },
                  ),
                  backgroundColor: ColorPalette.black,
                  elevation: 0.0,
                  titleSpacing: 0,
                )
              : null,
          drawer: const PageDrawer(),
          body: const SafeArea(child: ScreenPage()),
        ),
      ),
    );
  }

  void _showExitDialog() {
    DialogFactory.choiceDialog(
      context: context,
      onOkPressed: () {
        unawaited(AudioManager.instance.dispose());
        SystemNavigator.pop();
      },
      onCancelPressed: () {},
      content: TextFactory.text('Exit?', fontSize: 20),
    );
  }
}

class ScreenPage extends StatelessWidget {
  const ScreenPage({super.key});

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.enabledFullscreen(
    (context, value) => AppState.instance.isFullScreen
        ? const ScreenPageFullscreen()
        : const ScreenPageNormalScreen(),
  );
}

class ScreenPageFullscreen extends StatelessWidget {
  const ScreenPageFullscreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: ColorPalette.black,
    child: Stack(
      children: [
        const ScreenPageCenter(),
        FadeInOutWidget(
          child: Container(
            color: Colors.transparent,
            child: const Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 120,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: FullscreenButton(),
                        ),
                        ControlSection(),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    children: [
                      Spacer(),
                      Expanded(
                        flex: 2,
                        child: SeekToPreviousButton(outline: false),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 2,
                        child: PlayButton(outline: false, iconSize: 55),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 2,
                        child: SeekToNextButton(outline: false),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class ScreenPageNormalScreen extends StatelessWidget {
  const ScreenPageNormalScreen({super.key});
  final int minHeight = 600;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        color: ColorPalette.black,
        child: Column(
          children: [
            const Expanded(flex: 2, child: ScreenPageCenter()),
            Visibility(
              visible: MediaQuery.of(context).size.height >= minHeight,
              child: const Expanded(flex: 1, child: BottomSection()),
            ),
          ],
        ),
      ),
      Visibility(
        visible: MediaQuery.of(context).size.height >= minHeight,
        child: const ListSheet(),
      ),
    ],
  );
}

class ScreenPageCenter extends StatelessWidget {
  const ScreenPageCenter({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      OptionalVisibility.background(context, const Background()),
      const CenterSection(),
    ],
  );
}
