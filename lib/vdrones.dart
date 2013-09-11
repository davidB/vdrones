library vdrones;

import 'dart:async';
import 'dart:math' as math;
import 'dart:json' as JSON;
import 'dart:html';
import 'dart:svg' as svg;
import 'dart:collection';
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';
import 'package:lawndart/lawndart.dart';
import 'package:web_ui/watcher.dart' as watchers;
import 'package:dartemis/dartemis.dart';
import 'package:dartemis_toolbox/system_entity_state.dart';
import 'package:dartemis_toolbox/system_animator.dart';
import 'package:dartemis_toolbox/system_simple_audio.dart';
import 'package:dartemis_toolbox/system_transform.dart';
import 'package:dartemis_toolbox/system_verlet.dart';
import 'package:dartemis_toolbox/system_particles.dart';
import 'package:dartemis_toolbox/utils.dart';
import 'package:dartemis_toolbox/ease.dart' as ease;
import 'package:dartemis_toolbox/collisions.dart' as collisions;
import 'package:dartemis_toolbox/system_proto2d.dart' as proto;
import 'package:dartemis_toolbox/colors.dart';
import 'package:vector_math/vector_math.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:simple_audio/simple_audio.dart';
import 'package:simple_audio/simple_audio_asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_asset_pack.dart';
import 'package:glf/glf_renderera.dart';

//import 'package:box2d/box2d_browser.dart' as b2;

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
  double deltaMax = 1000.0 / 30;

  TimeInfo(){ reset(); }

  get delta => _delta;
  get time => _time;
  set time(double v) {
    _previousTime = (_previousTime < 0.0) ? v : _time;
    _time = v;
    _delta = math.min(deltaMax, _time - _previousTime);
  }

  void reset() {
    _previousTime = -1.0;
    _delta = 0.0;
  }
}

