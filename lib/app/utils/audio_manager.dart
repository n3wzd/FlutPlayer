import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import './audio_player.dart';
import './playlist.dart';
import './database_manager.dart';
import './preference.dart';
import './stream_controller.dart';
import './permission_handler.dart';
import '../models/audio_track.dart';
import '../models/enum.dart';
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
  int _currentIndexAudioPlayerList = 0;
  double _volumeTransitionRate = 1.0;
  List<int> _currentByteData = [];
  StreamSubscription<double>? _mashupVolumeTransitionTimer;
  StreamSubscription<void>? _mashupNextTriggerTimer;

  AudioPlayer get audioPlayer => _audioPlayerList[_currentIndexAudioPlayerList];
  AudioPlayer get audioPlayerSub =>
      _audioPlayerList[(_currentIndexAudioPlayerList + 1) % 2];
  PlayerLoopMode get loopMode => _loopMode;
  bool get mashupMode => _mashupMode;
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
    if (Preference.shuffleReload && playListLength > 0) {
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

      PlayList.instance.updateTrack(
          0,
          await DatabaseManager.instance
              .importTrack(PlayList.instance.audioTitle(0)));
      AudioStreamController.track.add(null);
      AudioStreamController.visualizerColor.add(null);
      AudioStreamController.backgroundFile.add(null);
      if (!Preference.instantlyPlay) {
        pause();
      } else {
        play();
      }
    }
  }

  void setMashupVolumeTransition() {
    Stream<double> mashupVolumeTransition = Stream.periodic(
            const Duration(milliseconds: 100),
            (x) => x * 1.0 / ((Preference.mashupTransitionTime * 1000) / 100))
        .take((Preference.mashupTransitionTime * 1000) ~/ 100);
    _mashupVolumeTransitionTimer = mashupVolumeTransition.listen((x) {
      transitionVolume = x;
    }, onDone: setAudioPlayerVolumeDefault);
  }

  void setMashupNextTrigger() {
    int nextDelay = ((Preference.mashupNextTriggerMaxTime -
                    Preference.mashupNextTriggerMinTime) *
                1000 *
                Random().nextDouble() +
            Preference.mashupNextTriggerMinTime * 1000)
        .toInt();
    _mashupNextTriggerTimer = Stream<void>.fromFuture(
            Future<void>.delayed(Duration(milliseconds: nextDelay), () {}))
        .listen((x) {
      seekToNext();
    });
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
        await cancelMashupTimer();
        setMashupVolumeTransition();
        setMashupNextTrigger();

        newDuration = await audioPlayer
            .setAudioSource(PlayList.instance.audioTrack(index));
        await seekPosition(Duration(
            milliseconds:
                (newDuration!.inMilliseconds * (Random().nextDouble() * 0.75))
                    .toInt()));
      } else {
        await audioPlayer.setAudioSource(PlayList.instance.audioTrack(index));
      }
      PlayList.instance.updateTrack(
          index,
          await DatabaseManager.instance
              .importTrack(PlayList.instance.audioTitle(index)));
      AudioStreamController.track.add(null);
      AudioStreamController.visualizerColor.add(null);
      AudioStreamController.backgroundFile.add(null);
      global.setbackgroundPathListCurrentIndex();

      play();
      PlayList.instance.currentIndex = index;
      setCurrentByteData();
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
    audioPlayer.setVolume(_volumeTransitionRate * Preference.volumeMasterRate);
    audioPlayerSub
        .setVolume((1.0 - _volumeTransitionRate) * Preference.volumeMasterRate);
  }

  void filesOpen() async {
    if (!global.isWeb) {
      if (global.isAndroid) {
        if (!PermissionHandler.instance.isPermissionAccepted) {
          return;
        }
      }
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
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (result != null) {
        List<AudioTrack> newList = [];
        for (PlatformFile track in result.files) {
          newList.add(AudioTrack(
              title: track.name.substring(0, track.name.length - 4),
              path: '',
              modifiedDateTime: dateTimeToString(DateTime.now()),
              file: track));
        }
        playListAddList(newList);
      }
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
    if (global.isWeb) {
      _currentByteData = PlayList.instance.currentbyteData;
      return;
    }
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
      if (_mashupMode) {
        setMashupNextTrigger();
      } else {
        await cancelMashupTimer();
        setAudioPlayerVolumeDefault();
      }
    }
  }

  Future<void> cancelMashupTimer() async {
    if (_mashupVolumeTransitionTimer != null) {
      await _mashupVolumeTransitionTimer!.cancel();
    }
    if (_mashupNextTriggerTimer != null) {
      await _mashupNextTriggerTimer!.cancel();
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
          modifiedDateTime: datas[0]['modified_time'],
          color: data['color'],
          background: data['background_path'],
        ));
      }
    }
    playListAddList(newList);
  }

  void setEnabledEqualizer() {
    audioPlayer.setEnabledEqualizer();
    audioPlayerSub.setEnabledEqualizer();
  }

  Future<void> syncEqualizer() async {
    audioPlayer.syncEqualizer(audioPlayerSub);
  }
}
