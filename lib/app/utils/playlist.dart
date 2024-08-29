import '../models/data.dart';
import './preference.dart';
import './stream_controller.dart';
import '../models/enum.dart';

class PlayList {
  PlayList._();
  static final PlayList _instance = PlayList._();
  static PlayList get instance => _instance;

  final Map<String, AudioTrack> _playMap = {};
  final List<String> _playList = [];
  List<String> _playListBackup = [];

  int currentIndex = 0;
  PlayListOrderState _playListOrderState = PlayListOrderState.none;

  Map<String, AudioTrack> get playMap => _playMap;
  List<String> get playList => _playList;
  int get playListLength => _playMap.length;
  bool get isNotEmpty => _playMap.isNotEmpty;
  AudioTrack? get currentAudioTrack =>
      isNotEmpty ? _playMap[(_playList[currentIndex])] : null;
  String get currentAudioTitle =>
      isNotEmpty ? (currentAudioTrack?.title ?? '') : '';
  String get currentAudioPath =>
      isNotEmpty ? (currentAudioTrack?.path ?? '') : '';
  String? get currentAudioColor =>
      isNotEmpty ? currentAudioTrack?.color : null;
  BackgroundData? get currentAudioBackground =>
      isNotEmpty ? currentAudioTrack?.background : null;
  PlayListOrderState get playListOrderState => _playListOrderState;

  String audioTitle(int index) {
    return _playMap[_playList[index]]!.title;
  }
  AudioTrack? audioTrack(int index) =>
      isNotEmpty ? _playMap[(_playList[index])] : null;
  void setAudioColor(int index, String color) =>
      isNotEmpty ? _playMap[(_playList[index])]!.color = color : null;
  void setAudioBackground(int index, BackgroundData background) =>
      isNotEmpty ? _playMap[(_playList[index])]!.background = background : null;

  bool compareIndexWithCurrent(int index) => currentIndex == index;
  void updateTrack(int index, AudioTrack? track) {
    if (isNotEmpty && track != null) {
      _playMap[(_playList[index])] = track;
    }
  }

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
  }

  void remove(int index) {
    if (currentIndex > index) {
      currentIndex -= 1;
    }
    _playMap.remove(_playList.removeAt(index));
  }

  void shuffle() {
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
    _playListOrderState = PlayListOrderState.shuffled;
  }

  void rollback() {
    if (_playList.isNotEmpty) {
      List<String> newBackup = [];
      String currentKey = _playList[currentIndex];
      for (int i = 0, j = 0; i < _playListBackup.length; i++) {
        if(_playMap[_playListBackup[i]] != null) {
          _playList[j] = _playListBackup[i];
          if (currentKey == _playList[j]) {
            currentIndex = j;
          }
          j++; newBackup.add(_playListBackup[i]);
        }
      }
      _playListBackup = newBackup;
    }
    _playListOrderState = PlayListOrderState.none;
  }

  void toggleShuffleMode() {
    if (_playList.isNotEmpty) {
      if (_playListOrderState == PlayListOrderState.shuffled) {
        rollback();
      } else {
        shuffle();
      }
    }
  }

  void sort() {
    if (_playList.isNotEmpty) {
      if (_playListOrderState == PlayListOrderState.ascending) {
        _playListOrderState = PlayListOrderState.descending;
      } else if (_playListOrderState == PlayListOrderState.descending) {
        _playListOrderState = PlayListOrderState.none;
      } else {
        _playListOrderState = PlayListOrderState.ascending;
      }

      if (_playListOrderState == PlayListOrderState.none) {
        rollback();
      } else {
        String currentKey = _playList[currentIndex];
        switch (Preference.playListOrderMethod) {
          case PlayListOrderMethod.title:
            _playListOrderState == PlayListOrderState.ascending
                ? sortByTitleAscending()
                : sortByTitleDescending();
            break;
          case PlayListOrderMethod.modifiedDateTime:
            _playListOrderState == PlayListOrderState.ascending
                ? sortByModifiedDateTimeAscending()
                : sortByModifiedDateTimeDescending();
            break;
          default:
            break;
        }
        for (int i = 0; i < _playList.length; i++) {
          if (currentKey == _playList[i]) {
            currentIndex = i;
            break;
          }
        }
      }
    }

    AudioStreamController.playList.add(null);
    AudioStreamController.playListOrderState.add(null);
  }

  void sortByTitleAscending() => _playList.sort((a, b) => a.compareTo(b));
  void sortByTitleDescending() => _playList.sort((a, b) => b.compareTo(a));
  void sortByModifiedDateTimeAscending() =>
      _playList.sort((a, b) => stringToDateTime(_playMap[a]!.modifiedDateTime)
              .isBefore(stringToDateTime(_playMap[b]!.modifiedDateTime))
          ? 1
          : -1);
  void sortByModifiedDateTimeDescending() =>
      _playList.sort((a, b) => stringToDateTime(_playMap[a]!.modifiedDateTime)
              .isBefore(stringToDateTime(_playMap[b]!.modifiedDateTime))
          ? -1
          : 1);

  void clear() {
    _playMap.clear();
    _playList.clear();
    _playListBackup.clear();
    currentIndex = 0;
    _playListOrderState = PlayListOrderState.none;

    AudioStreamController.playList.add(null);
    AudioStreamController.playListOrderState.add(null);
  }
}
