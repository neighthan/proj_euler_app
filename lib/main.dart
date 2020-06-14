import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;


void main() {
  runApp(ProjEulerApp());
}

class ProjEulerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProblemList(title: 'Problems'),
    );
  }
}

class ProblemList extends StatefulWidget {
  final String title;
  ProblemList({Key key, this.title}) : super(key: key);

  @override
  _ProblemListState createState() => _ProblemListState();
}

Future getProblem(int id) async {
  Client client = Client();
  Response response = await client.get(
    'https://projecteuler.net/problem=$id'
  );
  dom.Document document = parse(response.body);
  String title = document.querySelector("#content > h2").text;
  if (title == "Problems Archive") {
    return null;
  }
  String content = document.querySelector("#content > .problem_content").text;
  return {"id": id, "title": title, "content": content};
}

class _ProblemListState extends State<ProblemList> {
  int problemId = 0;
  String title = "";
  String content = "";


  void _nextProblem() async {
    problemId++;
    var problem = await getProblem(problemId);
    print(problem);
    setState(() {
      title = problem["title"];
      content = problem["content"];
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
            Text('Problem $problemId'),
            Text(title),
            Text(content),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _nextProblem,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
