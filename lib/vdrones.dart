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
import 'package:dartemis_addons/entity_state.dart';
import 'package:dartemis_addons/animator.dart';
import 'package:dartemis_addons/utils.dart';
import 'package:vector_math/vector_math.dart';
//import 'utils.dart';

part 'src/components.dart';
part 'src/system_physics.dart';
part 'src/system_renderer.dart';
part 'src/system_controller.dart';
part 'src/system_hud.dart';
part 'src/factory_physics.dart';
part 'src/factory_entities.dart';
part 'src/factory_animations.dart';
part 'src/factory_renderables.dart';
part 'src/stats.dart';

class Status {
  static const NONE = 0;
  static const INITIALIZING = 1;
  static const INITIALIZED = 2;
  static const RUNNING = 3;
  static const STOPPING = 4;
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

void showScreen(id){
  document.queryAll('.screen_info').forEach((screen) {
    //screen.style.opacity = (screen.id === id)?1 : 0;
    if (screen.id == id) {
      screen.classes.remove('hidden');
      screen.classes.add('show');
    } else {
      screen.classes.remove('show');
      screen.classes.add('hidden');
    }
  });
}

class VDrones {
  //var _evt = new Evt();
  var _devMode = true; //document.location.href.indexOf('dev=true') > -1;
  var _status = Status.NONE;
  World _world = null;
  var timeInfo = new TimeInfo();
  Factory_Entities _entitiesFactory;
  var _player = "u0";
  var _areaId = null;
  var _stats = new Stats("u0", clean : false);

  //var _worldRenderSystem;
  //var _hudRenderSystem;

  get status => _status;
  void _updateStatus(int v) {
    _status = v;
    watchers.dispatch();
  }

  void setup() {
    //NOTHING
  }
  void gotoArea(String areaId) {
    _initialize(areaId);
  }

  void handleError(error) {
    print("ERROR !! ${error}");
  }


  bool playable () => (_status == Status.INITIALIZED || _status == Status.STOPPING);

  bool play() {
    print("call play : ${_status}");
    if  (!playable()){
      print("NOT playable : ${_status}");
      return false;
    }
    if (_status != Status.INITIALIZED) {
      print("initialize : ${_status}");
      _initialize(_areaId).then((_) => _start());
      return true;
    } else {
      _start();
      return true;
    }
  }

  void _start() {
    //TODO spawn drone
    //TODO start area (=> start chronometer)
    _updateStatus(Status.RUNNING);
    //HACK screen should be converted into WebComponent
    showScreen('none');
    window.animationFrame.then(_loop);
  }

  bool _stop(bool viaExit, int cubesGrabbed) {
    if (_status == Status.RUNNING) {
      _updateStatus(Status.STOPPING);
    }
    _stats
      .updateCubesLast(_areaId, (viaExit)? cubesGrabbed : 0)
      .then((stats){
        var runresult = query('#runresult').xtag;
        runresult.areaId = _areaId;
        runresult.cubesLast = stats[_areaId + Stats.AREA_CUBES_LAST_V];
        runresult.cubesMax = stats[_areaId + Stats.AREA_CUBES_MAX_V];
        runresult.cubesTotal = stats[_areaId + Stats.AREA_CUBES_TOTAL_V];
        query('#runresult_dialog').xtag.show();
      });
  }

  Future _initialize(String areaId) {
    print("Request init");
    if (_status == Status.INITIALIZING) {
      return new Future.error("already initializing an area : ${_areaId}");
    }
    _updateStatus(Status.INITIALIZING);
    showScreen('screenInit');
    if (_world == null) _newWorld();
    _world.deleteAllEntities();
    //_newWorld();
    return _loadArea(areaId).then((a){
      _areaId = a;
      _updateStatus(Status.INITIALIZED);
      return _areaId;
    });
  }

  Future _loadArea(String areaId) {
    return _entitiesFactory.newFullArea(areaId, (e,t,t0){ _stop(false, 0); }).then((es){
      es.forEach((e){
        e.addToWorld();
        print("add to world : ${e}");
      });
      return areaId;
    });
  }

  void _newWorld() {
    _world = new World();
    var container = document.query('#layers');
    if (container == null) throw new StateError("#layers not found");

    _entitiesFactory = new Factory_Entities(_world);
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
    _world.addSystem(new System_DroneHandler(_entitiesFactory, this));
    _world.addSystem(new System_CubeGenerator(_entitiesFactory));
    _world.addSystem(new System_Animator());
    // Dart is single Threaded, and System doesn't run in // => component aren't
    // modified concurrently => Render3D.process like other System
    _world.addSystem(new System_Render3D(container), passive : false);
    _world.addSystem(new System_Hud(container, _player));
    _world.addSystem(new System_EntityState());
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
//    try {
    if ((_world != null) && (_status == Status.RUNNING)) {
      timeInfo.time = highResTime;
      var world = _world;
      world.delta = timeInfo.delta;
      world.process();
      //_worldRenderSystem.process();
      window.animationFrame.then(_loop);
    } else {
      timeInfo.reset();
    }
//    } catch(error) {
//      error);
//    }
  }

}
