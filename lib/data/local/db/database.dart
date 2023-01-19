import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:faker/faker.dart';
import 'package:flutter/foundation.dart';
import 'package:offline_poc_drift/data/models/dataset_config/dataset_column_model.dart';
import 'package:offline_poc_drift/data/models/dataset_config/dataset_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import '../../models/filter/filter_model.dart';
import '../../models/record/record_model.dart';

part 'database.g.dart';

late final MyDatabase dbSingleton;

@DriftDatabase(tables: [])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition.
  // Migrations are covered later in the documentation.
  @override
  int get schemaVersion => 1;

  Future<bool> generateDatasetTable(
    Dataset dataset,
  ) async {
    final List<String> columnStatements = dataset.columns.map(
      (e) {
        final pk = e.uuid == dataset.uuidPkColumn;
        if (pk) {
          return '"${e.uuid}" INTEGER PRIMARY KEY AUTOINCREMENT';
        } else {
          return '"${e.uuid}" ${_parseSqlDataType(e.type)}';
        }
      },
    ).toList();

    final tableName = '"${dataset.uuid}"';
    final ftsTableName = '"${dataset.uuid}_search"';
    final statement = '''
      DROP TABLE IF EXISTS $tableName;
      DROP TABLE IF EXISTS $ftsTableName;

      CREATE TABLE $tableName(
        ${columnStatements.join(', \n')}
      );
    ''';

    final fts5Columns = dataset.columns
        .where((e) => e.uuid != dataset.uuidPkColumn)
        .map((e) => '"${e.uuid}"');
    final fts5Statement = '''
      CREATE VIRTUAL TABLE $ftsTableName
      USING FTS5(${fts5Columns.join(',')}, content='${dataset.uuid}', content_rowid='${dataset.uuidPkColumn}');
    ''';

    final fts5Trigger = '''
      CREATE TRIGGER "${dataset.uuid}_ai" AFTER INSERT ON $tableName BEGIN
        INSERT INTO $ftsTableName(rowid, ${fts5Columns.join(',')}) VALUES (new."${dataset.uuidPkColumn}", ${fts5Columns.map((e) => 'new.$e').join(',')});
      END;

      CREATE TRIGGER "${dataset.uuid}_ad" AFTER DELETE ON $tableName BEGIN
        INSERT INTO $ftsTableName($ftsTableName, rowid, ${fts5Columns.join(',')}) VALUES('delete', old."${dataset.uuidPkColumn}", ${fts5Columns.map((e) => 'old.$e').join(',')});
      END;

      CREATE TRIGGER "${dataset.uuid}_au" AFTER UPDATE ON $tableName BEGIN
        INSERT INTO $ftsTableName($ftsTableName, rowid, ${fts5Columns.join(',')}) VALUES('delete', old."${dataset.uuidPkColumn}", ${fts5Columns.map((e) => 'old.$e').join(',')});
        INSERT INTO $ftsTableName(rowid, ${fts5Columns.join(',')}) VALUES (new."${dataset.uuidPkColumn}", ${fts5Columns.map((e) => 'new.$e').join(',')});
      END;
    ''';

    final result = await dbSingleton.doWhenOpened<bool>(
      (exec) async {
        await exec.beginTransaction().runCustom(
              statement,
            );
        await exec.runCustom(fts5Statement, []);
        await exec.runCustom(fts5Trigger, []);

        final results = await exec.runSelect(
          "SELECT name FROM sqlite_master WHERE type='table';",
          [],
        );

        log(results.map((e) => e['name']).join(','));

        return results.any((result) =>
            result['name'].toString() == tableName.replaceAll('"', ''));
      },
    );

    return result;
  }

  Future<bool> populateDataset(
    Dataset dataset,
    List<Record> records,
  ) async {
    final tableName = '"${dataset.uuid}"';
    final columnsNameList = dataset.columns
        .where((col) => col.uuid != dataset.uuidPkColumn)
        .map((e) => '"${e.uuid}"')
        .join(',');
    final mapDatasetColumnType = Map<String, ColumnType>.fromEntries(
        dataset.columns.map((e) => MapEntry(e.uuid, e.type)));

    final Iterable<String> insertStatementsLines = records.map(
      (record) {
        final uuidColumns = dataset.columns.map((e) => e.uuid);
        final recordValue =
            uuidColumns.where((e) => e != dataset.uuidPkColumn).map((e) {
          final columnType = mapDatasetColumnType[e]!;
          final columnValue = record.mapColumnValues[e];
          return _parseColumnValueInsert(columnType, columnValue);
        }).join(',');
        return '($recordValue)';
      },
    );

    final statement = '''
      INSERT INTO $tableName ($columnsNameList)
      VALUES  ${insertStatementsLines.join(',\n')};
    ''';

    final result = await dbSingleton.doWhenOpened<bool>(
      (exec) async {
        final result = await exec.beginTransaction().runInsert(
          statement,
          [],
        );

        return result == records.length;
      },
    );

    return result;
  }

  Future<List<Record>> queryDataset(
    Dataset dataset,
    List<Filter> searchFilters,
  ) async {
    final tableName = '"${dataset.uuid}_search"';
    final patternsMap = {};
    for (final filter in searchFilters) {
      patternsMap[filter.uuidCol] = patternsMap[filter.uuidCol] != null
          ? '${patternsMap[filter.uuidCol]} ${filter.searchValue}'
          : filter.searchValue;
    }
    final patternsStatement =
        patternsMap.entries.map((e) => "\"${e.key}\" MATCH '${e.value}'");

    final statement = '''
      SELECT *
      FROM $tableName
      ${patternsStatement.isNotEmpty ? "WHERE" : ""}        
      ${patternsStatement.join(" AND \n")}
      LIMIT 100;
    ''';

    log(statement);

    final result = await dbSingleton.doWhenOpened<List<Map<String, Object?>>>(
      (exec) async => await exec.beginTransaction().runSelect(
        statement,
        [],
      ),
    );

    return result.map((e) {
      final Map<String, dynamic> mapColumnValues = e.map(
        (key, value) => MapEntry(
          key.replaceFirst('col_', '').paramCase,
          value as dynamic,
        ),
      );

      return Record(
        uuidDataset: dataset.uuid,
        uuidPkColumn: dataset.uuidPkColumn,
        mapColumnValues: mapColumnValues,
      );
    }).toList();
  }

  Future<bool> insertRandomRecords(int quantity) async {
    final records =
        await compute<int, List<Record>>(_generateRandomRecords, quantity);

    log('Começou popular tabela ${DateTime.now().toIso8601String()}');

    final result = await populateDataset(
      kExampleDatasetConfig,
      records,
    );

    log('Terminou de popular tabela ${DateTime.now().toIso8601String()}');

    await _countRecordInTable(kExampleDatasetConfig);

    return result;
  }

  Future<int> _countRecordInTable(Dataset dataset) async {
    final tableName = '"${dataset.uuid}"';
    final statement = ''' 
      SELECT COUNT(*) FROM  $tableName;
    ''';
    final ftsTableName = '"${dataset.uuid}_search"';
    final ftsStatement = ''' 
      SELECT COUNT(*) FROM  $ftsTableName;
    ''';

    final result = await dbSingleton.doWhenOpened<int>(
      (exec) async {
        final result = await exec.beginTransaction().runSelect(
          statement,
          [],
        );

        return result.first.values.first as int;
      },
    );

    final result2 = await dbSingleton.doWhenOpened<int>(
      (exec) async {
        final result = await exec.beginTransaction().runSelect(
          ftsStatement,
          [],
        );

        return result.first.values.first as int;
      },
    );

    log('TABLE $tableName HAS $result RECORDS');
    log('TABLE $ftsTableName HAS $result2 RECORDS');

    return result;
  }
}

