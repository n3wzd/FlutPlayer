import 'package:flutter/material.dart';

import '../components/button.dart';

class ButtonSection extends StatelessWidget {
  const ButtonSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Button(
          buttonRadius: 50,
          icon: Icon(
            Icons.shuffle,
            color: Colors.white,
            size: 35,
          ),
        ),
        SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          icon: Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 35,
          ),
        ),
        SizedBox(width: 20),
        Button(
          buttonRadius: 70,
          icon: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 55,
          ),
        ),
        SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          icon: Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 35,
          ),
        ),
        SizedBox(width: 20),
        Button(
          buttonRadius: 50,
          icon: Icon(
            Icons.repeat,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }
}
