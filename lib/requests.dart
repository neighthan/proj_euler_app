import 'dart:html';

import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:flutter/foundation.dart';


/*
On your computer, open Chrome.
At the top right, click More More and then Settings.
Under 'Privacy and security', click Site settings.
Click Cookies and then See all cookies and site data.
At the top right, search for projecteuler
Click on the row for projecteuler.net
Copy the Content from keep_alive into the app
Delete the keep_alive and PHPSESSID cookies from chrome by clicking the Xs next to them (you'll have to sign in again on the website the next time that you visit it; this ensures you have separate cookies for the app and the browser)

response = session.post(url, cookies=cookies)
# this is updated after... some requests?
cookies["keep_alive"] = session.cookies.get_dict()["keep_alive"]
# wait >= 30 seconds before submitting again
# have a snackbar about this if the user tries to submit too early; tell them how many seconds left
# before they can submit again
response = session.post(url, cookies=cookies, data=data)
cookies["keep_alive"] = session.cookies.get_dict()["keep_alive"]
*/

postSolution(int problemId, String solution) async {
  String keepAlive = "1586532504%231348184%23lV81CbpkdXpXtHzpVlr4SCzJxQ3oAeEU";
  String url = "https://projecteuler.net/problem=$problemId";
  Map<String, String> headers = {"cookie": "keep_alive=$keepAlive"};
  Client client = Client();
  Response response = await client.post(url, headers: headers);
  debugPrint("code: ${response.statusCode.toString()}; reason: ${response.reasonPhrase}");
  debugPrint(response.body);
  debugPrint(response.headers.toString());
  Document html = parse(response.body);
  // submit_token = html.find("input", {"name": "submit_token"})["value"]
  Element sToken = html.querySelector('input[name="submit_token"]');
  debugPrint(sToken.toString());
  // String submit_token = "123";
  // Map<String, String> formResponses = {"guess_$problemId": solution, "submit_token": submit_token};
  // response = await client.post(url, body: formResponses);
  // response.statusCode;
  // html = parse(response.body);
  // html.find("img", {"title": "Correct"})
  // html.find("img", {"title": "Wrong"})
  // html.querySelector("img > ");
  // post(url)
}
