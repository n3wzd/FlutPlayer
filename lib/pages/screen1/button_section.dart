import 'package:flutter/material.dart';

import '../components/button.dart';

class ButtonSection extends StatelessWidget {
  const ButtonSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Button(buttonRadius: 45),
        Button(buttonRadius: 45),
        Button(buttonRadius: 70),
        Button(buttonRadius: 45),
        Button(buttonRadius: 45),
      ],
    );
  }
}
