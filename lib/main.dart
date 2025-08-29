import 'package:flutter/material.dart';
import 'package:mapa_testes/workflow_model.dart';
import 'package:mapa_testes/workflow_page.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkflowModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dynamic Workflow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: const WorkflowPage(),
    );
  }
}

abstract class DefaultColors {
  static const Color primary = Color(0xFF006874);
  static const Color secondary = Color(0xFF46C8BC);
  static const Color secondary2 = Color(0xFFCCE0DC);
}

