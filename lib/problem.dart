import 'dart:ffi';

import 'package:ProjectEuler/main.dart';
import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'code.dart';
import 'requests.dart';

@entity
class Problem {
  @primaryKey
  final int id;
  final String title;
  final String content;
  bool favorited;
  bool solved;
  String solution;
  @ignore
  bool expanded = false;

  Problem(this.id, this.title, this.content,
      {this.favorited = false, this.solved = false, this.solution = ""});

  @override
  String toString() {
    return "Problem $id [$favorited] $title.";
  }
}

@dao
abstract class ProblemDao {
  @Query('SELECT * FROM Problem')
  Future<List<Problem>> getAllProblems();

  @Query('SELECT * FROM Problem WHERE id = :id LIMIT 1')
  Future<Problem> getProblem(int id);

  @Query('SELECT * FROM Problem WHERE favorited = 1')
  Future<List<Problem>> getFavoriteProblems();

  @insert
  Future<void> insertProblem(Problem problem);

  @update
  Future<void> updateProblem(Problem problem);

  @Query("DELETE FROM Problem")
  Future<void> deleteAllProblems();
}

// TODO - a ProblemModel and a CodeModel would be better, but
// do this for now since we're switching from scoped-model to
// Provider soon anyway; make the change then.
class ProblemModel extends Model {
  final database;
  final ProblemDao problemDao;
  final CodeDao codeDao;
  bool loading;
  // TODO: maybe make getters with unmodifiable views for these?
  // changes should only happen through ProblemModel so listeners are notified
  List<Problem> allProblems;
  List<Problem> visibleProblems;
  bool onlyFavoritesVisible = false;

  ProblemModel(this.database)
      : problemDao = database.problemDao,
        codeDao = database.codeDao {
    loading = true;
    loadProblems();
  }

  // You can await this to make sure the model is done loading.
  // This isn't expected to notifyListeners
  Future<void> loadProblems() async {
    if (loading) {
      allProblems = await problemDao.getAllProblems();
      visibleProblems = allProblems;
      loading = false;
    }
  }

  // WARNING: this doesn't call notifyListeners; it's used in ProblemList and setState is used instead
  List<Problem> toggleOnlyFavoritesVisible() {
    onlyFavoritesVisible = !onlyFavoritesVisible;
    if (onlyFavoritesVisible) {
      visibleProblems =
          allProblems.where((problem) => problem.favorited).toList();
    } else {
      visibleProblems = allProblems;
    }
    return visibleProblems;
  }

  toggleFavoriteProblem(Problem problem) {
    problem.favorited = !problem.favorited;
    if (onlyFavoritesVisible && !problem.favorited) {
      visibleProblems.remove(problem);
    }
    problemDao.updateProblem(problem);
    notifyListeners();
  }

  Future<Code> getCode(int id) async {
    return codeDao.getCode(id);
  }

  Future<void> insertOrUpdateCode(Code code) async {
    await codeDao.insertOrUpdateCode(code);
  }

  Future<void> addProblemSolution(Problem problem, String solution) async {
    problem.solved = true;
    problem.solution = solution;
    await problemDao.updateProblem(problem);
    notifyListeners();
  }
}

class ProblemWidget extends StatefulWidget {
  final Problem problem;
  final ProblemModel problemModel;
  ProblemWidget(
      {@required Key key, @required this.problem, @required this.problemModel})
      : super(key: key);

  @override
  _ProblemWidgetState createState() =>
      _ProblemWidgetState(problem, problemModel);
}

class _ProblemWidgetState extends State<ProblemWidget> {
  final Problem problem;
  final ProblemModel problemModel;
  _ProblemWidgetState(this.problem, this.problemModel);

  @override
  Widget build(BuildContext context) {
    void goToDetailPage() {
      debugPrint("go to detail page for ${problem.id}");
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return ScopedModelDescendant<ProblemModel>(
                builder:
                    (BuildContext context, Widget child, ProblemModel model) =>
                        ProblemDetailWidget(problem, model));
          },
        ),
      );
    }

    void toggleFavorited() {
      problemModel.toggleFavoriteProblem(problem);
    }

    void toggleExpanded() {
      setState(() {
        problem.expanded = !problem.expanded;
      });
    }

    final listTile = ListTile(
      title: Text(
        "${problem.id}. ${problem.title}",
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(problem.favorited ? Icons.star : Icons.star_border),
        onPressed: toggleFavorited,
      ),
      onTap: toggleExpanded,
      onLongPress: goToDetailPage,
    );

    if (problem.expanded) {
      return Card(
        child: Column(
          children: <Widget>[
            listTile,
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Text(problem.content),
            ),
          ],
        ),
      );
    } else {
      return listTile;
    }
  }
}

