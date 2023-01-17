import 'dart:convert';

const pkColumn = 'facdd1a1-120e-4e6f-8db8-d8566f613c25';
const _column2 = '4c3a6d81-24ba-4d78-b0dc-4deba04c33e0';
const _column3 = '81f11cc3-4694-425e-b047-3a66c9b742cf';
const _column4 = '6f7f18ff-6057-4dac-8aa7-9a6662479bb9';
const _column5 = 'ad56900d-e26a-47c8-a940-07b73a97f666';
const _column6 = 'afb6ed8d-c8e1-4bf0-bf7d-69e35ef179fd';

const List<DatasetColumn> kExampleColumns = [
  DatasetColumn(
    uuid: pkColumn,
    title: '1-texto',
    type: ColumnType.text,
  ),
  DatasetColumn(
    uuid: _column2,
    title: '2-texto',
    type: ColumnType.text,
  ),
  DatasetColumn(
    uuid: _column3,
    title: '3-number',
    type: ColumnType.number,
  ),
  DatasetColumn(
    uuid: _column4,
    title: '4-date',
    type: ColumnType.date,
  ),
  DatasetColumn(
    uuid: _column5,
    title: '5-location',
    type: ColumnType.location,
  ),
  DatasetColumn(
    uuid: _column6,
    title: '6-selection',
    type: ColumnType.selection,
  )
];

enum ColumnType {
  text,
  number,
  date,
  location,
  selection,
}

class DatasetColumn {
  final String uuid;
  final String title;
  final ColumnType type;

  const DatasetColumn({
    required this.uuid,
    required this.title,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uuid': uuid,
      'title': title,
      'type': type.name,
    };
  }

  factory DatasetColumn.fromMap(Map<String, dynamic> map) {
    return DatasetColumn(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      type: ColumnType.values.firstWhere((type) => map['type'] == type),
    );
  }

  String toJson() => json.encode(toMap());

  factory DatasetColumn.fromJson(String source) =>
      DatasetColumn.fromMap(json.decode(source) as Map<String, dynamic>);
}
