class Statement {
  final String brokerName;
  final String brokerAddress;
  final String title;
  final String period;
  final String whenGenerated;

  Statement(this.brokerName, this.brokerAddress, this.title, this.period,
      this.whenGenerated);
  @override
  String toString() {
    return 'Statement(brokerName: $brokerName, brokerAddress: $brokerAddress, '
        'title: $title, period: $period, whenGenerated: $whenGenerated)';
  }
}
