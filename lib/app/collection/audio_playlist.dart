import 'package:just_audio/just_audio.dart';
import './audio_track.dart';
import './file_audio_source.dart';

class PlayList {
  final Map<String, AudioTrack> _playMap = {};
  final List<String> _playList = [];
  final List<String> _playListBackup = [];
  int currentIndex = 0;

  int get playListLength => _playMap.length;
  bool get isNotEmpty => _playMap.isNotEmpty;
  String get currentAudioTitle =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.title : '';

  String audioTitle(int index) => _playMap[_playList[index]]!.title;
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

  void shift(int oldIndex, int newIndex) {
    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (currentIndex == newIndex) {
      if (currentIndex > oldIndex) {
        currentIndex = newIndex - 1;
      } else {
        currentIndex = newIndex + 1;
      }
    } else if (currentIndex > oldIndex && currentIndex < newIndex) {
      currentIndex -= 1;
    } else if (currentIndex < oldIndex && currentIndex > newIndex) {
      currentIndex += 1;
    }
    _playList.insert(newIndex, _playList.removeAt(oldIndex));
    _playListBackup.insert(newIndex, _playListBackup.removeAt(oldIndex));
  }

  void remove(int index) {
    if (currentIndex > index) {
      currentIndex -= 1;
    }
    _playMap.remove(_playList.removeAt(index));
    _playListBackup.removeAt(index);
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
