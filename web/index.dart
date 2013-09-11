import 'dart:html';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vdrones/vdrones.dart' as vdrones;
//import 'package:web_ui/web_ui.dart';

var game = new vdrones.VDrones();
var feedbackScreen = null;

void main() {
  // xtag is null until the end of the event loop (known dart web ui issue)
  new Timer(const Duration(), () {
    //_setupLog();
    _setupRoutes();
  });
}

void _setupRoutes() {
  var el = query('#feedback_dialog');
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
  switch(hash) {
    case '#/a/alpha0' :
      game.area = 'alpha0';
      break;
    case '#/a/beta0' :
      game.area = 'beta0';
      break;
    case '#/a/beta1' :
      game.area = 'beta1';
      break;
    case '#/a/gamma0' :
      game.area = 'gamma0';
      break;
    case '#/a/pacman0' :
      game.area = 'pacman0';
      break;
    case '#/comments':
      feedbackScreen.show();
      break;
    default:
      window.location.hash = '/a/alpha0';
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

