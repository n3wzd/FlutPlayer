import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import './audio_player.dart';
import './background_manager.dart';
import './playlist.dart';
import './database_manager.dart';
import './preference.dart';
import './stream_controller.dart';
import '../models/data.dart';
import '../models/enum.dart';
import '../models/timer.dart';
import '../global.dart' as global;

class AudioManager {
  AudioManager._();
  static final AudioManager _instance = AudioManager._();
  static AudioManager get instance => _instance;

  late final List<AudioPlayer> _audioPlayerList = [
    AudioPlayer(),
    AudioPlayer(),
  ];
  final _allowedExtensions = ['mp3', 'wav', 'ogg'];

  PlayerLoopMode _loopMode = PlayerLoopMode.all;
  bool _mashupMode = false;
  bool _customMixMode = false;
  int _currentIndexAudioPlayerList = 0;
  double _volumeTransitionRate = 1.0;
  List<int> _currentByteData = [];
  StreamSubscription<double>? _mashupVolumeTransitionTimer;
  AdvancedTimer? _mashupNextTriggerTimer;
  Map<String, CustomMixData> _customMixData = {};

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
  List<int> get currentByteData => _currentByteData;

  set masterVolume(double v) {
    Preference.volumeMasterRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  set transitionVolume(double v) {
    _volumeTransitionRate = v < 0 ? 0 : (v > 1.0 ? 1.0 : v);
    updateAudioPlayerVolume();
  }

  void init() {
    audioPlayer.init(0, nextEventWhenPlayerCompleted);
    audioPlayerSub.init(1, nextEventWhenPlayerCompleted);
    setAudioPlayerVolumeDefault();
  }

  void dispose() {
    audioPlayer.dispose();
    audioPlayerSub.dispose();
  }

  void nextEventWhenPlayerCompleted(int audioPlayerCode) async {
    AudioStreamController.track.add(null);
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

  void playListAddList(List<AudioTrack> newList) {
    PlayList.instance.addAll(newList);
    if (Preference.shuffleReload && playListLength > 0 && !_customMixMode) {
      PlayList.instance.currentIndex = Random().nextInt(playListLength);
      PlayList.instance.shuffle();
      AudioStreamController.playListOrderState.add(null);
    }
    AudioStreamController.playList.add(null);
    initPlayListUpdated();
  }

  void initPlayListUpdated() async {
    if (isAudioPlayerEmpty) {
      await audioPlayer.setAudioSource(PlayList.instance.audioTrack(0));
      setCurrentByteData();

      PlayList.instance.updateTrack(0, await DatabaseManager.instance.importTrack(PlayList.instance.audioTitle(0)));
      AudioStreamController.track.add(null);
      AudioStreamController.visualizerColor.add(null);
      AudioStreamController.backgroundFile.add(null);
      if (Preference.instantlyPlay || _customMixMode) {
        play();
      } else {
        pause();
      }
    }
  }

  void setMashupVolumeTransition() {
    int transitionTime = (_customMixMode ? 
          _customMixData[PlayList.instance.currentAudioTitle]!.buildUpTime : 
          Preference.mashupTransitionTime) * 1000;
    Stream<double> mashupVolumeTransition = Stream.periodic(
              const Duration(milliseconds: 100),
              (x) => x * 1.0 / (transitionTime / 100))
          .take(transitionTime ~/ 100);
    _mashupVolumeTransitionTimer = mashupVolumeTransition.listen((x) {
      transitionVolume = x;
    }, onDone: setAudioPlayerVolumeDefault);
  }

  void setMashupNextTrigger() {
    final playList = PlayList.instance;
    if(_customMixMode) {
      int nextSecond = _customMixData[playList.currentAudioTitle]!.duration - 
            min(((_customMixData[playList.currentAudioTitle]!.duration - _customMixData[playList.currentAudioTitle]!.buildUpTime) * 0.8).toInt(),
            _customMixData[playList.audioTitle((playList.currentIndex + 1) % playList.playListLength)]!.buildUpTime);
      _mashupNextTriggerTimer = AdvancedTimer(duration: Duration(seconds: nextSecond), onComplete: () {
        if(_customMixMode) {
          seekToNext();
        }
      });
    }
    else {
      int nextMilliseconds = ((Preference.mashupNextTriggerMaxTime -
                      Preference.mashupNextTriggerMinTime) *
                  1000 *
                  Random().nextDouble() +
              Preference.mashupNextTriggerMinTime * 1000)
          .toInt();
      _mashupNextTriggerTimer = AdvancedTimer(duration: Duration(milliseconds: nextMilliseconds), onComplete: () {
        if(_mashupMode) {
          seekToNext();
        }
      });
    }
    _mashupNextTriggerTimer!.start();
  }

  void setAudioPlayerVolumeDefault() {
    transitionVolume = 1.0;
  }

  Future<void> seekTrack(int index, {bool forceLoad = false}) async {
    Duration? newDuration;
    if (PlayList.instance.isNotEmpty &&
        (index != PlayList.instance.currentIndex || forceLoad)) {
      index %= playListLength;
      if (_mashupMode) {
        play();
        _currentIndexAudioPlayerList = (_currentIndexAudioPlayerList + 1) % 2;
        newDuration = await audioPlayer
            .setAudioSource(PlayList.instance.audioTrack(index));
        if(_customMixMode) {
          await seekPosition(Duration(seconds: _customMixData[PlayList.instance.audioTitle(index)]!.start));
        } else {
          await seekPosition(Duration(
              milliseconds:
                  (newDuration!.inMilliseconds * (Random().nextDouble() * 0.75))
                      .toInt()));
        }
      } else {
        await audioPlayer.setAudioSource(PlayList.instance.audioTrack(index));
      }
      PlayList.instance.updateTrack(
          index,
          await DatabaseManager.instance
              .importTrack(PlayList.instance.audioTitle(index)));
      
      AudioStreamController.track.add(null);
      AudioStreamController.visualizerColor.add(null);

      play();
      PlayList.instance.currentIndex = index;
      setCurrentByteData();
      BackgroundManager.instance.randomizeCurrentBackgroundList();
      AudioStreamController.backgroundFile.add(null);
      global.setVisualizerColor();

      if(_mashupMode) {
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
      audioPlayerSub.play();
      if (_mashupVolumeTransitionTimer != null) {
        _mashupVolumeTransitionTimer!.resume();
      }
      if (_mashupNextTriggerTimer != null) {
        _mashupNextTriggerTimer!.resume();
      }
    }
  }

  Future<void> pause() async {
    if (!isAudioPlayerEmpty && isPlaying) {
      await audioPlayer.pause();
      await audioPlayerSub.pause();
      if (_mashupVolumeTransitionTimer != null) {
        _mashupVolumeTransitionTimer!.pause();
      }
      if (_mashupNextTriggerTimer != null) {
        _mashupNextTriggerTimer!.pause();
      }
    }
  }

  Future<void> replay() async {
    audioPlayer.replay();
  }

  void updateAudioPlayerVolume() {
    double logScale = 8.0;
    double expPower = 3.5;
    double volumeA = 1.0;
    double volumeB = 1.0;
    if(_customMixMode) {
      double baseA = 0.6;
      double baseB = 0.1;
      double volumeThreshold1 = 0.2;
      double volumeThreshold2 = 0.7;
      if(_volumeTransitionRate < volumeThreshold1) {
        double v = _volumeTransitionRate / volumeThreshold1;
        volumeA = (log(1 + v * logScale) / log(1 + logScale)) * baseA;
        volumeB = 1.0 - (pow(v, expPower).toDouble()) * baseB;
      }
      else if (_volumeTransitionRate < volumeThreshold2) {
        volumeA = baseA;
        volumeB = 1.0 - baseB;
      } else {
        double v = (_volumeTransitionRate - volumeThreshold2) / (1.0 - volumeThreshold2);
        volumeA = (log(1 + v * logScale) / log(1 + logScale)) * (1.0 - baseA) + baseA;
        volumeB = 1.0 - (pow(v, expPower).toDouble() * (1.0 - baseB) + baseB);
      }
    } else {
      volumeA = log(1 + _volumeTransitionRate * logScale) / log(1 + logScale);
      volumeB = 1.0 - pow(_volumeTransitionRate, expPower).toDouble();
    }
    audioPlayer.setVolume(volumeA * Preference.volumeMasterRate);
    audioPlayerSub.setVolume(volumeB * Preference.volumeMasterRate);
  }

  void filesOpen() async {
    String? selectedDirectoryPath =
          await FilePicker.platform.getDirectoryPath();
      if (selectedDirectoryPath != null) {
        List<AudioTrack> newList = [];
        Directory selectedDirectory = Directory(selectedDirectoryPath);
        List<FileSystemEntity> selectedDirectoryFile =
            selectedDirectory.listSync(recursive: true);
        for (FileSystemEntity file in selectedDirectoryFile) {
          String path = file.path;
          if (!FileSystemEntity.isDirectorySync(path)) {
            if (_allowedExtensions.contains(path.split('.').last)) {
              String name = file.uri.pathSegments.last;
              FileStat fileStat = FileStat.statSync(path);
              newList.add(AudioTrack(
                title: name.substring(0, name.length - 4),
                path: path,
                modifiedDateTime: dateTimeToString(fileStat.modified),
              ));
            }
          }
        }
        playListAddList(newList);
      }
  }

  List<int> _readBytesFromFile(String filePath) {
    File file = File(filePath);
    if (file.existsSync()) {
      RandomAccessFile accessFile = file.openSync();
      int length = file.lengthSync();
      List<int> bytes = accessFile.readSync(length);
      accessFile.closeSync();
      return bytes;
    }
    return [];
  }

  void setCurrentByteData() {
    _currentByteData = _readBytesFromFile(PlayList.instance.currentAudioPath);
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
    AudioStreamController.loopMode.add(null);
  }

  void toggleShuffleMode() {
    PlayList.instance.toggleShuffleMode();
    AudioStreamController.playListOrderState.add(null);
  }

  void toggleMashupMode() async {
    if (PlayList.instance.isNotEmpty) {
      _mashupMode = !_mashupMode;
      _customMixMode = false;
      if (_mashupMode) {
        activeMashupMode();
      } else {
        await cancelMashupTimer();
        setAudioPlayerVolumeDefault();
      }
      AudioStreamController.mashupButton.add(null);
    }
  }

  void activeMashupMode() async {
    _mashupMode = true;
    setMashupNextTrigger();
  }

  Future<void> cancelMashupTimer() async {
    if (_mashupVolumeTransitionTimer != null) {
      await _mashupVolumeTransitionTimer!.cancel();
    }
    if (_mashupNextTriggerTimer != null) {
      _mashupNextTriggerTimer!.cancel();
    }
  }

  void removePlayListItem(int index) {
    bool needReload = (index == PlayList.instance.currentIndex);
    PlayList.instance.remove(index);
    if (needReload) {
      seekTrack(index < playListLength ? index : index - 1, forceLoad: true);
    }
  }

  void importTagList(String listName) async {
    List<Map>? datas = await DatabaseManager.instance.importList(listName);
    List<AudioTrack> newList = [];
    for (Map data in datas) {
      String path = data['path'];
      if (File(path).existsSync()) {
        newList.add(AudioTrack(
          title: data['title'],
          path: data['path'],
          modifiedDateTime: data['modified_time'],
          color: data['color'],
        ));
      }
    }
    playListAddList(newList);
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
        AudioTrack? track = await DatabaseManager.instance.importTrack(trackName);
        if(track != null) {
          customMixTracks[trackName] = track;
        }
      }

      List<AudioTrack> newList = [];
      for (final trackData in mixData.entries) {
        String trackName = trackData.key;
        Map<String, dynamic> range = trackData.value;
        AudioTrack? track = customMixTracks[trackName];
        if(track != null) {
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
      AudioStreamController.mashupButton.add(null);
      playListAddList(newList);
      activeMashupMode();
    }
  }
}
