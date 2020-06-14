import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:flutter/foundation.dart';
import 'data_utils.dart';

/*
There's likely an easier way to do this, but this seems to work.

1. Go to PE site -> Account, select all Active Logins and click "Remove Selected".
2. Refresh the page; you'll have to sign in again (make sure Remember Me is checked)
3. Close the PE tab
4. Click the triple dots in the top-right corner then Settings
5. Under 'Privacy and security', click Site settings.
6. Click Cookies and site date and then "See all cookies and site data".
7. At the top right, search for euler
8. Click on the row for projecteuler.net
9. Copy the Content from keep_alive into the app
10. Delete the keep_alive and PHPSESSID cookies from chrome by clicking Remove All
  (you'll have to sign in again on the website the next time that you visit it; this is to ensure
  you have separate cookies for the app and the browser)
*/

final RegExp KEEP_ALIVE = RegExp(r"keep_alive=([\w%]+)");
final RegExp PHP_SESS_ID = RegExp(r"PHPSESSID=([\w%]+)");
const int CORRECT = 0;
const int INCORRECT = 1;
const int ERROR = 2;

Future<int> postSolution(int problemId, String solution) async {
  // String keepAlive = "1587099225%231348184%23BW2e9Rq0Qm65EddyppMKZl1ZHmQNYTgx";
  // setCookie(keepAlive);
  String keepAlive = await getCookie();
  final String url = "https://projecteuler.net/problem=$problemId";
  final Client client = Client();
  Response response =
      await client.post(url, headers: {"cookie": "keep_alive=$keepAlive"});
  if (response.statusCode != 200) {
    if (response.statusCode == 302) {
      // show a snackbar about the cookie; otherwise, show a snackbar with the reason code and phrase
    }
    debugPrint(
        "Invalid initial response (code ${response.statusCode} '${response.reasonPhrase}')");
    return ERROR;
  }

  bool cookieError = false;
  String phpSessId;
  if (response.headers.containsKey("set-cookie")) {
    final String newCookies = response.headers["set-cookie"];
    final RegExpMatch match = KEEP_ALIVE.firstMatch(newCookies);
    if (match != null) {
      final String newKeepAlive = match.group(1);
      if (newKeepAlive != null) {
        keepAlive = newKeepAlive;
        setCookie(keepAlive);
        phpSessId = PHP_SESS_ID.firstMatch(newCookies).group(1);
      } else {
        cookieError = true;
      }
    } else {
      cookieError = true;
    }
  } else {
    cookieError = true;
  }

  if (phpSessId == null) {
    debugPrint("No PHPSESSID found!");
  }

  if (cookieError) {
    debugPrint("No new keep_alive cookie found!");
    debugPrint("headers = " + response.headers.toString());
  }

  Document html = parse(response.body);
  final Element submitTokenElement =
      html.querySelector('input[name="submit_token"]');
  if (submitTokenElement == null) {
    debugPrint("No submit_token found");
    return ERROR;
  }
  final String submitToken = submitTokenElement.attributes["value"];
  final Map<String, String> formResponses = {
    "guess_$problemId": solution,
    "submit_token": submitToken
  };
  response = await client.post(url,
      body: formResponses, headers: {"cookie": "keep_alive=$keepAlive; PHPSESSID=$phpSessId"});
  if (response.statusCode != 200) {
    debugPrint(
        "Invalid secondary response (code ${response.statusCode} '${response.reasonPhrase}')");
    return ERROR;
  }
  html = parse(response.body);
  final bool correct = html.querySelector('img[title="Correct"]') != null;
  final bool incorrect = html.querySelector('img[title="Wrong"]') != null;
  if (!correct && !incorrect) {
    return ERROR;
  }
  return correct ? CORRECT : INCORRECT;
}
