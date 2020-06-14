import 'package:flutter/material.dart';
import 'data_utils.dart';
import 'code.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Center(
        child: ListView(
          children: <Widget>[
            RaisedButton(
              child: Text("Set Cookie"),
              onPressed: updateCookie,
            ),
            RaisedButton(
              child: Text("Update Completed Problems"),
              onPressed: updateCompletedProblems,
            ),
            RaisedButton(
              child: Text("Export Code"),
              onPressed: exportCode,
            ),
          ],
        ),
      ),
    );
  }

  void updateCookie() {
    // have a dialog pop up, user enters cookie and hits Okay (or cancel)
    // if okay, then we update the cookie.
    // show the cookie-setting instructions in this pop-up (cut and paste them from
    // the top of requests.dart)
    debugPrint("Setting cookie");
    // String cookie = "";
    // setCookie(cookie);
  }

  void updateCompletedProblems() {
    debugPrint("Updating completed problems");
  }

  void exportCode() async {
    debugPrint("exporting code");
    // make this page a ScopedModel so we can get codeDao;
    // see how the ProblemWidgets are created in main.dart for an example;
    // just update this in navigateToSettings
    // String code = await exportCodeTable(codeDao);
    // Share.share()
  }
}
