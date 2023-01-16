import 'package:flutter/material.dart';
import 'package:offline_poc_drift/data/models/dataset_config/dataset_model.dart';
import 'package:offline_poc_drift/data/models/record/record_model.dart';

import '../../../data/models/dataset_config/dataset_column_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController tec = TextEditingController();
  final dropDownValues = kExampleDatasetConfig.columns
      .map(
        (e) => DropdownMenuItem<DatasetColumn>(
          value: e,
          child: Text(e.title),
        ),
      )
      .toList();
  final List<Record> recordsList = [];
  DatasetColumn selectedColumn = kExampleDatasetConfig.columns.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drift db test'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Container(
            height: constraints.maxHeight,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: tec,
                  onChanged: (_) => changeSearch(),
                ),
                DropdownButton(
                  items: dropDownValues,
                  onChanged: selectColumn,
                  value: selectedColumn,
                  selectedItemBuilder: (BuildContext context) {
                    return kExampleDatasetConfig.columns
                        .map<Widget>((DatasetColumn column) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        constraints: const BoxConstraints(minWidth: 100),
                        child: Text(
                          column.title,
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList();
                  },
                ),
                //query results
                Expanded(
                  child: RecordsList(
                    //@TODO implementar
                    recordsList: recordsList,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void selectColumn(DatasetColumn? column) {
    if (column == null) return;

    setState(() {
      selectedColumn = column;
    });
    changeSearch();
  }

  changeSearch() {
    print('Selected Value: ${tec.text}');
    print('Selected Column: ${selectedColumn.title}');

    //set state with search and recordList setter
  }
}

class RecordsList extends StatelessWidget {
  final List<Record> recordsList;

  const RecordsList({
    super.key,
    required this.recordsList,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: recordsList.length,
      itemBuilder: (context, index) {
        final record = recordsList[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: record.mapColumnValues.entries
                  .map(
                    (entry) => Row(
                      children: [
                        Text('${entry.key}: '),
                        Text(
                          entry.value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}