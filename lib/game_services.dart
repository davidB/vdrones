library game_services;

import 'dart:html';
import 'dart:async';
import "package:google_oauth2_client/google_oauth2_browser.dart" as oauth;
import 'package:google_games_v1_api/games_v1_api_browser.dart' as gamesbrowser;
import 'package:google_games_v1_api/games_v1_api_client.dart' as gamesclient;
import 'package:intl/intl.dart';

import 'effects.dart';
import 'html_tools.dart';

makeGameServices(oauth.OAuth2 auth) {
  return new gamesbrowser.Games(auth)
  ..makeAuthRequests = true
  ;
}

class ScreenAchievements {
  final Element el;
  final gamesbrowser.Games gameservice;
  var _state = 0;
  var _defsF;
  var _tmpl = null;
  var playerId = "me"; //gameservice.auth.token.userId

  ScreenAchievements(this.el, this.gameservice) {
    var tmpl = el.querySelector("script.ach");
    if (tmpl == null) {
      print("ERROR: no template define for '.ach'");
      _state = -1;
      return;
    }
    _tmpl = new MicroTemplate(tmpl);
  }

  showPage() {
    var s = ShowHide.getState(el);
    if (s == ShowHideState.HIDING || s == ShowHideState.HIDDEN) return;
    if (gameservice.auth.token == null){
      _showPage("login");
      return;
    }
    if(_state == 0) {
      _load();
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

  void _load() {
    _state = 1;
  //TODO setup the screen to "loading mode"
    if (_defsF == null) {
      _defsF = gameservice.achievementDefinitions.list();
    }
    Future.wait([
      _defsF,
      gameservice.achievements.list(playerId)
    ]).then((l){
      _render(l[0].items, l[1].items);
      _state = 2;
      showPage();
    }, onError: (e,st){
      //TODO setup the screen to "error mode"
      // eg : Failed to load resource: the server responded with a status of 401 (Unauthorized)
      //   https://www.googleapis.com/games/v1/achievements
      // APIRequestException: 401 Login Required
      print("ERROR: $e");
      print("ERROR: $st");
      _state = 3;
      showPage();
    });
  }

  _render(List<gamesclient.AchievementDefinition> defs, List<gamesclient.PlayerAchievement> achs) {
    int pos = 0;
    var pas = defs.map((x) => new _PlayerAchievements()
    ..ad = x
    ..pos0 = --pos
    ).toList(growable: false);
    achs.forEach((x){
      pas.firstWhere((y) => y.ad.id == x.id).pa = x;
    });
    pas.sort((e1,e2) => e2.pos - e1.pos);
    _tmpl.apply(pas.map((x) => x.asMap()));
  }
}


class _PlayerAchievements {
  static final _datetimeFmt = new DateFormat().add_Hm();

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
      "state" : pa.achievementState.toLowerCase(),
      "at" : (pa.lastUpdatedTimestamp == null)  ? "" : _datetimeFmt.format(new DateTime.fromMillisecondsSinceEpoch(pa.lastUpdatedTimestamp))
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