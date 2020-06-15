import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'data_utils.dart';
import 'code.dart';
import 'problem.dart';

const String COOKIE_INSTRUCTIONS = """
The "cookie" is used to log in to the Project Euler website with your account. This lets the app submit answers on your behalf. If you don't want to provide the cookie, all functionality except for answer submissions will still work.

WARNING - giving this cookie to somebody allows them to do anything that you could do with your Project Euler account until the cookie is revoked (which you can do from the Account page). This app only uses the cookie to submit answers for you and query information like which problems you've completed, but verifying that is difficult, so procede only if you're willing to accept the risks of sharing access to your account.

These instructions assume you're using Chrome; if you use another browser, you'll need to find out how to get cookies from it.

(There's likely an easier way to get a cookie for the app, but this seems to work.)

1. Go to projecteuler.net -> Account, select all Active Logins and click "Remove Selected".
2. Sign out then sign in again (make sure Remember Me is checked).
3. Close the PE tab.
4. Click the triple dots in the top-right corner then Settings.
5. Under "Privacy and security", click "Site settings".
6. Click "Cookies and site date" and then "See all cookies and site data".
7. At the top right, search for "euler".
8. Click on the row for projecteuler.net.
9. Copy the Content from the keep_alive cookie into the app.
10. Delete the keep_alive and PHPSESSID cookies from Chrome by clicking "Remove All" (you'll have to sign in again on the website the next time that you visit it; this is to ensure you have separate cookies for the app and the browser).""";

class Settings extends StatelessWidget {
  final ProblemModel model;
  Settings(this.model);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Center(
        child: ListView(
          children: <Widget>[
            RaisedButton(
              child: Text("Set Cookie"),
              onPressed: () => updateCookie(context),
            ),
            RaisedButton(
              child: Text("Update Completed Problems"),
              onPressed: updateCompletedProblems,
            ),
            RaisedButton(
              child: Text("Export Code"),
              onPressed: exportCode,
            ),
            RaisedButton(
              child: Text("Check for New Problems"),
              onPressed: checkForNewProblems,
            ),
          ],
        ),
      ),
    );
  }

  void updateCookie(BuildContext context) {
    debugPrint("Setting cookie");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController cookieController = TextEditingController();

        return AlertDialog(
          title: Text("Set Cookie"),
          // might need SingleChildScrollView wrapping the content
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text(
                  COOKIE_INSTRUCTIONS,
                  style: TextStyle(fontSize: 12),
                ),
                TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: cookieController,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop()),
            FlatButton(
              child: Text("Save"),
              onPressed: () {
                final String cookie = cookieController.text;
                debugPrint("setting cookie to $cookie");
                setCookie(cookie);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updateCompletedProblems() {
    debugPrint("Updating completed problems");
  }

  void exportCode() async {
    debugPrint("exporting code");
    final String code = await exportCodeTable(model.codeDao);
    Share.share(code);
  }

  void checkForNewProblems() async {
    debugPrint("checking for new problems");
    int maxProblemId = await getMaxProblemId();
    // int currentMaxId = await getMaxProblemStoredId();
    int currentMaxId = 0;
    if (maxProblemId > currentMaxId) {
      for (int problemId = currentMaxId + 1; problemId <= maxProblemId; problemId++) {
        Problem problem = await getProblemFromWebsite(problemId);
        model.insertOrUpdateProblem(problem);
        debugPrint("Added $problemId");
      }
      model.notifyProblemsUpdated();
      updateMaxProbleStoredId(maxProblemId);
    }
  }
}
