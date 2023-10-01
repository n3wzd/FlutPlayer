import 'package:flutter/material.dart';

import './control_section.dart';
import './button_section.dart';

class BottomSection extends StatelessWidget {
  const BottomSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF36081B)),
      child: const Column(
        children: [
          SizedBox(height: 10),
          ControlSection(),
          SizedBox(height: 10),
          ButtonSection(),
        ],
      ),
    );
  }
}