dynamic _parseColumnValueInsert(ColumnType columnType, dynamic columnValue) {
  if (columnValue == null) return "NULL";

  switch (columnType) {
    case ColumnType.text:
    case ColumnType.location:
    case ColumnType.date:
    case ColumnType.selection:
      return "'$columnValue'";
    case ColumnType.number:
      return columnValue;
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

String _parseSqlDataType(ColumnType type) {
  switch (type) {
    case ColumnType.number:
      return 'REAL';

    case ColumnType.text:
    case ColumnType.date:
    case ColumnType.location:
    case ColumnType.selection:
      return 'TEXT';
  }
}

List<Record> _generateRandomRecords(int quantity) {
  return [
    for (var i = 0; i < quantity; i++)
      Record(
        uuidDataset: kExampleDatasetConfig.uuid,
        uuidPkColumn: kExampleDatasetConfig.uuidPkColumn,
        mapColumnValues: {
          for (final column in kExampleDatasetConfig.columns)
            column.uuid: _generateColumnValue(column.type),
        },
      )
  ];
}

_generateColumnValue(ColumnType type) {
  final nullValue = faker.randomGenerator.integer(10) > 7;
  if (nullValue) return null;
  switch (type) {
    case ColumnType.text:
    case ColumnType.location:
      return faker.lorem.sentence();
    case ColumnType.number:
      return faker.randomGenerator.decimal();
    case ColumnType.date:
      return faker.date.dateTime().toIso8601String();
    case ColumnType.selection:
      return "[${faker.lorem.sentence().split(' ').join(',')}]";
  }
}

bool _hasFTS(DatasetColumn e) =>
    e.type != ColumnType.date && e.type != ColumnType.number;
