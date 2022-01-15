import 'package:flutter/material.dart';
import 'api.dart' as api;
import 'models/pr.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _error;
  PR? _pr;

  void _getPR(String prNumber) async {
    setState(() {
      _error = null;
    });

    late final PR localPR;
    try {
      localPR = await api.getPr(prNumber);
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
      return;
    }

    setState(() {
      _pr = localPR;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TODO(justinmc): Loading state.
            if (_pr == null)
              TextField(
                decoration: InputDecoration(
                  hintText: 'PR',
                  errorText: _error,
                ),
                onSubmitted: _getPR,
              ),
            if (_pr != null)
              Text("PR's merge commit is ${_pr!.mergeCommitSHA}"),
          ],
        ),
      ),
    );
  }
}
