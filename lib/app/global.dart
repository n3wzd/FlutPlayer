import 'package:flutter/material.dart';
import 'dart:async';

String debugLog = '';
final debugLogStreamController = StreamController<void>.broadcast();

late final VoidCallback rebuildAll;
