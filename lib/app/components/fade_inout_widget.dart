import 'package:flutter/material.dart';
import 'dart:async';

class FadeInOutWidget extends StatefulWidget {
  const FadeInOutWidget({super.key, required this.child});
  final Widget child;

  @override
  State<FadeInOutWidget> createState() => _FadeInOutWidgetState();
}

class _FadeInOutWidgetState extends State<FadeInOutWidget> {
  final Duration triggerVisibleTime = const Duration(milliseconds: 2000);
  final Duration triggerActiveTime = const Duration(milliseconds: 2250);
  final Duration animationTime = const Duration(milliseconds: 250);
  bool _isVisible = false;
  bool _isActive = false;
  StreamSubscription<void>? _triggerVisible;
  StreamSubscription<void>? _triggerActive;

  void _activeVisibility() {
    cancelTrigger();
    setNextTrigger();
    setState(() {
      _isVisible = true;
      _isActive = true;
    });
  }

  void setNextTrigger() {
    _triggerVisible =
        Stream<void>.fromFuture(Future<void>.delayed(triggerVisibleTime, () {}))
            .listen((x) {
      if (!mounted) return;
      setState(() {
        _isVisible = false;
      });
    });
    _triggerActive =
        Stream<void>.fromFuture(Future<void>.delayed(triggerActiveTime, () {}))
            .listen((x) {
      if (!mounted) return;
      setState(() {
        _isActive = false;
      });
    });
  }

  void cancelTrigger() {
    if (_triggerVisible != null) {
      _triggerVisible!.cancel();
    }
    if (_triggerActive != null) {
      _triggerActive!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          _activeVisibility();
        },
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child:
              _isActive ? widget.child : Container(color: Colors.transparent),
        ));
  }
}
