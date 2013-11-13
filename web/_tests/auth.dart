import 'dart:html';
import 'dart:async';
import "package:google_oauth2_client/google_oauth2_browser.dart" as oauth;
import 'package:google_plus_v1_api/plus_v1_api_browser.dart' as plusclient;
import 'package:google_games_v1_api/games_v1_api_browser.dart' as gamesbrowser;
import 'package:google_games_v1_api/games_v1_api_client.dart' as gamesclient;
import 'package:intl/intl.dart';
import '../cfg.dart' as cfg;
import 'package:vdrones/effects.dart';



var signAction = new SignAction()
..autoLogin = false
;
void main() {
  signAction.bind();
  signAction.onSign.listen((evt) {
    if (evt.logged) helloGPlus(evt.auth);
  });

  var gameservice = new gamesbrowser.Games(signAction.auth)
  ..makeAuthRequests = true
  ;

  var screenAchievements = new ScreenAchievements(querySelector("#screenAchievements"), gameservice);
  signAction.onSign.listen((evt) {
    screenAchievements.showPage();
  });
  screenAchievements.showPage();

  //ShowHide.show(querySelector("#achievements"))
}

class SignEvent {
  bool logged = false;
  oauth.OAuth2 auth;
}
class SignAction {
  var selector = ".gplus_signin";
  var autoLogin = false;
  var _im = true;
  var _streamCtrl = new StreamController<SignEvent>.broadcast();

  get onSign => _streamCtrl.stream;

  final auth = new oauth.GoogleOAuth2(
      cfg.OAUTH2_CLIENT_ID,
      cfg.DATA_SCOPES,
      autoLogin: false
  );

  bind() {
    querySelectorAll(selector).forEach((Element e) => e.onClick.listen((_) => toggleSign()));
    if (autoLogin) {
      auth.login(immediate: _im).then((_) => _displayAction());
      _displayWIP();
    }
    _displayAction();
  }

  toggleSign() {
    if (auth.token == null || auth.token.expired) {
      auth.login(immediate: _im).then((_) => _displayAction());
      _displayWIP();
      _im = false;
    } else {
      _im = false;
      auth.logout();
      _displayAction();
    }
  }

  _displayAction() {
    _streamCtrl.add(new SignEvent()
    ..auth = auth
    ..logged = (auth.token != null)
    );
    var txt = (auth.token == null || auth.token.expired) ? "Sign In" : "Sign Out";
    querySelectorAll(selector + " .buttonText").forEach((e) {
      e.text = txt;
      e.parent.disabled = false;
    });
  }

  _displayWIP() {
    querySelectorAll(selector + " .buttonText").forEach((e) {
      e.text = "... working ...";
      e.parent.disabled = true;
    });
  }

  _oauthReady(oauth.Token token){

  }

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

class ScreenAchievements {
  final Element el;
  final gamesbrowser.Games gameservice;
  var _state = 0;
  var defsF;
  var tmplAchievements = null;
  var tmplAchievementsParent = null;
  var uriPolicy = new UriPolicyAll();

  ScreenAchievements(this.el, this.gameservice) {
    var tmpl = el.querySelector(".ach");
    if (tmpl == null) {
      print("no template define for achivement");
      _state = -1;
      return;
    }
    tmplAchievementsParent = tmpl.parent;
    tmplAchievements = tmplAchievementsParent.innerHtml;
    tmplAchievementsParent.setInnerHtml('');
  }

  _showPage(clazz) {
    el.children.forEach((e){
      var cs = e.classes;
      if (cs.contains("subpage")) {
        if (e.classes.contains(clazz)) {
          ShowHide.show(e);
        } else {
          ShowHide.hide(e);
        }
      }
    });
  }

  showPage() {
    print("showPage 00");
    var s = ShowHide.getState(el);
    if (s == ShowHideState.HIDING || s == ShowHideState.HIDDEN) return;
    print("showPage 01");
    if (gameservice.auth.token == null){
      print("showPage 01 - x");
      _showPage("login");
      return;
    }
    print("showPage 01 - ${_state}");
    if(_state == 0) {
      _loadAchievements();
    }
    if (_state == 1) {
      _showPage("loading");
    }
    if (_state == 2) {
      _showPage("ready");
    }
    if (_state == -1) {
      _showPage("bad");
    }
  }

  void _loadAchievements() {
    _state = 1;
  //TODO setup the screen to "loading mode"
    if (defsF == null) {
      defsF = gameservice.achievementDefinitions.list();
    }
    Future.wait([
      defsF,
      gameservice.achievements.list(gameservice.auth.token.userId)
    ]).then((l){
      print("data received");
      _renderAchievements(l[0].items, l[1].items);
      _state = 2;
      print("showPage zz - ${_state}");
      showPage();
    }, onError: (e,st){
      _state = 3;
      showPage();
      //TODO setup the screen to "error mode"
      // eg : Failed to load resource: the server responded with a status of 401 (Unauthorized)
      //   https://www.googleapis.com/games/v1/achievements
      // APIRequestException: 401 Login Required
      print(e);
      print(st);
    });

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
  }

  _renderAchievements(List<gamesclient.AchievementDefinition> defs, List<gamesclient.PlayerAchievement> achs) {
    int pos = 0;
    var pas = defs.map((x) => new PlayerAchievements()
    ..ad = x
    ..pos0 = --pos
    ).toList(growable: false);
    achs.forEach((x){
      pas.firstWhere((y) => y.ad.id == x.id).pa = x;
    });
    pas.sort((e1,e2) => e2.pos - e1.pos);
    tmplAchievementsParent.setInnerHtml(
      pas.fold("", (acc, item) => acc + (interpolate(tmplAchievements, item.asMap()))),
      validator: new NodeValidator(uriPolicy: uriPolicy)
    );
  }
}
var datetimeFmt = new DateFormat().add_Hm();

class PlayerAchievements {
  gamesclient.AchievementDefinition ad;
  gamesclient.PlayerAchievement pa;
  int pos0 = 0;

  get pos =>  (pa == null || pa.lastUpdatedTimestamp == null)  ? pos0 : pa.lastUpdatedTimestamp;

  asMap() {
    if (ad == null || pa == null) return {};
    return {
      "id" : ad.id,
      "iconUrl" : _iconUrl(),
      "name" : ad.name,
      "description" : ad.description,
      "state" : pa.achievementState,
      "at" : (pa.lastUpdatedTimestamp == null)  ? "" : datetimeFmt.format(new DateTime.fromMillisecondsSinceEpoch(pa.lastUpdatedTimestamp))
    };
  }

  //TODO provide a default (HIDDEN url)
  _iconUrl() {
    switch(pa.achievementState) {
      case "UNLOCKED": return ad.unlockedIconUrl;
      case "REVEALED": return ad.revealedIconUrl;
      case "HIDDEN" : return "";
    }
  }

}

interpolate(String tmpl, Map kv) {
  var from = new RegExp(r'\$\{([^}]*)\}');
  return tmpl.replaceAllMapped(from, (x) => kv[x.group(1)]);
}

class UriPolicyAll implements UriPolicy{
  bool allowsUri(String uri) => true;
}
