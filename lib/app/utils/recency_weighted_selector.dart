import 'dart:math';

class RecencyWeightedCandidate<T> {
  const RecencyWeightedCandidate({
    required this.key,
    required this.value,
    required this.recency,
  });

  final String key;
  final T value;
  final DateTime recency;
}

class RecencyWeightedSelector<T> {
  RecencyWeightedSelector({Random? random}) : _random = random ?? Random();

  final Random _random;
  List<RecencyWeightedCandidate<T>> _candidates = [];
  Map<String, RecencyWeightedCandidate<T>> _candidateByKey = {};
  Map<String, double> _recencyScoreByKey = {};
  Map<String, int> _recencyBucketSizeByKey = {};
  final Map<String, int> _lastSelectionByKey = {};
  List<String> _remainingKeys = [];
  String? _lastSelectedKey;
  int _selectionCount = 0;

  bool get isNotEmpty => _candidates.isNotEmpty;

  void replace(Iterable<RecencyWeightedCandidate<T>> candidates) {
    final nextCandidates = candidates.toList();
    final nextCandidateByKey = <String, RecencyWeightedCandidate<T>>{};
    for (final candidate in nextCandidates) {
      if (nextCandidateByKey.containsKey(candidate.key)) {
        throw StateError('Duplicate recency candidate key: ${candidate.key}');
      }
      nextCandidateByKey[candidate.key] = candidate;
    }

    _candidates = nextCandidates;
    _candidateByKey = nextCandidateByKey;
    _recencyScoreByKey = _buildRecencyScores(nextCandidates);
    _recencyBucketSizeByKey = _buildRecencyBucketSizes(nextCandidates);
    _lastSelectionByKey.clear();
    _lastSelectedKey = null;
    _selectionCount = 0;
    _refillRemainingKeys();
  }

  T? next({required double recencyWeight}) {
    if (recencyWeight < 0 || recencyWeight > 1) {
      throw RangeError.range(recencyWeight, 0, 1, 'recencyWeight');
    }
    if (_candidates.isEmpty) {
      return null;
    }

    final selectedKey = recencyWeight == 0
        ? _nextWithoutReuse()
        : _nextWeighted(recencyWeight);
    _recordSelection(selectedKey);
    return _candidateByKey[selectedKey]!.value;
  }

  String _nextWithoutReuse() {
    if (_remainingKeys.isEmpty) {
      _refillRemainingKeys();
    }
    return _remainingKeys.removeLast();
  }

  String _nextWeighted(double recencyWeight) {
    final selectable = _candidates
        .where(
          (candidate) =>
              _candidates.length == 1 || candidate.key != _lastSelectedKey,
        )
        .toList();
    final weights = <double>[];
    var totalWeight = 0.0;
    final concentration = 12 * recencyWeight;
    final totalRecencyPriority = _recencyScoreByKey.values
        .toSet()
        .map((score) => exp(-concentration * (1 - score)))
        .reduce((total, priority) => total + priority);
    for (final candidate in selectable) {
      final recencyScore = _recencyScoreByKey[candidate.key]!;
      final recencyPriority = exp(-concentration * (1 - recencyScore));
      final uniformProbability = 1 / _candidates.length;
      final recencyProbability =
          recencyPriority /
          totalRecencyPriority /
          _recencyBucketSizeByKey[candidate.key]!;
      final baseWeight =
          (1 - recencyWeight) * uniformProbability +
          recencyWeight * recencyProbability;
      final weight =
          baseWeight * _reuseAvailability(candidate.key, recencyWeight);
      weights.add(weight);
      totalWeight += weight;
    }

    if (totalWeight == 0) {
      return selectable[_random.nextInt(selectable.length)].key;
    }

    var target = _random.nextDouble() * totalWeight;
    for (var index = 0; index < selectable.length; index++) {
      target -= weights[index];
      if (target <= 0) {
        return selectable[index].key;
      }
    }
    return selectable.last.key;
  }

  double _reuseAvailability(String key, double recencyWeight) {
    final lastSelection = _lastSelectionByKey[key];
    if (lastSelection == null || _candidates.length <= 2) {
      return 1;
    }
    final cooldown =
        1 + ((_candidates.length - 2) * (1 - recencyWeight)).round();
    final selectionsSinceUse = _selectionCount - lastSelection;
    return (selectionsSinceUse / cooldown).clamp(0.0, 1.0).toDouble();
  }

  void _recordSelection(String key) {
    _selectionCount++;
    _lastSelectionByKey[key] = _selectionCount;
    _lastSelectedKey = key;
    _remainingKeys.remove(key);
  }

  void _refillRemainingKeys() {
    _remainingKeys = _candidates.map((candidate) => candidate.key).toList();
    _remainingKeys.shuffle(_random);
    if (_remainingKeys.length > 1 && _remainingKeys.last == _lastSelectedKey) {
      final first = _remainingKeys.first;
      _remainingKeys[0] = _remainingKeys.last;
      _remainingKeys[_remainingKeys.length - 1] = first;
    }
  }

  Map<String, double> _buildRecencyScores(
    List<RecencyWeightedCandidate<T>> candidates,
  ) {
    final timestamps =
        candidates
            .map((candidate) => candidate.recency.microsecondsSinceEpoch)
            .toSet()
            .toList()
          ..sort();
    if (timestamps.length <= 1) {
      return {for (final candidate in candidates) candidate.key: 1};
    }

    final scoreByTimestamp = <int, double>{};
    for (var index = 0; index < timestamps.length; index++) {
      final rank = index / (timestamps.length - 1);
      scoreByTimestamp[timestamps[index]] = rank;
    }
    return {
      for (final candidate in candidates)
        candidate.key:
            scoreByTimestamp[candidate.recency.microsecondsSinceEpoch]!,
    };
  }

  Map<String, int> _buildRecencyBucketSizes(
    List<RecencyWeightedCandidate<T>> candidates,
  ) {
    final sizeByTimestamp = <int, int>{};
    for (final candidate in candidates) {
      final timestamp = candidate.recency.microsecondsSinceEpoch;
      sizeByTimestamp[timestamp] = (sizeByTimestamp[timestamp] ?? 0) + 1;
    }
    return {
      for (final candidate in candidates)
        candidate.key:
            sizeByTimestamp[candidate.recency.microsecondsSinceEpoch]!,
    };
  }
}
