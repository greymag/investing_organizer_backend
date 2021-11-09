import 'package:in_date_range/in_date_range.dart';
import 'package:in_date_utils/in_date_utils.dart';

class Statement {
  final String brokerName;
  final String brokerAddress;
  final String title;
  final DateRange period;
  // TODO: DateTime
  final String whenGenerated;

  Statement(this.brokerName, this.brokerAddress, this.title, this.period,
      this.whenGenerated);

  factory Statement.fromMap(Map<String, dynamic> map) {
    return Statement(
      map['brokerName'] as String,
      map['brokerAddress'] as String,
      map['title'] as String,
      _parsePeriod(map['period'] as String),
      map['whenGenerated'] as String,
    );
  }

  @override
  String toString() {
    return 'Statement(brokerName: $brokerName, brokerAddress: $brokerAddress, '
        'title: $title, period: $period, whenGenerated: $whenGenerated)';
  }
}

// TODO: tests
DateRange _parsePeriod(String value) {
  // October 18, 2021 - October 22, 2021
  final arr = value.split('-');
  return DateRange(
    _parseDate(arr[0].trim()),
    DateUtils.nextDay(_parseDate(arr[1].trim())),
  );
}

DateTime _parseDate(String value) {
  final arr = value.split(',');
  final arr2 = arr.first.split(' ');

  final monthStr = arr2[0];
  final dateStr = arr2[1];
  final yearStr = arr[1].trim();

  return DateTime(
      int.parse(yearStr), _parseMonth(monthStr), int.parse(dateStr));
}

const _months = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

int _parseMonth(String value) {
  return _months.indexOf(value.toLowerCase()) + 1;
}