class ProblemDetailWidget extends StatefulWidget {
  final Problem problem;
  final ProblemModel problemModel;
  ProblemDetailWidget(this.problem, this.problemModel);

  @override
  _ProblemDetailWidgetState createState() =>
      _ProblemDetailWidgetState(problem, problemModel);
}

class _ProblemDetailWidgetState extends State<ProblemDetailWidget> {
  Problem problem;
  final ProblemModel problemModel;
  final TextEditingController answerController;
  final TextEditingController codeController;
  static const int swipeThreshold = 500; // even higher would probably be fine
  String language = "julia";
  bool loading;
  _ProblemDetailWidgetState(this.problem, this.problemModel)
      : answerController = TextEditingController(),
        codeController = TextEditingController() {
    loading = true;
    loadCode();
  }

  Future<void> loadCode() async {
    Code code = await problemModel.getCode(problem.id);
    if (code != null) {
      codeController.text = code.code;
      language = code.language;
    } else {
      codeController.text = "";
      language = "julia"; // TODO: default language
    }
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    void toggleFavorited() {
      problemModel.toggleFavoriteProblem(problem);
    }

    Widget solutionWidget;

    if (problem.solved) {
      solutionWidget = Text("Solution: ${problem.solution}");
    } else {
      solutionWidget = Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Answer",
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Builder(builder: (BuildContext context) {
              return RaisedButton(
                onPressed: () => submitAnswer(context),
                child: Text("Submit"),
              );
            }),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Problem ${problem.id}"),
        actions: <Widget>[
          IconButton(
            onPressed: copyCode,
            icon: Icon(Icons.content_copy),
          ),
          // to show a snackbar, you need a context that is below Scaffold;
          // extracting things into separate widgets was too much of a pain,
          // so we can use Builder to introduce a new context under Scaffold
          Builder(builder: (BuildContext context) {
            return IconButton(
              onPressed: () => saveCode(context),
              icon: Icon(Icons.save),
            );
          }),
          IconButton(
            onPressed: toggleFavorited,
            icon: Icon(problem.favorited ? Icons.star : Icons.star_border),
          )
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: swipe,
        child: Center(
          child: ListView(
            children: <Widget>[
              Text(problem.title),
              Text(problem.content),
              solutionWidget,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: codeController,
                  autocorrect: false,
                  // enableSuggestions: false,
                  maxLines: null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void swipe(DragEndDetails details) {
    double velX = details.primaryVelocity;
    bool swipeRight = velX < -swipeThreshold;
    bool swipeLeft = velX > swipeThreshold;
    int problemIdx = problemModel.visibleProblems.indexOf(problem);

    int newIdx;
    if (swipeRight) {
      newIdx = problemIdx + 1;
    } else if (swipeLeft) {
      newIdx = problemIdx - 1;
    } else {
      return;
    }

    if (newIdx < 0 || newIdx >= problemModel.visibleProblems.length) {
      return; // out of range
    }

    setState(() {
      problem = problemModel.visibleProblems[newIdx];
      answerController.text = "";
      loading = true;
      loadCode();
    });
  }

  void submitAnswer(BuildContext context) async {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Submitting answer."),
    ));
    debugPrint(
        "submitted answer ${answerController.text} for problem ${problem.id}.");
    final String solution = answerController.text;
    int ret = await postSolution(problem.id, solution);
    debugPrint("submit return = $ret");
    String snackbarMsg;
    Color color;
    if (ret == CORRECT) {
      problemModel.addProblemSolution(problem, solution);
      snackbarMsg = "Correct answer!";
      color = Colors.green;
    } else if (ret == INCORRECT) {
      snackbarMsg = "Incorrect answer.";
      color = Colors.red;
    } else if (ret == ERROR) {
      // TODO: have postSolution return something more specific so we know what the error was.
      // probably just have it return a string instead of an int? Then we show that string
      // directly as the message. The color we can figure out.
      snackbarMsg =
          "Error submitting answer; check your cookie and internet connection.";
      color = Colors.purple;
    } else {
      snackbarMsg = "Received unknown reponse.";
      color = Colors.purple;
    }
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(snackbarMsg, style: TextStyle(color: Colors.black)),
      backgroundColor: color,
    ));
  }

  void copyCode() {
    debugPrint("copying code");
    Clipboard.setData(ClipboardData(text: codeController.text));
  }

  void saveCode(BuildContext context) {
    debugPrint("saving code:\n${codeController.text}");
    Code code = Code(problem.id, language, codeController.text);
    problemModel.insertOrUpdateCode(code);
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Code saved."),
    ));
  }
}
