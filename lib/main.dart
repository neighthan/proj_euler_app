import 'package:ProjectEuler/data_utils.dart';
import 'package:ProjectEuler/problem.dart';
import 'package:flutter/material.dart';
import 'package:floor/floor.dart';
import 'database.dart';
import 'problem.dart';
import 'code.dart';

// any name for the .db file is fine; the class name is Floor<name of db class>
const String DB_NAME = "proj_euler2.db";

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final migration1to2 = Migration(1, 2, (database) async {
    await database.execute("ALTER TABLE Problem ADD COLUMN favorited INTEGER DEFAULT 0");
  });

  final database = await $FloorAppDatabase
    .databaseBuilder(DB_NAME)
    .addMigrations([migration1to2])
    .build();
  final ProblemDao problemDao = database.problemDao;
  final CodeDao codeDao = database.codeDao;

  List<Problem> fav_probs = await problemDao.getFavoriteProblems();
  debugPrint("fav probs");
  debugPrint(fav_probs.toString());
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
  bool showingFavorites = false;
  List<Problem> problems = [];
  List<Problem> showingProblems = [];
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
      showingProblems = allProblems;
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

          void toggleFavorited() {
            setState(() {
              problem.favorited = problem.favorited == 1 ? 0 : 1;
            });
          }

          return ProblemWidget(
            problem.id,
            problem.shortTitle(),
            problem.content,
            problem.favorited,
            expanded[index],
            onTap,
            toggleFavorited,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Problems"),
        actions: <Widget>[
          IconButton(
            icon: Icon(showingFavorites ? Icons.star : Icons.star_border),
            onPressed: toggleShowingFavorites,
          ),
        ],
      ),
      body: Center(
        child: loadingOrList,
      ),
    );
  }

  toggleShowingFavorites() {
    showingFavorites = !showingFavorites;
    setState(() {
      if (showingFavorites) {
        showingProblems = problems.where((problem) => problem.favorited == 1);
      } else {
        showingProblems = problems;
      }
    });
  }
}
