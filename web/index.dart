import 'dart:html';
import 'package:logging/logging.dart';
import 'package:vdrones/vdrones.dart' as vdrones;
import 'package:web_ui/web_ui.dart';

var game = new vdrones.VDrones();

void main() {
  _setupLog();
  game.setup();
  _setupRoutes();
  //game.gotoArea("alpha0");
}

void _setupRoutes() {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    String path = window.location.hash.substring(2);
    game.gotoArea(path);
  });
  if (window.location.hash.isEmpty) {
    window.location.hash = "/alpha0";
  } else {
    String path = window.location.hash.substring(2);
    game.gotoArea(path);
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
      window.console.debug(r);
    }
  });
  var _logger = new Logger("test");
  _logger.info("info");
  _logger.fine("fine");
  _logger.finer("finer");
  _logger.warning("warning");
  _logger.severe("severe");
}

