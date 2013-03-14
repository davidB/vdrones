import 'dart:html';
import 'package:logging/logging.dart';
import '_lib/vdrones.dart' as vdrones;


void main() {
  _setupLog();
  var evt = vdrones.setup();
//  _setupRoutes();
  gotoArea(evt, "grab0");
}

void gotoArea(vdrones.Evt evt, String name) {
  evt.GameInit.dispatch([name]);
  print('catch-all handler xx : ${name}');
}

void _setupRoutes(vdrones.Evt evt) {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    String path = window.location.hash.substring(2);
    gotoArea(evt, path);
  });
  if (window.location.hash.isEmpty) {
    window.location.hash = "/grab0";
  } else {
    String path = window.location.hash.substring(2);
    gotoArea(evt, path);
  }
}


void _setupLog() {
  Logger.root.level = Level.FINE;
  Logger.root.on.record.add((r){
    print(r);
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

