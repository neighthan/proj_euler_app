import 'dart:ffi';

import 'package:ProjectEuler/main.dart';
import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';

const int MAX_TITLE_LENGTH = 150;

@entity
class Problem {
  @primaryKey
  final int id;
  final String title;
  final String content;
  // floor doesn't store bools; just a 0 / 1 int
  int favorited;
  @ignore
  bool expanded = false;

  Problem(this.id, this.title, this.content, this.favorited);

  String shortTitle() {
    if (title.length > MAX_TITLE_LENGTH) {
      return title.substring(0, MAX_TITLE_LENGTH);
    } else {
      return title;
    }
  }

  @override
  String toString() {
    return "Problem $id [$favorited] (${shortTitle()}).";
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

class ProblemModel extends Model {
  final ProblemDao problemDao;
  bool loading;
  // TODO: maybe make getters with unmodifiable views for these?
  // changes should only happen through ProblemModel so listeners are notified
  List<Problem> allProblems;
  List<Problem> visibleProblems;
  bool onlyFavoritesVisible = false;

  ProblemModel(this.problemDao) {
    loading = true;
    loadProblems();
  }

  // you can await this to make sure the model is done loading
  // this isn't expected to notifyListeners
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
          allProblems.where((problem) => problem.favorited == 1).toList();
    } else {
      visibleProblems = allProblems;
    }
    return visibleProblems;
  }

  toggleFavoriteProblem(Problem problem) {
    problem.favorited = problem.favorited == 1 ? 0 : 1;
    if (onlyFavoritesVisible && problem.favorited == 0) {
      visibleProblems.remove(problem);
    }
    problemDao.updateProblem(problem);
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
      // setState(() {
      //   problem.favorited = problem.favorited == 1 ? 0 : 1;
      // });
    }

    void toggleExpanded() {
      setState(() {
        problem.expanded = !problem.expanded;
      });
    }

    final listTile = ListTile(
      title: Text("${problem.id}. ${problem.shortTitle()}"),
      trailing: IconButton(
        icon: Icon(problem.favorited == 1 ? Icons.star : Icons.star_border),
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
  final Problem problem;
  final ProblemModel problemModel;
  final TextEditingController answerController;
  final TextEditingController codeController;
  _ProblemDetailWidgetState(this.problem, this.problemModel)
      : answerController = TextEditingController(),
        codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    void toggleFavorited() {
      problemModel.toggleFavoriteProblem(problem);
      // setState(() {
      //   problem.favorited = problem.favorited == 1 ? 0 : 1;
      // });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Problem ${problem.id}"),
        actions: <Widget>[
          IconButton(
            onPressed: toggleFavorited,
            icon: Icon(problem.favorited == 1 ? Icons.star : Icons.star_border),
          )
        ],
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Text(problem.title),
            Text(problem.content),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: answerController,
                      decoration: InputDecoration(
                        hintText: "Answer",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: RaisedButton(
                    onPressed: submitAnswer,
                    child: Text("Submit"),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: codeController,
                maxLines: null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: copyCode,
                  child: Text("Copy"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                ),
                RaisedButton(
                  onPressed: saveCode,
                  child: Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void submitAnswer() {
    debugPrint(
        "submitted answer ${answerController.text} for problem ${problem.id}.");
  }

  void copyCode() {
    debugPrint("copying code");
    Clipboard.setData(ClipboardData(text: codeController.text));
  }

  void saveCode() {
    debugPrint("saving code");
  }
}
