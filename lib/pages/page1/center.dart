import 'package:flutter/material.dart';

import './song_cover.dart';
import './song_title.dart';
import './top_menu.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 80,
          child: TopMenu(),
        ),
        const Expanded(
          child: SongCover(),
        ),
        SizedBox(
          height: 80,
          child: SongTitle(title: title),
        ),
      ],
    );
  }
}
