import 'dart:ffi';

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
  // floor doesn't store bools; just a 0 / 1 int
  int favorited;

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
    return "Problem $id [$favorited] ($shortTitle()).";
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

  @Query("DELETE FROM Problem")
  Future<void> deleteAllProblems();

  @Query("ALTER TABLE Problem ADD COLUMN :name :type DEFAULT :defaultValue")
  Future<void> addColumn(String name, String type, String defaultValue);
}

class ProblemWidget extends StatelessWidget {
  final int id;
  final String title;
  final String content;
  final int favorited;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback toggleFavorited;
  ProblemWidget(
    this.id,
    this.title,
    this.content,
    this.favorited,
    this.expanded,
    this.onTap,
    this.toggleFavorited,
  );

  @override
  Widget build(BuildContext context) {
    void goToDetailPage() {
      debugPrint("go to detail page for $id");
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return ProblemDetailWidget(id, title, content);
          },
        ),
      );
    }

    final listTile = ListTile(
      title: Text("$id. $title"),
      trailing: IconButton(
        icon: Icon(favorited == 1 ? Icons.star : Icons.star_border),
        onPressed: toggleFavorited,
      ),
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
}

class ProblemDetailWidget extends StatelessWidget {
  final int id;
  final String title;
  final String content;
  ProblemDetailWidget(this.id, this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Problem $id")),
      body: Center(
        child: Column(
          children: <Widget>[
            Text(title),
            Text(content),
          ],
        ),
      ),
    );
  }
}