import 'dart:math';
import 'package:ProjectEuler/problem.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:shared_preferences/shared_preferences.dart';

const String MAX_PROBLEM_ID_KEY = "maxProblemId";
const String PROBLEM_TABLE_VERSION_KEY = "problemTableVersion";

Future getProblem(int id) async {
  Client client = Client();
  Response response = await client.get('https://projecteuler.net/problem=$id');
  dom.Document document = parse(response.body);
  String title = document.querySelector("#content > h2").text;
  if (title == "Problems Archive") {
    return null;
  }
  String content = document.querySelector("#content > .problem_content").text;
  return {"id": id, "title": title, "content": content};
}

Future<int> getFromSharedPrefs(String key, {int defaultValue=0}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt(key) ?? defaultValue;
}

Future<void> setInSharedPrefs(String key, int value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(key, value);
}

Future<int> getMaxProblemId() async {
  Client client = Client();
  Response response = await client.get('https://projecteuler.net/recent');
  dom.Document document = parse(response.body);
  // first ID column is header row, second is most recent problem
  return int.parse(document.querySelectorAll(".id_column")[1].text);
}

Future<int> getMaxProblemStoredId() async {
  // the max problem id of problems stored in the database
  return getFromSharedPrefs(MAX_PROBLEM_ID_KEY);
}

Future<void> updateMaxProbleStoredId(int maybeMaxId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int oldMaxId = prefs.getInt(MAX_PROBLEM_ID_KEY) ?? 0;
  await prefs.setInt(MAX_PROBLEM_ID_KEY, max(oldMaxId, maybeMaxId));
}

Future<void> resetMaxProblemStoredId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt(MAX_PROBLEM_ID_KEY, 0);
}
