import 'package:flutter/material.dart';

class SongTitle extends StatelessWidget {
  const SongTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text(
        'REAPER - BLACK FIRES',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          height: 0,
        ),
      ),
    );
  }
}
