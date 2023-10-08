import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

class ButtonUI extends StatefulWidget {
  const ButtonUI({Key? key, required this.assetsAudioPlayer}) : super(key: key);
  final AssetsAudioPlayer assetsAudioPlayer;

  @override
  State<ButtonUI> createState() => _ButtonUIState();
}

class _ButtonUIState extends State<ButtonUI> {
  bool _isPlay = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(const Color(0xCCFFFFFF)),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            shape: MaterialStateProperty.all(const CircleBorder(
                side: BorderSide(color: Color(0xCCFFFFFF), width: 1))),
            overlayColor:
                MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return const Color(0x44FFFFFF);
              } else if (states.contains(MaterialState.hovered)) {
                return const Color(0x33FFFFFF);
              }
              return Colors.transparent;
            }),
          ),
        ),
        useMaterial3: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            iconSize: 35,
            onPressed: () {},
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 35,
            onPressed: () {},
          ),
          const SizedBox(width: 20),
          IconButton(
            isSelected: _isPlay,
            icon: const Icon(Icons.play_arrow),
            selectedIcon: const Icon(Icons.pause),
            iconSize: 55,
            onPressed: () {
              if (_isPlay) {
                widget.assetsAudioPlayer.pause();
              } else {
                widget.assetsAudioPlayer.play();
              }
              setState(() {
                _isPlay = !_isPlay;
              });
            },
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 35,
            onPressed: () {},
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.repeat),
            iconSize: 35,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
