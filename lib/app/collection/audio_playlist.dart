import 'package:just_audio/just_audio.dart';
import './audio_track.dart';
import './file_audio_source.dart';

class PlayList {
  final Map<String, AudioTrack> _playMap = {};
  final List<String> _playList = [];
  final List<String> _playListBackup = [];
  int currentIndex = 0;

  get playListLength => _playMap.length;
  get isNotEmpty => _playMap.isNotEmpty;
  get currentAudioTitle =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.title : '';

  String audioTitle(index) => _playMap[_playList[index]]!.title;
  AudioSource audioSource(int index, {bool androidMode = true}) => androidMode
      ? AudioSource.file(_playMap[_playList[index]]!.path)
      : FileAudioSource(
          bytes: _playMap[_playList[index]]!.file!.bytes!.cast<int>());

  void addAll(List<AudioTrack> files) {
    for (AudioTrack file in files) {
      String key = file.title;
      if (!_playMap.containsKey(key)) {
        _playMap[key] = file;
        _playList.add(key);
        _playListBackup.add(key);
      }
    }
  }

  void shuffleOn() {
    if (_playList.isNotEmpty) {
      String currentKey = _playList[currentIndex];
      _playList.shuffle();
      for (int i = 0; i < _playList.length; i++) {
        if (currentKey == _playList[i]) {
          String tempKey = _playList[0];
          _playList[0] = _playList[i];
          _playList[i] = tempKey;
          break;
        }
      }
      currentIndex = 0;
    }
  }

  void shuffleOff() {
    if (_playList.isNotEmpty) {
      String currentKey = _playList[currentIndex];
      for (int i = 0; i < _playList.length; i++) {
        _playList[i] = _playListBackup[i];
        if (currentKey == _playList[i]) {
          currentIndex = i;
        }
      }
    }
  }

  void clear() {
    _playMap.clear();
    _playList.clear();
    _playListBackup.clear();
    currentIndex = 0;
  }
}
