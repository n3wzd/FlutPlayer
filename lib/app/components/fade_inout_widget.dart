import 'package:flutter/material.dart';
import 'dart:async';

class FadeInOutWidget extends StatefulWidget {
  const FadeInOutWidget({super.key, required this.child});
  final Widget child;

  @override
  State<FadeInOutWidget> createState() => _FadeInOutWidgetState();
}

class _FadeInOutWidgetState extends State<FadeInOutWidget> {
  bool _isVisible = false;
  StreamSubscription<void>? _trigger;

  void _activeVisibility() {
    cancelTrigger();
    setNextTrigger();
    setState(() {
      _isVisible = true;
    });
  }

  void setNextTrigger() {
    _trigger = Stream<void>.fromFuture(
            Future<void>.delayed(const Duration(seconds: 2), () {}))
        .listen((x) {
      if (!mounted) return;
      setState(() {
        _isVisible = false;
      });
    });
  }

  void cancelTrigger() {
    if (_trigger != null) {
      _trigger!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _activeVisibility();
      },
      child: Center(
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: widget.child,
        ),
      ),
    );
  }
}
