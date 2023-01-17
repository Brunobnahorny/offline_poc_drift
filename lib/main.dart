import 'package:flutter/material.dart';
import 'package:offline_poc_drift/presentation/screens/home/home_screen.dart';

import 'data/local/db/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dbSingleton = MyDatabase();
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        //
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
