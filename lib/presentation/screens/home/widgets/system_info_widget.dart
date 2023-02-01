import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:system_info2/system_info2.dart';

import '../../../../data/local/db/database.dart';
import '../../../../data/models/dataset_config/dataset_model.dart';

const int kMEGABYTE = 1024 * 1024;

class SystemInfo extends StatefulWidget {
  const SystemInfo({super.key});

  @override
  State<SystemInfo> createState() => _SystemInfoState();
}

class _SystemInfoState extends State<SystemInfo> {
  String totalPhysicalMemory = '--';
  String freePhysicalMemory = '--';
  String totalVirtualMemory = '--';
  String virtualMemorySize = '--';
  String freeVirtualMemory = '--';
  String recordsCount = '--';

  _setSystemInfo() async {
    //sadly doesnt work in release
    if (kDebugMode) {
      totalPhysicalMemory =
          'Total physical memory: ${SysInfo.getTotalPhysicalMemory() ~/ kMEGABYTE} MB';
      freePhysicalMemory =
          'Free physical memory: ${SysInfo.getFreePhysicalMemory() ~/ kMEGABYTE} MB';
      totalVirtualMemory =
          'Total virtual memory: ${SysInfo.getTotalVirtualMemory() ~/ kMEGABYTE} MB';
      virtualMemorySize =
          'Free virtual memory: ${SysInfo.getVirtualMemorySize() ~/ kMEGABYTE} MB';
      freeVirtualMemory =
          'Virtual memory size: ${SysInfo.getFreeVirtualMemory() ~/ kMEGABYTE} MB';
    }
    try {
      final mainDatasetCount =
          await dbSingleton.countRecordInTable(kExampleDatasetConfig);
      final anotherDatasetCount =
          await dbSingleton.countRecordInTable(kExampleAnotherDatasetConfig);

      recordsCount = '${mainDatasetCount + anotherDatasetCount} registros';
    } catch (e) {
      //DO NOTHING
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        IconButton(
          onPressed: () async {
            await _setSystemInfo();
            setState(() {});
          },
          icon: const Icon(Icons.repeat),
        ),
        if (kDebugMode) ...[
          Text(totalPhysicalMemory),
          Text(freePhysicalMemory),
          Text(totalVirtualMemory),
          Text(virtualMemorySize),
          Text(freeVirtualMemory),
        ],
        Text(recordsCount),
      ],
    );
  }
}
