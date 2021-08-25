List<T> listFromMap<T>(Map<String, dynamic> data, String key,
        T Function(Map<String, dynamic> data) itemFromJson) =>
    (data[key] as List).cast<Map<String, dynamic>>().map(itemFromJson).toList();

double doubleFromMap(Map<String, dynamic> data, String key) =>
    (data[key] as num).toDouble();

double? doubleOrNullFromMap(Map<String, dynamic> data, String key) =>
    (data[key] as num?)?.toDouble();

int intFromMap(Map<String, dynamic> data, String key) =>
    (data[key] as num).toInt();

int? intOrNullFromMap(Map<String, dynamic> data, String key) =>
    (data[key] as num?)?.toInt();

DateTime dateTimeFromMap(Map<String, dynamic> data, String key) =>
    DateTime.parse(data[key] as String).toLocal();

extension FromMapExtension on Map<String, dynamic> {
  bool requireBool(String key) => this[key] as bool;

  double requireDouble(String key) => doubleFromMap(this, key);

  double? optionalDouble(String key) => doubleOrNullFromMap(this, key);

  int requireInt(String key) => intFromMap(this, key);

  int? optionalInt(String key) => intOrNullFromMap(this, key);

  DateTime requireDateTime(String key) => dateTimeFromMap(this, key);

  List<T> requireList<T>(
          String key, T Function(Map<String, dynamic> data) itemFromJson) =>
      listFromMap(this, key, itemFromJson);

  List<T>? optionalList<T>(
          String key, T Function(Map<String, dynamic> data) itemFromJson) =>
      this[key] != null ? listFromMap(this, key, itemFromJson) : null;

  T? optional<T>(String key, T Function(Map<String, dynamic> data) fromJson) =>
      this[key] != null ? fromJson(this[key] as Map<String, dynamic>) : null;
}
