// all of these imports are required by the generated code; don't remove them
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
// end definitely required imports
import 'problem.dart';
import 'code.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 2, entities: [Problem, Code])
abstract class AppDatabase extends FloorDatabase {
  ProblemDao get problemDao;
  CodeDao get codeDao;
}
