import 'dart:math';
import 'package:floor/floor.dart';

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

  @Query('SELECT * FROM Problem WHERE id = :id')
  Future<List<Problem>> getProblem(int id);

  @insert
  Future<void> insertProblem(Problem problem);

  @Query("DELETE FROM Problem")
  Future<void> deleteAllProblems();
}

// class ProblemWidget extends