String findBaseUrl() {
  String location = window.location.pathname;
  int slashIndex = location.lastIndexOf('/');
  if (slashIndex < 0) {
    return '/';
  } else {
    return location.substring(0, slashIndex);
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
  var _world = new World();
  var timeInfo = new TimeInfo();
  Factory_Entities _entitiesFactory;
  System_Hud _hud;
  var _player = "u0";
  var _areaPack = null;
  var _stats = new Stats("u0", clean : false);
  AssetManager _assetManager = null;
  AudioManager _audioManager = null;
  WebGL.RenderingContext _gl = null;
  //var _worldRenderSystem;
  //var _hudRenderSystem;

  get masterMute => (_audioManager == null)? true : _audioManager.mute;
  set masterMute(v) { if(_audioManager == null) return; _audioManager.mute = v; }
  get masterVolume => (_audioManager == null)? "0" : _audioManager.masterVolume.toString();
  set masterVolume(v) { if(_audioManager == null) return; _audioManager.masterVolume = double.parse(v) ; }
  get musicVolume => (_audioManager == null)? "0" : _audioManager.musicVolume.toString();
  set musicVolume(v) { if(_audioManager == null) return; _audioManager.musicVolume = double.parse(v) ; }
  get sourceVolume => (_audioManager == null)? "0" : _audioManager.sourceVolume.toString();
  set sourceVolume(v) { if(_audioManager == null) return; _audioManager.sourceVolume = double.parse(v) ; }

  VDrones() {
    var bar = document.query('#gameload');
    var container = document.query('#layers');

    _assetManager = _newAssetManager(bar);
    _audioManager = _newAudioManager(findBaseUrl(), _assetManager);
    _gl = _newRenderingContext(container.queryAll("canvas")[0], _assetManager);
    _preloadAssets();

    if (container == null) throw new StateError("#layers not found");
    _entitiesFactory = new Factory_Entities(_world, _assetManager);
    _hud = new System_Hud(container, _player);
    _setupWorld(container);

    container.tabIndex = -1;
  }

  get status => _status;
  void _updateStatus(int v) {
    _status = v;
    watchers.dispatch();
  }

  get area => (_areaPack == null) ? null : _areaPack.name;
  set area(String v) {
    if (v == area) return;
    _initialize(v);
  }

  void handleError(error,[s]) {
    print("ERROR !! ${error}");
    if (s != null) print(s); //.fullStackTrace); // This should print the full stack trace)
  }


  bool playable () => (_status == Status.INITIALIZED || _status == Status.STOPPING);

  bool play() {
    print("call play : ${_status}");
    try {
    if  (!playable()){
      print("NOT playable : ${_status}");
      return false;
    }
    if (_status != Status.INITIALIZED) {
      print("initialize : ${_status}");
      _initialize(area).then((_) => _start());
      return true;
    } else {
      _start();
      return true;
    }
    } on Object catch(e, s) {
      handleError(e, s);
    }
  }

  void _start() {
    _updateStatus(Status.RUNNING);
    //TODO spawn drone
    //TODO start area (=> start chronometer)
    var es = _entitiesFactory.newFullArea(_areaPack, (e,t,t0){ _stop(false, 0); });
    es.forEach((e){
      e.addToWorld();
      print("add to world : ${e}");
    });
    //HACK screen should be converted into WebComponent
    showScreen('none');
    window.animationFrame.then(_loop);
  }

  bool _stop(bool viaExit, int cubesGrabbed) {
    if (_status == Status.RUNNING) {
      _updateStatus(Status.STOPPING);
    }
    _stats
      .updateCubesLast(area, (viaExit)? cubesGrabbed : 0)
      .then((stats){
        var runresult = query('#runresult').xtag;
        runresult.areaId = area;
        runresult.cubesLast = stats[area + Stats.AREA_CUBES_LAST_V];
        runresult.cubesMax = stats[area + Stats.AREA_CUBES_MAX_V];
        runresult.cubesTotal = stats[area + Stats.AREA_CUBES_TOTAL_V];
        query('#runresult_dialog').xtag.show();
      });
  }

  Future _initialize(String areaId) {
    print("Request init");
    if (_status == Status.INITIALIZING) {
      return new Future.error("already initializing an area");
    }
    _updateStatus(Status.INITIALIZING);
    showScreen('screenInit');
    _hud.reset();
    _world.deleteAllEntities();
    //_newWorld();
    return _loadArea(areaId).then((pack){
      _areaPack = pack;
      _updateStatus(Status.INITIALIZED);
      return _areaPack;
    });
  }

  Future _loadArea(String areaId) {
    var fpack = (_assetManager[areaId] == null) ?
        _assetManager.loadPack(areaId, '_areas/${areaId}.pack')
        : new Future.value(_assetManager[areaId]);
//    var fdrones = (_assetManager['drone01'] == null) ?
//        _assetManager.loadAndRegisterAsset('drone01', 'json', '_models/drone01.js', null, null)
//        : new Future.value(_assetManager['drone01']);
    var f0 = (_assetManager['0'] == null) ?
        _assetManager.loadPack('0', '_packs/0/_.pack')
        : new Future.value(_assetManager['0']);
//        _assetManager.loadAndRegisterAsset('drone01', 'shaderProgram', 'packages/glf/shaders/default', null, null)
//        : new Future.value(_assetManager['drone01']);
    return Future.wait([fpack, f0]).then((l) => l[0]);
  }

  void _setupWorld(Element container) {
    _world.addManager(new PlayerManager());
    _world.addManager(new GroupManager());
    _world.addSystem(new System_DroneGenerator(_entitiesFactory, _player));
    _world.addSystem(new System_DroneController());
    _world.addSystem(new System_DroneHandler(_entitiesFactory, this));
    //_world.addSystem(new System_Physics(false), passive : false);
    _world.addSystem(new System_Simulator()
      ..globalAccs.setValues(0.0, 0.0, 0.0)
      ..steps = 3
      //..collSpace = new collisions.Space_Noop()
      //..collSpace = new collisions.Space_XY0(new collisions.Checker_MvtAsPoly4(), new _EntityContactListener(new ComponentMapper<Collisions>(Collisions,_world)))
      ..collSpace = new collisions.Space_QuadtreeXY(new collisions.Checker_MvtAsPoly4(), new _EntityContactListener(new ComponentMapper<Collisions>(Collisions,_world)), grid : new collisions.QuadTreeXYAabb(-10.0, -10.0, 220.0, 220.0, 5))
    );
    _world.addSystem(
        new System_CameraFollower()
        ..playerToFollow = _player
    );
    _world.addSystem(new System_CubeGenerator(_entitiesFactory));
    _world.addSystem(new System_Animator());
    // Dart is single Threaded, and System doesn't run in // => component aren't
    // modified concurrently => Render3D.process like other System
    _world.addSystem(new System_Render3D(_gl, _assetManager), passive : false);
    var canvases = container.queryAll("canvas");
    if (canvases.length > 1) {
      _world.addSystem(new proto.System_Renderer(canvases[1])
        ..scale = 2.0
        ..translateX = 10
        ..translateY = 50
      );
    }
    if (_audioManager != null) _world.addSystem(new System_Audio(_audioManager, clipProvider : (x) => _assetManager[x]), passive : false);
    _world.addSystem(_hud);
    _world.addSystem(new System_EntityState());
    _world.initialize();
  }

  // TODO add notification of errors
  static AssetManager _newAssetManager(Element bar) {
    var tracer = new AssetPackTrace();
    var stream = tracer.asStream().asBroadcastStream();
    new ProgressControler(bar).bind(stream);
    new EventsPrintControler().bind(stream);

    var b = new AssetManager(tracer);
    b.loaders['img'] = new ImageLoader();
    b.importers['img'] = new NoopImporter();
    return b;
  }
  AudioManager _newAudioManager(baseUrl, AssetManager am) {
    try {
//      var audioManager = new AudioManager(baseUrl);
//      audioManager.mute = false;
//      audioManager.masterVolume = 1.0;
//      audioManager.musicVolume = 0.5;
//      audioManager.sourceVolume = 0.9;
//      registerSimpleAudioWithAssetManager(audioManager, am);
//      return audioManager;
      return null;
    } catch (e) {
      handleError(e);
      return null;
    }
  }

  WebGL.RenderingContext _newRenderingContext(CanvasElement canvas, AssetManager am) {
    var gl = canvas.getContext3d(alpha: false, depth: true);
    registerGlfWithAssetManager(gl, am);
    return gl;
  }

  void _preloadAssets() {
    _assetManager.loadAndRegisterAsset('explosion', 'audioclip', 'sfxr:3,,0.2847,0.7976,0.88,0.0197,,0.1616,,,,,,,,0.5151,,,1,,,,,0.72', null, null);
  }
  void _loop(num highResTime) {
    if ((_world != null) && (_status == Status.RUNNING)) {
      window.animationFrame.then(_loop);
      timeInfo.time = highResTime;
      var world = _world;
      world.delta = timeInfo.delta;
      world.process();
      //_worldRenderSystem.process();
    } else {
      timeInfo.reset();
    }
  }

}

class EventsPrintControler {

  EventsPrintControler();

  StreamSubscription bind(Stream<AssetPackTraceEvent> tracer) {
    return tracer.listen(onEvent);
  }

  void onEvent(AssetPackTraceEvent event) {
    print("AssetPackTraceEvent : ${event}");
  }
}