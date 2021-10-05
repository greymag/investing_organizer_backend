abstract class Operation {
  String get currency;
  DateTime get date;
  String get description;
  double get amount;

  String? get ticker {
    return description.split('(').first;
  }
}
