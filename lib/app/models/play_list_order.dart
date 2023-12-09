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
