import 'package:flutter/material.dart';

import '../components/button.dart';

class ButtonSection extends StatelessWidget {
  const ButtonSection({Key? key, required this.onPlay}) : super(key: key);
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.shuffle,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 70,
          onPressed: onPlay,
          icon: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 55,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          onPressed: onPlay,
          icon: const Icon(
            Icons.repeat,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }
}
