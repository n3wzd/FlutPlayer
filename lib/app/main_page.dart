import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './global.dart' as global;
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

  @override
  void initState() {
    super.initState();
    global.initApp();
  }

  @override
  void dispose() {
    AudioManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: AudioStreamBuilder.enabledFullsccreen(
        (context, value) => Scaffold(
          key: _scaffoldKey,
          appBar: !global.isFullScreen
              ? AppBar(
                  automaticallyImplyLeading: false,
                  title: TopMenu(onDrawTap: () {
                    _scaffoldKey.currentState!.openDrawer();
                  }),
                  backgroundColor: ColorPalette.black,
                  elevation: 0.0,
                  titleSpacing: 0,
                )
              : null,
          drawer: const PageDrawer(),
          body: const SafeArea(
            child: ScreenPage(),
          ),
        ),
      ),
      onWillPop: () {
        DialogFactory.choiceDialog(
            context: context,
            onOkPressed: () {
              AudioManager.instance.dispose();
              SystemNavigator.pop();
            },
            onCancelPressed: () {},
            content: TextFactory.text('Exit?', fontSize: 20));
        return Future<bool>.value(false);
      },
    );
  }
}

class ScreenPage extends StatelessWidget {
  const ScreenPage({super.key});

  @override
  Widget build(BuildContext context) => AudioStreamBuilder.enabledFullsccreen(
      (context, value) => global.isFullScreen
          ? const ScreenPageFullscreen()
          : const ScreenPageNormalScreen());
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

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Container(
            color: ColorPalette.black,
            child: const Column(
              children: [
                Expanded(
                  flex: 2,
                  child: ScreenPageCenter(),
                ),
                Expanded(
                  flex: 1,
                  child: BottomSection(),
                ),
              ],
            ),
          ),
          const ListSheet(),
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
