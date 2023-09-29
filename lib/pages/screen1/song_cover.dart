import 'package:flutter/material.dart';

class SongCover extends StatelessWidget {
  const SongCover({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 10.0),
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFF1D1D1D)),
      ),
    );
  }
}
