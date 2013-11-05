import 'dart:html';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vdrones/vdrones.dart' as vdrones;
import 'package:vdrones/effects.dart';
//import 'package:web_ui/web_ui.dart';

var game = new vdrones.VDrones(document.querySelector('#screenInGame'))
..showScreen = _showScreen
;
var feedbackScreen = null;

void main() {
  // xtag is null until the end of the event loop (known dart web ui issue)
  new Timer(const Duration(), () {
    //_setupLog();
    _setupRoutes();
    new vdrones.UiAudioVolume()
    ..element = querySelector("#audioVolume")
    ..audioManager = game.audioManager
    ;
    vdrones.UiDropdown.bind(document.body);
  });
}

void _setupRoutes() {
  var el = querySelector('#feedback_dialog');
  if (el != null) {
    feedbackScreen = el.xtag;
    feedbackScreen.onToggle.listen((e){
      if (!feedbackScreen.isShown) {
        window.location.hash = '/a/${game.area}';
      }
    });
  }


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
    _showScreen(hash.substring("#/s/".length));
  } else if (hash == "#/comments") {
    feedbackScreen.show();
  } else {
    window.location.hash = '/a/alpha0';
  }
}

var _currentScreenId = '';
void _showScreen(id){
  var previousScreenId = _currentScreenId;
  var previousScreenTransition = _findTransition(previousScreenId);
  _currentScreenId = id;
  var currentScreenTransition = _findTransition(_currentScreenId);
  Swapper.swap(document.querySelector('#layers'), document.querySelector('#$id'), effect: currentScreenTransition, duration : 1000, effectTiming: EffectTiming.ease, hideEffect: previousScreenTransition);
}

final transitionsDefault = new ScaleEffect();
//final transitionsFromTop = new ScaleEffect();
_findTransition(id) {
  return transitionsDefault;
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

