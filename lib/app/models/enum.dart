enum PlayerLoopMode {
  off,
  one,
  all,
}

enum PlayListOrderState {
  none,
  ascending,
  descending,
  shuffled,
}

enum PlayListOrderMethod {
  title('title'),
  modifiedDateTime('modifiedDateTime'),
  undefined('undefined');

  const PlayListOrderMethod(this.code);
  final String code;

  factory PlayListOrderMethod.toEnum(String code) {
    return PlayListOrderMethod.values.firstWhere((value) => value.code == code,
        orElse: () => PlayListOrderMethod.undefined);
  }

  @override
  String toString() {
    return code;
  }
}

enum BackgroundMethod {
  normal('normal'),
  random('random'),
  specific('specific'),
  undefined('undefined');

  const BackgroundMethod(this.code);
  final String code;

  factory BackgroundMethod.toEnum(String code) {
    return BackgroundMethod.values.firstWhere((value) => value.code == code,
        orElse: () => BackgroundMethod.undefined);
  }

  @override
  String toString() {
    return code;
  }
}
