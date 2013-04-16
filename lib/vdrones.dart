library vdrones;


import 'package:logging/logging.dart';
import 'package:box2d/box2d_browser.dart' as b2;
import 'dart:async';
import 'dart:math' as math;
import 'dart:json' as JSON;
import 'dart:html';
import 'dart:svg' as svg;
import 'package:js/js.dart' as js;
import 'package:lawndart/lawndart.dart';
import 'package:web_ui/watcher.dart' as watchers;
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';

import 'utils.dart';

part 'src/components.dart';
//part 'src/animations.dart';
//part 'src/controls.dart';
part 'src/entities.dart';
part 'src/system_physics.dart';
part 'src/system_renderer.dart';
part 'src/system_controller.dart';
part 'src/system_animator.dart';
//part 'src/events.dart';
//part 'src/gameplay.dart';
//part 'src/layer2d.dart';
//part 'src/periodic.dart';
//part 'src/physics.dart';
//part 'src/renderer.dart';
//part 'src/zone_cubes.dart';
//part 'src/zone_gate_out.dart';
//part 'src/stats.dart';

class Status {
  static const NONE = 0;
  static const INITIALIZING = 1;
  static const INITIALIZED = 2;
  static const RUNNING = 3;
  //static const STOPPING = 4;
  static const STOPPED = 5;
}

class TimeInfo {
  double _time;
  double _previousTime;
  double _delta;

  TimeInfo(){ reset(); }

  get delta => _delta;
  get time => _time;
  set time(double v) {
    _previousTime = (_previousTime < 0.0) ? v : _time;
    _time = v;
    _delta = _time - _previousTime;
  }

  void reset() {
    _previousTime = -1.0;
    _delta = 0.0;
  }
}
class VDrones {
  //var _evt = new Evt();
  var _devMode = true; //document.location.href.indexOf('dev=true') > -1;
  var _status = Status.NONE;
  World _world = null;
  var timeInfo = new TimeInfo();
  _EntitiesFactory _entitiesFactory;
  var _player = "u0";

  //var _worldRenderSystem;
  //var _hudRenderSystem;

  get status => _status;

  void gotoArea(String areaId) {
    if (_status == Status.RUNNING) {
      //_evt.GameStop.dispatch([false]);
    }
    //_evt.GameInit.dispatch([areaId]);
    //TODO remove every entities from _world
    newWorld();
    _entitiesFactory.newFullArea(areaId)
      .then((es){
        es.forEach((e){
          e.addToWorld();
          print("add to world : ${e}");
        });
        _status = Status.RUNNING;
      })
      .catchError((error) => handleError(error))
      ;
  }

  void handleError(error) {
    print("ERROR !! ${error}");
  }

  void play() {
    if (_status == Status.INITIALIZED || _status == Status.STOPPED) {
      //HACK screen should be converted into WebComponent
      //showScreen('none');
      //_evt.GameStart.dispatch(null);
    }
  }

  void setup() {
    window.animationFrame.then(_loop);
  }

  void newWorld() {
    _world = new World();
    var container = document.query('#layers');
    if (container == null) throw new StateError("#layers not found");

    _entitiesFactory = new _EntitiesFactory(_world);
    _world.addManager(new PlayerManager());
    _world.addManager(new GroupManager());
    _world.addSystem(new System_Physics(false), passive : false);
    _world.addSystem(
      new System_PlayerFollower()
        ..playerToFollow = _player
      , passive : false
    );
    _world.addSystem(new System_DroneGenerator(_entitiesFactory, _player));
    _world.addSystem(new System_DroneController());
    _world.addSystem(new System_DroneHandler());
    _world.addSystem(new System_Animator(timeInfo));
    // Dart is single Threaded, and System doesn't run in // => component aren't
    // modified concurrently => Render3D.process like other System
    _world.addSystem(new System_Render3D(container), passive : false);
    _world.initialize();

/*
    _world.addSystem(new AreaLoader());

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
       {watchers.dispatch();
      print("status : ${_status}");
      var tickArgs = [0, 0];
      var lastDelta500 = -1;
      window.animationFrame.then(loop);
    });
*/
  }

  void _loop(num highResTime) {
    try {
    if (_world != null) {
      timeInfo.time = highResTime;
      var world = _world;
      world.delta = timeInfo.delta;
      world.process();
      //_worldRenderSystem.process();
    //if (_status == Status.RUNNING) {
      window.animationFrame.then(_loop);
    //}
    } else {
      timeInfo.reset();
    }
    } catch(error) {
      print(error);
    }
  }

}
