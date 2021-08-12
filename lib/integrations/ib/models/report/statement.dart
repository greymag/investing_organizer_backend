class Statement {
  final String brokerName;
  final String brokerAddress;
  final String title;
  // TODO: DateRange
  final String period;
  // TODO: DateTime
  final String whenGenerated;

  Statement(this.brokerName, this.brokerAddress, this.title, this.period,
      this.whenGenerated);

  factory Statement.fromMap(Map<String, dynamic> map) {
    return Statement(
      map['brokerName'] as String,
      map['brokerAddress'] as String,
      map['title'] as String,
      map['period'] as String,
      map['whenGenerated'] as String,
    );
  }

  @override
  String toString() {
    return 'Statement(brokerName: $brokerName, brokerAddress: $brokerAddress, '
        'title: $title, period: $period, whenGenerated: $whenGenerated)';
  }
}
