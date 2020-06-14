import 'package:ProjectEuler/data_utils.dart';
import 'package:ProjectEuler/problem.dart';
import 'package:flutter/material.dart';
import 'package:floor/floor.dart';
import 'package:scoped_model/scoped_model.dart';
import 'database.dart';
import 'problem.dart';
import 'code.dart';
import 'settings.dart';

// any name for the .db file is fine; the class name is Floor<name of db class>
const String DB_NAME = "proj_euler2.db";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final List<Migration> migrations = [
    Migration(1, 2, (database) async {
      await database.execute(
          "ALTER TABLE Problem ADD COLUMN favorited INTEGER DEFAULT 0");
    }),
    Migration(2, 3, (database) async {
      await database.execute(
          "CREATE TABLE IF NOT EXISTS Code (id INTEGER, language TEXT, code TEXT, PRIMARY KEY (id))");
    }),
  ];

  final database = await $FloorAppDatabase
      .databaseBuilder(DB_NAME)
      .addMigrations(migrations)
      .build();
  runApp(ProjEulerApp(database));
}

class ProjEulerApp extends StatelessWidget {
  final database;
  ProjEulerApp(this.database);

  @override
  Widget build(BuildContext context) {
    return ScopedModel<ProblemModel>(
      model: ProblemModel(database),
      child: MaterialApp(
        title: 'Project Euler',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ScopedModelDescendant<ProblemModel>(
          builder: (BuildContext context, child, ProblemModel model) =>
              ProblemList(model),
        ),
      ),
    );
  }
}

class ProblemList extends StatefulWidget {
  final ProblemModel problemModel;
  ProblemList(this.problemModel);

  @override
  _ProblemListState createState() => _ProblemListState(problemModel);
}

class _ProblemListState extends State<ProblemList> {
  final ProblemModel problemModel;
  bool loading;
  bool showingFavorites = false;
  List<Problem> visibleProblems;

  _ProblemListState(this.problemModel) {
    loading = true;
    loadProblems();
  }

  Future<void> loadProblems() async {
    await problemModel.loadProblems();
    setState(() {
      visibleProblems = problemModel.visibleProblems;
      loading = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    Widget loadingOrList;
    if (loading) {
      loadingOrList = Text("Loading");
    } else {
      loadingOrList = ListView.builder(
        itemCount: visibleProblems.length,
        itemBuilder: (BuildContext context, int index) {
          return ScopedModelDescendant<ProblemModel>(
              builder:
                  (BuildContext context, Widget child, ProblemModel model) =>
                      ProblemWidget(
                          key: UniqueKey(),
                          problem: visibleProblems[index],
                          problemModel: model));
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
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => navigateToSettings(context),
          ),
        ],
      ),
      body: Center(
        child: loadingOrList,
      ),
    );
  }

  void toggleShowingFavorites() {
    // I use setState here instead of having the model notifyListeners because
    // no other widgets should need updating based on this call
    setState(() {
      showingFavorites = !showingFavorites;
      visibleProblems = problemModel.toggleOnlyFavoritesVisible();
    });
  }

  void navigateToSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Settings();
    }));
  }
}
