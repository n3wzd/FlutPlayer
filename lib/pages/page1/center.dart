import 'package:flutter/material.dart';

import './song_cover.dart';
import './song_title.dart';
import './top_menu.dart';

class CenterSection extends StatelessWidget {
  const CenterSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          height: 80,
          child: TopMenu(),
        ),
        Expanded(
          child: SongCover(),
        ),
        SizedBox(
          height: 80,
          child: SongTitle(),
        ),
      ],
    );
  }
}
