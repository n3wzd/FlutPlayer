import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import './audio_mashup_controller.dart';
import './audio_player.dart';
import './background_manager.dart';
import './playlist.dart';
import './database_manager.dart';
import './preference.dart';
import './permission_handler.dart';
import './stream_controller.dart';
import '../models/data.dart';
import '../models/enum.dart';
import '../app_state.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager _instance = AudioManager._();
  static AudioManager get instance => _instance;

  late final List<AudioPlayer> _audioPlayerList = [
    AudioPlayer(),
    AudioPlayer(),
  ];
  final _allowedExtensions = ['mp3', 'wav', 'ogg'];
  static const _trackSwitchFadeDuration = Duration(milliseconds: 80);

  PlayerLoopMode _loopMode = PlayerLoopMode.all;
  bool _mashupMode = false;
  bool _customMixMode = false;
  int _currentIndexAudioPlayerList = 0;
  double _volumeTransitionRate = 1.0;
  final AudioMashupController _mashupController = AudioMashupController();
  final List<StreamSubscription<void>> _playbackSubscriptions = [];
  Map<String, CustomMixData> _customMixData = {};
  Future<void>? _playListInitFuture;
  bool _initialized = false;

  AudioPlayer get audioPlayer => _audioPlayerList[_currentIndexAudioPlayerList];
  AudioPlayer get audioPlayerSub =>
      _audioPlayerList[(_currentIndexAudioPlayerList + 1) % 2];
  PlayerLoopMode get loopMode => _loopMode;
  bool get mashupMode => _mashupMode;
  bool get customMixMode => _customMixMode;
  int get playListLength => PlayList.instance.playListLength;
  bool get isPlaying => audioPlayer.isPlaying;
  Duration get duration => audioPlayer.duration;
  Duration get position => audioPlayer.position;
  bool get isAudioPlayerEmpty => audioPlayer.isAudioPlayerEmpty;

  set masterVolume(double v) {
    Preference.volumeMasterRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  set transitionVolume(double v) {
    _volumeTransitionRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await audioPlayer.init(0, nextEventWhenPlayerCompleted);
    await audioPlayerSub.init(1, nextEventWhenPlayerCompleted);
    _listenForPlaybackChanges();
    setAudioPlayerVolumeDefault();
    _initialized = true;
  }

  Future<void> dispose() async {
    await cancelMashupTimer();
    for (final subscription in _playbackSubscriptions) {
      await subscription.cancel();
    }
    _playbackSubscriptions.clear();
    await audioPlayer.dispose();
    await audioPlayerSub.dispose();
    _initialized = false;
  }

  void _listenForPlaybackChanges() {
    if (_playbackSubscriptions.isNotEmpty) {
      return;
    }
    for (final player in _audioPlayerList) {
      _playbackSubscriptions.add(
        player.playbackEventStream.listen(
          (_) => AudioStreamController.emitPlayingChanged(),
        ),
      );
    }
  }

  void nextEventWhenPlayerCompleted(int audioPlayerCode) async {
    AudioStreamController.emitTrackChanged();
    if (audioPlayerCode != _currentIndexAudioPlayerList) {
      return;
    }
    if (_mashupMode) {
      await seekToNext();
    } else {
      if (_loopMode == PlayerLoopMode.one) {
        replay();
      } else {
        if (PlayList.instance.currentIndex == playListLength - 1 &&
            _loopMode == PlayerLoopMode.off) {
          pause();
        } else {
          await seekToNext();
        }
      }
    }
  }

  Future<void> playListAddList(List<AudioTrack> newList) async {
    PlayList.instance.addAll(newList);
    if (Preference.shuffleReload && playListLength > 0 && !_customMixMode) {
      PlayList.instance.currentIndex = Random().nextInt(playListLength);
      PlayList.instance.shuffle();
      AudioStreamController.emitPlayListOrderChanged();
    }
    AudioStreamController.emitPlayListChanged();
    await initPlayListUpdated();
  }

  Future<void> initPlayListUpdated() async {
    if (!isAudioPlayerEmpty) {
      return;
    }
    _playListInitFuture ??= _initPlayListUpdated().whenComplete(() {
      _playListInitFuture = null;
    });
    await _playListInitFuture;
  }

  Future<void> _initPlayListUpdated() async {
    if (!isAudioPlayerEmpty || !PlayList.instance.isNotEmpty) {
      return;
    }
    await audioPlayer.setAudioSource(PlayList.instance.audioTrack(0));

    PlayList.instance.updateTrack(
      0,
      await DatabaseManager.instance.importTrack(
        PlayList.instance.audioTitle(0),
      ),
    );
    AudioStreamController.emitTrackChanged();
    AudioStreamController.emitVisualizerColorChanged();
    AudioStreamController.emitBackgroundFileChanged();
    if (Preference.instantlyPlay || _customMixMode) {
      play();
    } else {
      await pause();
    }
  }

  void setMashupVolumeTransition() {
    _mashupController.startVolumeTransition(
      duration: Duration(seconds: Preference.mashupTransitionTime),
      onTick: (value) {
        transitionVolume = value;
      },
      onDone: setAudioPlayerVolumeDefault,
    );
  }

  void setMashupNextTrigger() {
    final duration = _customMixMode
        ? Duration(
            seconds:
                _customMixData[PlayList.instance.currentAudioTitle]!.duration,
          )
        : AudioMashupController.randomTriggerDuration(
            minSeconds: Preference.mashupNextTriggerMinTime,
            maxSeconds: Preference.mashupNextTriggerMaxTime,
          );
    _mashupController.startNextTrigger(
      duration: duration,
      shouldAdvance: () => _mashupMode,
      onNext: seekToNext,
    );
  }

  void setAudioPlayerVolumeDefault() {
    transitionVolume = 1.0;
  }

  Future<void> seekTrack(int index, {bool forceLoad = false}) async {
    Duration? newDuration;
    if (PlayList.instance.isNotEmpty &&
        (index != PlayList.instance.currentIndex || forceLoad)) {
      index %= playListLength;
      final wasPlaying = isPlaying;
      if (_mashupMode) {
        play();
        _currentIndexAudioPlayerList = (_currentIndexAudioPlayerList + 1) % 2;
        newDuration = await audioPlayer.setAudioSource(
          PlayList.instance.audioTrack(index),
        );
        if (_customMixMode) {
          await seekPosition(
            Duration(
              seconds:
                  _customMixData[PlayList.instance.audioTitle(index)]!.start,
            ),
          );
        } else {
          await seekPosition(
            Duration(
              milliseconds:
                  (newDuration!.inMilliseconds * (Random().nextDouble() * 0.75))
                      .toInt(),
            ),
          );
        }
      } else {
        final previousAudioPlayer = audioPlayer;
        _currentIndexAudioPlayerList = (_currentIndexAudioPlayerList + 1) % 2;
        await audioPlayer.setAudioSource(PlayList.instance.audioTrack(index));
        final targetVolume = Preference.volumeMasterRate;
        audioPlayer.setVolume(wasPlaying ? 0 : targetVolume);
        if (wasPlaying) {
          audioPlayer.play();
          await Future.wait([
            audioPlayer.fadeVolume(targetVolume, _trackSwitchFadeDuration),
            previousAudioPlayer.fadeVolume(0, _trackSwitchFadeDuration),
          ]);
        }
        await previousAudioPlayer.clearAudioSource();
        updateAudioPlayerVolume();
      }
      PlayList.instance.updateTrack(
        index,
        await DatabaseManager.instance.importTrack(
          PlayList.instance.audioTitle(index),
        ),
      );

      AudioStreamController.emitTrackChanged();
      AudioStreamController.emitVisualizerColorChanged();

      play();
      PlayList.instance.currentIndex = index;
      BackgroundManager.instance.randomizeCurrentBackgroundList();
      AudioStreamController.emitBackgroundFileChanged();
      AppState.instance.updateVisualizerColor();

      if (_mashupMode) {
        await cancelMashupTimer();
        setMashupVolumeTransition();
        setMashupNextTrigger();
      }
    }
  }

  Future<void> seekPosition(Duration duration) async {
    if (!isAudioPlayerEmpty) {
      await audioPlayer.seek(duration);
    }
  }

  Future<void> seekToPrevious() async {
    await seekTrack(PlayList.instance.currentIndex - 1);
  }

  Future<void> seekToNext() async {
    await seekTrack(PlayList.instance.currentIndex + 1);
  }

  void play() {
    if (!isAudioPlayerEmpty && !isPlaying) {
      audioPlayer.play();
      if (_mashupMode) {
        audioPlayerSub.play();
      }
      _mashupController.resume();
    }
  }

  Future<void> pause() async {
    if (!isAudioPlayerEmpty && isPlaying) {
      await audioPlayer.pause();
      if (_mashupMode) {
        await audioPlayerSub.pause();
      }
      _mashupController.pause();
    }
  }

  Future<void> replay() async {
    audioPlayer.replay();
  }

  void updateAudioPlayerVolume() {
    final levels = AudioVolumeMixer.calculate(
      customMixMode: _customMixMode,
      transitionRate: _volumeTransitionRate,
    );
    audioPlayer.setVolume(levels.primary * Preference.volumeMasterRate);
    audioPlayerSub.setVolume(levels.secondary * Preference.volumeMasterRate);
  }

  void filesOpen() async {
    if (!PermissionHandler.instance.isPermissionAccepted) {
      return;
    }
    String? selectedDirectoryPath = await FilePicker.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      List<AudioTrack> newList = [];
      Directory selectedDirectory = Directory(selectedDirectoryPath);
      List<FileSystemEntity> selectedDirectoryFile = selectedDirectory.listSync(
        recursive: true,
      );
      for (FileSystemEntity file in selectedDirectoryFile) {
        String path = file.path;
        if (!FileSystemEntity.isDirectorySync(path)) {
          if (_allowedExtensions.contains(path.split('.').last)) {
            String name = file.uri.pathSegments.last;
            FileStat fileStat = FileStat.statSync(path);
            newList.add(
              AudioTrack(
                title: name.substring(0, name.length - 4),
                path: path,
                modifiedDateTime: dateTimeToString(fileStat.modified),
              ),
            );
          }
        }
      }
      await playListAddList(newList);
    }
  }

  void togglePlayMode() async {
    if (isPlaying) {
      await pause();
    } else {
      play();
    }
  }

  void toggleLoopMode() {
    if (_loopMode == PlayerLoopMode.off) {
      _loopMode = PlayerLoopMode.all;
    } else if (_loopMode == PlayerLoopMode.all) {
      _loopMode = PlayerLoopMode.one;
    } else {
      _loopMode = PlayerLoopMode.off;
    }
    AudioStreamController.emitLoopModeChanged();
  }

  void toggleShuffleMode() {
    PlayList.instance.toggleShuffleMode();
    AudioStreamController.emitPlayListOrderChanged();
  }

  void toggleMashupMode() async {
    if (PlayList.instance.isNotEmpty) {
      _mashupMode = !_mashupMode;
      _customMixMode = false;
      if (_mashupMode) {
        activeMashupMode();
      } else {
        await cancelMashupTimer();
        await audioPlayerSub.pause();
        setAudioPlayerVolumeDefault();
      }
      AudioStreamController.emitMashupButtonChanged();
    }
  }

  void activeMashupMode() async {
    _mashupMode = true;
    setMashupNextTrigger();
  }

  Future<void> cancelMashupTimer() async {
    await _mashupController.cancel();
  }

  void removePlayListItem(int index) {
    bool needReload = (index == PlayList.instance.currentIndex);
    PlayList.instance.remove(index);
    if (needReload) {
      seekTrack(index < playListLength ? index : index - 1, forceLoad: true);
    }
  }

  Future<void> importTagList(String listName) async {
    List<Map> datas = await DatabaseManager.instance.importList(listName);
    List<AudioTrack> newList = [];
    for (Map data in datas) {
      String path = data['path'];
      if (await File(path).exists()) {
        newList.add(
          AudioTrack(
            title: data['title'],
            path: data['path'],
            modifiedDateTime: data['modified_time'],
            color: data['color'],
          ),
        );
      }
    }
    await playListAddList(newList);
  }

  void setEnabledEqualizer() {
    audioPlayer.setEnabledEqualizer();
    audioPlayerSub.setEnabledEqualizer();
  }

  Future<void> syncEqualizer() async {
    audioPlayer.syncEqualizer(audioPlayerSub);
  }

  void importCustomMixs(List<String> paths) async {
    PlayList.instance.clear();
    _customMixData = {};
    for (final path in paths) {
      importCustomMix(path);
    }
  }

  void importCustomMix(String path) async {
    if (File(path).existsSync()) {
      File file = File(path);
      String datas = file.readAsStringSync();
      Map<String, dynamic> mixData = json.decode(datas);

      Map<String, AudioTrack> customMixTracks = {};
      for (final trackName in mixData.keys) {
        AudioTrack? track = await DatabaseManager.instance.importTrack(
          trackName,
        );
        if (track != null) {
          customMixTracks[trackName] = track;
        }
      }

      List<AudioTrack> newList = [];
      for (final trackData in mixData.entries) {
        String trackName = trackData.key;
        Map<String, dynamic> range = trackData.value;
        AudioTrack? track = customMixTracks[trackName];
        if (track != null) {
          int lo = stringTimeToInt(range["start"]);
          int mid = stringTimeToInt(range["mid"]);
          int hi = stringTimeToInt(range["end"]);
          _customMixData.addEntries([
            MapEntry(
              trackName,
              CustomMixData(
                track: track,
                start: lo,
                duration: hi - lo,
                buildUpTime: ((mid - lo) * 0.8).toInt(),
              ),
            ),
          ]);
          newList.add(track);
        }
      }
      newList.shuffle();

      _customMixMode = true;
      AudioStreamController.emitMashupButtonChanged();
      await playListAddList(newList);
      activeMashupMode();
    }
  }
}
