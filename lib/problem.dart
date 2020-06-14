import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const int MAX_TITLE_LENGTH = 150;

@entity
class Problem {
  @primaryKey
  final int id;
  final String title;
  final String content;

  Problem(this.id, this.title, this.content);

  String shortTitle() {
    if (title.length > MAX_TITLE_LENGTH) {
      return title.substring(0, MAX_TITLE_LENGTH);
    } else {
      return title;
    }
  }
}

@dao
abstract class ProblemDao {
  @Query('SELECT * FROM Problem')
  Future<List<Problem>> getAllProblems();

  @Query('SELECT * FROM Problem WHERE id = :id LIMIT 1')
  Future<Problem> getProblem(int id);

  @insert
  Future<void> insertProblem(Problem problem);

  @Query("DELETE FROM Problem")
  Future<void> deleteAllProblems();
}

class ProblemWidget extends StatelessWidget {
  final int id;
  final String title;
  final String content;
  final bool expanded;
  final onTap;
  ProblemWidget(this.id, this.title, this.content, this.expanded, this.onTap);

  @override
  Widget build(BuildContext context) {
    final listTile = ListTile(
      title: Text("$id. $title"),
      onTap: onTap,
      onLongPress: goToDetailPage,
    );

    if (expanded) {
      return Card(
        child: Column(
          children: <Widget>[
            listTile,
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Text(content),
            ),
          ],
        ),
      );
    } else {
      return listTile;
    }
  }

  goToDetailPage() {
    debugPrint("go to detail page for $id");
  }
}
