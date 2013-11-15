import 'dart:html';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vdrones/vdrones.dart' as vdrones;
import 'package:vdrones/effects.dart';
//import 'package:web_ui/web_ui.dart';
import 'package:vdrones/auth.dart';
import 'package:vdrones/html_tools.dart';
import 'package:vdrones/game_services.dart';

var game = new vdrones.VDrones(document.querySelector('#screenInGame'))
..showScreen = _showScreen
;
var feedbackScreen = null;
var screenAchievements = null;

void main() {
  loadDataSvgs().map((f) => f.catchError((err,st) {
    print(err);
    print(st);
  }));
  // xtag is null until the end of the event loop (known dart web ui issue)
  new Timer(const Duration(), () {
    //_setupLog();
    new vdrones.UiAudioVolume()
    ..element = querySelector("#audioVolume")
    ..audioManager = game.audioManager
    ;
    UiDropdown.bind(document.body);
    var uiSign = new UiSign()..bind();
    var gameservices = makeGameServices(uiSign.auth);

    screenAchievements = new ScreenAchievements(querySelector("#screenAchievements"), gameservices);
    uiSign.onSign.listen((evt) {
      screenAchievements.showPage();
    });
    _setupRoutes();
  });
}

void _setupRoutes() {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    _route(window.location.hash);
  });
  _route(window.location.hash);
}

void _route(String hash) {
  //RegExp exp = new RegExp(r"(\w+)");
  if (hash.startsWith("#/a/")) {
    game.area = hash.substring("#/a/".length);
  } else if (hash.startsWith("#/s/")) {
    game.pause();
    _showScreen(hash.substring("#/s/".length));
  } else {
    window.location.hash = '/a/alpha0';
  }
}

void _showScreen(id){
  if (_currentScreenId == id) return;
  var previousScreenId = _currentScreenId;
  var previousScreenTransition = _findTransition(previousScreenId);
  _currentScreenId = id;
  var currentScreenTransition = _findTransition(_currentScreenId);
  _preShowScreen(id);
  Swapper.swap(document.querySelector('#layers'), document.querySelector('#$id'), effect: currentScreenTransition, duration : 1000, effectTiming: EffectTiming.ease, hideEffect: previousScreenTransition);
}

var _currentScreenId = '';

_findTransition(id) {
  return _transitionsDefault;
}
final _transitionsDefault = new ScaleEffect();
//final _transitionsFromTop = new ScaleEffect();

_preShowScreen(id) {
  if (id == 'screenAchievements') {
    screenAchievements.showPage();
  }
}
void _setupLog() {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((r){
    if (r.level == Level.SEVERE) {
      window.console.error(r);
    } else if (r.level == Level.WARNING) {
      window.console.warn(r);
    } else if (r.level == Level.INFO) {
      window.console.log(r);
    } else {
//      window.console.debug(r);
    }
  });
  var _logger = new Logger("test");
  _logger.info("info");
  _logger.fine("fine");
  _logger.finer("finer");
  _logger.warning("warning");
  _logger.severe("severe");
}


