library vdrones;


import 'package:logging/logging.dart';
import 'package:box2d/box2d_browser.dart' hide Position;
import 'dart:async';
import 'dart:math' as math;
import 'dart:json' as JSON;
import 'dart:html';
import 'dart:svg' as svg;
import 'package:js/js.dart' as js;
import 'package:lawndart/lawndart.dart';
import 'package:web_ui/watcher.dart' as watchers;

import 'utils.dart';

part 'src/animations.dart';
part 'src/controls.dart';
part 'src/entities.dart';
part 'src/events.dart';
part 'src/gameplay.dart';
part 'src/layer2d.dart';
part 'src/periodic.dart';
part 'src/physics.dart';
part 'src/renderer.dart';
part 'src/zone_cubes.dart';
part 'src/zone_gate_out.dart';
part 'src/stats.dart';

class Status {
  static const NONE = 0;
  static const INITIALIZING = 1;
  static const INITIALIZED = 2;  
  static const RUNNING = 3;
  //static const STOPPING = 4;
  static const STOPPED = 5;
}

class VDrones {
  var _evt = new Evt();
  var _devMode = true; //document.location.href.indexOf('dev=true') > -1;
  var _status = Status.NONE;

  get status => _status;

  void gotoArea(String areaId) {
    if (_status == Status.RUNNING) {
      _evt.GameStop.dispatch([false]);
    }
    _evt.GameInit.dispatch([areaId]);
  }

  void play() {
    if (_status == Status.INITIALIZED || _status == Status.STOPPED) {
      //HACK screen should be converted into WebComponent
      showScreen('none');
      _evt.GameStart.dispatch(null);
    }
  }

  void setup() {
    var container = document.query('#layers');
    if (container == null) throw new StateError("#layers not found");

  //  Stage4Periodic(evt)
  //  Rules4Countdown(evt)
  //  Rules4TargetG1(evt)
  //  Stage4GameRules(evt)
  //  Stage4Physics(evt)
  //  Stage4UserInput(evt)
  //  Stage4Animation(evt)
    var stats = new Stats(_evt, "vdrones");
    setupPeriodic(_evt);
    setupPhysics(_evt);
    var animator  = setupAnimations(_evt);
    setupRenderer(_evt, container, animator);
    setupLayer2D(_evt, document.query('#game_area'), stats);
    setupControls(_evt);
    setupGameplay(_evt);
    //  if (devMode) {
  //    Stage4DevMode(evt);
  //    Stage4LogEvent(evt, ['Init', 'SpawnObj', 'DespawnObj', 'BeginContact', 'Start', 'Stop', 'Initialized']);
  //    Stage4DatGui(evt);
  //  }

    //ring.push(evt.Start); //TODO push Start when ready and user hit star button
    _evt.GameStop.add((_){
      _status = Status.STOPPED;
      watchers.dispatch();
      print("status : ${_status}");
    });
    _evt.GameInit.add((_){
      _status = Status.INITIALIZING;
      watchers.dispatch();
      print("status : ${_status}");
    });
    _evt.GameInitialized.add((){
      _status = Status.INITIALIZED;
      watchers.dispatch();
      print("status : ${_status}");
    });
    _evt.GameStart.add(() {
      _status = Status.RUNNING;
      watchers.dispatch();
      print("status : ${_status}");
      var tickArgs = [0, 0];
      var lastDelta500 = -1;
      void loop(num highResTime) {
        // loop on request animation loop
        // - it has to be at the beginning of the function
        // - @see http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
        //RequestAnimationFrame.request(loop);
        // note: three.js includes requestAnimationFrame shim
        //setTimeout(function() { requestAnimationFrame(loop); }, 1000/30);
        if (_status == Status.RUNNING) {
          window.requestAnimationFrame(loop);
        }
        var t = highResTime; //new Date().getTime();
        var delta500 = 0;
        if (lastDelta500 == -1) {
          lastDelta500 = t;
          delta500 = 0;
        }
        var d = (t - lastDelta500) / 500;
        if (d >=  1) {
          lastDelta500 = t;
          delta500 = d;
        }
        tickArgs[0] = t;
        tickArgs[1] = delta500;
        _evt.Tick.dispatch(tickArgs);
        _evt.Render.dispatch(null);
      };
      window.requestAnimationFrame(loop);
    });
  }
}
