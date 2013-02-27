import 'dart:html';
import 'package:logging/logging.dart';
import '_lib/vdrones.dart';


var evt = new Evt();

void main() {
  _setupLog();
  _setup();
//  _setupRoutes();
  gotoArea("grab0");
}

void _setupRoutes() {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    String path = window.location.hash.substring(2);
    gotoArea(path);
  });
  if (window.location.hash.isEmpty) {
    window.location.hash = "/grab0";
  } else {
    String path = window.location.hash.substring(2);
    gotoArea(path);
  }
}

void gotoArea(String name) {
  evt.GameInit.dispatch([name]);
  print('catch-all handler xx : ${name}');
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


void _setup() {


  var devMode = true; //document.location.href.indexOf('dev=true') > -1;

  var container = document.query('#layers');
  if (container == null) throw new StateError("#layers not found");

//  Stage4Periodic(evt)
//  Rules4Countdown(evt)
//  Rules4TargetG1(evt)
//  Stage4GameRules(evt)
//  Stage4Physics(evt)
//  Stage4UserInput(evt)
//  Stage4Animation(evt)
  setupPeriodic(evt);
  setupGameplay(evt);
  setupPhysics(evt);
  var animator  = setupAnimations(evt);
  setupRenderer(evt, container, animator);
  setupLayer2D(evt, document.query('#game_area'));
  setupKeyboard(evt);
  //  if (devMode) {
//    Stage4DevMode(evt);
//    Stage4LogEvent(evt, ['Init', 'SpawnObj', 'DespawnObj', 'BeginContact', 'Start', 'Stop', 'Initialized']);
//    Stage4DatGui(evt);
//  }

  //ring.push(evt.Start); //TODO push Start when ready and user hit star button
  var _running = false;
  evt.GameStop.add((){
    _running = false;
  });
  evt.GameStart.add(() {
    _running = true;
    var tickArgs = [0, 0];
    var lastDelta500 = -1;
    void loop(num highResTime) {
      // loop on request animation loop
      // - it has to be at the beginning of the function
      // - @see http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
      //RequestAnimationFrame.request(loop);
      // note: three.js includes requestAnimationFrame shim
      //setTimeout(function() { requestAnimationFrame(loop); }, 1000/30);

      var t = highResTime; //new Date().getTime();
      var delta500 = 0;
      if (lastDelta500 == -1) {
        lastDelta500 = t;
        delta500 = 0;
        print("init ${t}");
      }
      var d = (t - lastDelta500) / 500;
      if (d >=  1) {
        lastDelta500 = t;
        delta500 = d;
      }
      tickArgs[0] = t;
      tickArgs[1] = delta500;
      evt.Tick.dispatch(tickArgs);
      evt.Render.dispatch(null);
      if (_running) {
        window.requestAnimationFrame(loop);
      }
    };
    window.requestAnimationFrame(loop);
  });
}
