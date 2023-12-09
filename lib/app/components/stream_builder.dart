import 'package:flutter/material.dart';
import '../utils/audio_player.dart';
import '../utils/stream_controller.dart';

typedef BuildParameter<T> = Widget Function(BuildContext, AsyncSnapshot<T>);

class AudioStreamBuilder {
  static StreamBuilder<bool> playing(BuildParameter<bool> builder) =>
      StreamBuilder<bool>(
        stream: AudioPlayerKit.instance.audioPlayer.playingStream,
        builder: (context, data) => StreamBuilder<bool>(
          stream: AudioPlayerKit.instance.audioPlayerSub.playingStream,
          builder: builder,
        ),
      );

  static StreamBuilder<Duration> position(BuildParameter<Duration> builder) =>
      StreamBuilder<Duration>(
        stream: AudioPlayerKit.instance.audioPlayer.positionStream,
        builder: builder,
      );

  static StreamBuilder<void> track(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.track.stream,
        builder: builder,
      );

  static StreamBuilder<void> playList(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.playList.stream,
        builder: builder,
      );

  static StreamBuilder<void> loopMode(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.loopMode.stream,
        builder: builder,
      );

  static StreamBuilder<void> playListOrderState(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.playListOrderState.stream,
        builder: builder,
      );

  static StreamBuilder<void> visualizerColor(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.visualizerColor.stream,
        builder: builder,
      );

  static StreamBuilder<void> playListSheet(BuildParameter<void> builder) =>
      playListOrderState(
          (context, value) => playList((context, value) => track(builder)));

  static StreamBuilder<void> enabledBackground(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.enabledBackground.stream,
        builder: builder,
      );

  static StreamBuilder<void> enabledFullsccreen(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.enabledFullsccreen.stream,
        builder: builder,
      );

  static StreamBuilder<void> enabledNCSLogo(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.enabledNCSLogo.stream,
        builder: builder,
      );

  static StreamBuilder<void> enabledVisualizer(BuildParameter<void> builder) =>
      StreamBuilder<void>(
        stream: AudioStreamController.enabledVisualizer.stream,
        builder: builder,
      );
}
