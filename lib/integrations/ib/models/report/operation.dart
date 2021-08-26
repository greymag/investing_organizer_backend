abstract class Operation {
  String get currency;
  DateTime get date;
  String get description;
  double get amount;

  String? get ticker {
    // TODO: ticker from desc
    return description;
  }
}
