import '../models/audio_track.dart';
import './preference.dart';
import './stream_controller.dart';
import '../models/play_list_order.dart';

class PlayList {
  PlayList._();
  static final PlayList _instance = PlayList._();
  static PlayList get instance => _instance;

  final Map<String, AudioTrack> _playMap = {};
  final List<String> _playList = [];
  final List<String> _playListBackup = [];

  int currentIndex = 0;
  PlayListOrderState _playListOrderState = PlayListOrderState.none;

  Map<String, AudioTrack> get playMap => _playMap;
  List<String> get playList => _playList;
  int get playListLength => _playMap.length;
  bool get isNotEmpty => _playMap.isNotEmpty;
  String get currentAudioTitle =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.title : '';
  String get currentAudioPath =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.path : '';
  int? get currentAudioColor =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.color : null;
  String? get currentAudioBackground =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.background : null;
  PlayListOrderState get playListOrderState => _playListOrderState;
  AudioTrack? get currentAudioTrack =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]! : null;

  String audioTitle(int index) => _playMap[_playList[index]]!.title;
  AudioTrack? audioTrack(int index) =>
      isNotEmpty ? _playMap[(_playList[index])]! : null;
  void setCurrentAudioColor(int color) =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.color = color : null;
  void setCurrentAudioBackground(String background) => isNotEmpty
      ? _playMap[(_playList[currentIndex])]!.background = background
      : null;

  // only Web Mode
  List<int> get currentbyteData =>
      _playMap[_playList[currentIndex]]!.file!.bytes!.cast<int>();

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
    _playListBackup.insert(newIndex, _playListBackup.removeAt(oldIndex));
  }

  void remove(int index) {
    if (currentIndex > index) {
      currentIndex -= 1;
    }
    _playMap.remove(_playList.removeAt(index));
    _playListBackup.removeAt(index);
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
      String currentKey = _playList[currentIndex];
      for (int i = 0; i < _playList.length; i++) {
        _playList[i] = _playListBackup[i];
        if (currentKey == _playList[i]) {
          currentIndex = i;
        }
      }
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
  void sortByModifiedDateTimeAscending() => _playList.sort((a, b) =>
      _playMap[a]!.modifiedDateTime.isBefore(_playMap[b]!.modifiedDateTime)
          ? 1
          : -1);
  void sortByModifiedDateTimeDescending() => _playList.sort((a, b) =>
      _playMap[a]!.modifiedDateTime.isBefore(_playMap[b]!.modifiedDateTime)
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
