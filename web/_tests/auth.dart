import 'dart:html';
import 'package:google_plus_v1_api/plus_v1_api_browser.dart' as plusclient;
import '../../lib/cfg.dart' as cfg;
import '../../lib/events.dart';
import 'package:vdrones/auth.dart';
import 'package:vdrones/game_services.dart';

void main() {
  var bus = makeBus();
  var uiSign = new UiSign()
  ..bus = bus
  ..init()
  ;
  var gameservices = makeGameServices(uiSign.auth);

  var screenAchievements = new ScreenAchievements()
  ..el = querySelector("#screenAchievements")
  ..gameservices = gameservices
  ..init()
  ;
  bus.on(eventAuth).listen((evt) {
    if (evt.logged) helloGPlus(evt.auth);
    screenAchievements.update();
  });
  screenAchievements.update();
}

void helloGPlus(auth) {
  var plus = new plusclient.Plus(auth);
  // set the API key
  plus.key = cfg.API_KEY_BROWSER;
  plus.oauth_token = auth.token.data;
  plus.people.get("me").then((person) {
    // log the users full name to the console
    print("Hello ${person.name.givenName} ${person.name.familyName}");
  });
}


//  games.leaderboards.list(maxResults: 5).then((x){
//    //TODO setup the screen to "display mode"
//    print(x.items);
//  }, onError: (e,st){
//    //TODO setup the screen to "error mode"
//    // eg : Failed to load resource: the server responded with a status of 401 (Unauthorized)
//    //   https://www.googleapis.com/games/v1/achievements
//    // APIRequestException: 401 Login Required
//    print(e);
//    print(st);
//  });

