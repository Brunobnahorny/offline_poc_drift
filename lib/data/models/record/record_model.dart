// ignore_for_file: public_member_api_docs, sort_constructors_first
class Record {
  final String uuidDataset;

  final String uuidPkColumn;
  String get pkValue => mapColumnValues[uuidPkColumn]!;

  final Map<String, dynamic> mapColumnValues;

  const Record({
    required this.uuidDataset,
    required this.uuidPkColumn,
    required this.mapColumnValues,
  });
}
