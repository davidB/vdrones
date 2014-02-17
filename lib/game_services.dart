library game_services;

import 'dart:html';
import 'dart:async';
import "package:google_oauth2_client/google_oauth2_browser.dart" as oauth;
import 'package:google_games_v1_api/games_v1_api_browser.dart' as gamesbrowser;
import 'package:google_games_v1_api/games_v1_api_client.dart' as gamesclient;
import 'package:html_toolbox/html_toolbox.dart';
import 'package:intl/intl.dart';

import 'package:html_toolbox/effects.dart';

import 'cfg.dart' as cfg;

makeGameServices(oauth.OAuth2 auth) {
  return new gamesbrowser.Games(auth)
  ..makeAuthRequests = true
  ;
}

class ScreenAchievements {
  Element el;
  gamesbrowser.Games gameservices;
  var _state = 0;
  var _defsF;
  var _tmpl = null;
  var playerId = "me"; //gameservice.auth.token.userId

  init() {
    var tmpl = el.querySelector("script.ach");
    if (tmpl == null) {
      print("ERROR: no template define for '.ach'");
      _state = -1;
      return;
    }
    _tmpl = new MicroTemplate(tmpl);
  }

  reload() {
    _state = 0;
    update();
  }

  update() {
    var s = ShowHide.getState(el);
    //if (s == ShowHideState.HIDING || s == ShowHideState.HIDDEN) return;
    if (gameservices.auth.token == null){
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
      _defsF = gameservices.achievementDefinitions.list();
    }
    Future.wait([
      _defsF,
      gameservices.achievements.list(playerId)
    ]).then((l){
      _render(l[0].items, l[1].items);
      _state = 2;
      update();
    }, onError: (e,st){
      //TODO setup the screen to "error mode"
      // eg : Failed to load resource: the server responded with a status of 401 (Unauthorized)
      //   https://www.googleapis.com/games/v1/achievements
      // APIRequestException: 401 Login Required
      print("ERROR: $e");
      print("ERROR: $st");
      _state = 3;
      update();
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

class ScreenScores {
  Element el;
  gamesbrowser.Games gameservices;
  var _state = 0;
  var _defsF;
  var _tmpl = null;
  var playerId = "me"; //gameservice.auth.token.userId
  static final optParams = {
    "fields" : "items(player,scoreRank,scoreValue),nextPageToken,prevPageToken"
  };
  static final _emptyData = {
    "scoreRank" : "",
    "player.displayName" : "",
    "scoreValue" : ""
  };
  var _nextToken;
  var _prevToken;
  var _collection;
  var _maxResults = 15;

  init(){
    var tmpl = el.querySelector("script.score");
    if (tmpl == null) {
      print("ERROR: no template define for '.score'");
      //_state = -1;
      return;
    }
    _tmpl = new MicroTemplate(tmpl);

    var sel = (el.querySelector("#friends_filter") as CheckboxInputElement);
    _collection = sel.checked ? "SOCIAL" : "PUBLIC";
    sel.onChange.listen((_){
      _collection = sel.checked ? "SOCIAL" : "PUBLIC";
      reload();
    });

  }

  reload() {
    _state = 0;
    update();
  }

  update() {
    var s = ShowHide.getState(el);
    //if (s == ShowHideState.HIDING || s == ShowHideState.HIDDEN) return;
    if (gameservices.auth.token == null){
      _showPage("login");
      return;
    }
    if (_state == 0) {
      _load(null);
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

  void _load(pageToken) {
    _state = 1;
    _setPageToken("next", null);
    _setPageToken("prev", null);
    //gameservice.leaderboards.(maxResults: 15).then((x){
    gameservices.scores.listWindow(cfg.LEAD_CUBES, _collection, "ALL_TIME", maxResults : _maxResults, pageToken : pageToken/*, optParams: optParams*/).then((x){
      _setPageToken("next", x.nextPageToken);
      _setPageToken("prev", x.prevPageToken);
      print("scores : $x");
      _render((x.items == null) ? [] : x.items);
      _state = 2;
      update();
    }, onError: (e,st){
      //TODO setup the screen to "error mode"
      // eg : Failed to load resource: the server responded with a status of 401 (Unauthorized)
      //   https://www.googleapis.com/games/v1/achievements
      // APIRequestException: 401 Login Required
      print("ERROR: $e");
      print("ERROR: $st");
      _state = 3;
      update();
    });
  }

  _render(List<gamesclient.LeaderboardEntry> items) {
    var l = items.map((x) => x.toJson()).toList(growable: true);
    for(var i = l.length; i <_maxResults; i++) {
      l.add(_emptyData);
    }
    _tmpl.apply(l);
  }

  _setPageToken(kind, token) {
    var btn = el.querySelector(".${kind}");
    if (btn != null) {
      btn.disabled = token == null;
      if (token != null) {
        btn.onClick.first.then((_){
          _load(token);
        });
      } else {
        btn.onClick.drain();
      }
    }
  }
}
