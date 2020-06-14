import 'package:ProjectEuler/problem.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'problem.dart';

// any name for the .db file is fine; the class name is Floor<name of db class>
const String DB_NAME = "proj_euler2.db";

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final database = await $FloorAppDatabase.databaseBuilder(DB_NAME).build();
  final problemDao = database.problemDao;
  runApp(ProjEulerApp(problemDao));
}

class ProjEulerApp extends StatelessWidget {
  final ProblemDao problemDao;
  ProjEulerApp(this.problemDao);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Euler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProblemList(problemDao: problemDao),
    );
  }
}

class ProblemList extends StatefulWidget {
  final ProblemDao problemDao;
  ProblemList({Key key, this.problemDao}) : super(key: key);

  @override
  _ProblemListState createState() => _ProblemListState(problemDao);
}

class _ProblemListState extends State<ProblemList> {
  final ProblemDao problemDao;
  bool loading = false;
  List<Problem> problems = [];
  List<bool> expanded = [];

  _ProblemListState(this.problemDao) {
    loading = true;
    loadProblems();
  }

  Future<void> loadProblems() async {
    // int maxProblemId = await getMaxProblemId();
    // int currentMaxId = await getMaxProblemStoredId();
    // if (maxProblemId > currentMaxId) {
    //   for (int problemId = currentMaxId + 1; problemId <= maxProblemId; problemId++) {
    //     Map<String, Object> problemDict = await getProblem(problemId);
    //     assert(problemDict != null);
    //     Problem problem = Problem(problemDict["id"], problemDict["title"], problemDict["content"]);
    //     widget.problemDao.insertProblem(problem);
    //     problems.add(problem);
    //   }
    //   updateMaxProbleStoredId(maxProblemId);
    // }

    final List<Problem> allProblems = await problemDao.getAllProblems();
    setState(() {
      problems = allProblems;
      expanded = List<bool>.generate(problems.length, (index) => false);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingOrList;
    if (loading) {
      loadingOrList = Text("Loading");
    } else {
      loadingOrList = ListView.builder(
        itemCount: problems.length,
        itemBuilder: (BuildContext context, int index) {
          final Problem problem = problems[index];
          void onTap() {
            debugPrint("tapped $index");
            setState(() {
              expanded[index] = !expanded[index];
            });
          }
          return ProblemWidget(problem.id, problem.shortTitle(), problem.content, expanded[index], onTap);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Problems"),
      ),
      body: Center(
        child: loadingOrList,
      ),
    );
  }
}
