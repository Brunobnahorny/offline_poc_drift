import 'dart:convert';

import 'dataset_column_model.dart';

const _kDatasetUuid = 'c5b61220-0122-479c-bf0f-f1c511cd22bf';

const kExampleDatasetConfig = Dataset(
  uuid: _kDatasetUuid,
  title: 'Dataset de exemplo',
  columns: kExampleColumns,
);

class Dataset {
  final String uuid;
  final String title;
  final List<DatasetColumn> columns;

  const Dataset({
    required this.uuid,
    required this.title,
    required this.columns,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uuid': uuid,
      'title': title,
      'columns': columns.map((x) => x.toMap()).toList(),
    };
  }

  factory Dataset.fromMap(Map<String, dynamic> map) {
    return Dataset(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      columns: List<DatasetColumn>.from(
        (map['columns'] as List<int>).map<DatasetColumn>(
          (x) => DatasetColumn.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Dataset.fromJson(String source) =>
      Dataset.fromMap(json.decode(source) as Map<String, dynamic>);
}
