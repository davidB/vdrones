library vdrones;

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:html';
import 'dart:svg' as svg;
import 'dart:collection';
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:lawndart/lawndart.dart';
import 'package:dartemis/dartemis.dart';
import 'package:dartemis_toolbox/system_entity_state.dart';
import 'package:dartemis_toolbox/system_animator.dart';
import 'package:dartemis_toolbox/system_simple_audio.dart';
import 'package:dartemis_toolbox/system_transform.dart';
import 'package:dartemis_toolbox/system_verlet.dart';
import 'package:dartemis_toolbox/system_particles.dart';
import 'package:dartemis_toolbox/utils.dart';
import 'package:dartemis_toolbox/utils_math.dart' as Math2;
import 'package:dartemis_toolbox/ease.dart' as ease;
import 'package:dartemis_toolbox/collisions.dart' as collisions;
import 'package:dartemis_toolbox/system_proto2d.dart' as proto2d;
import 'package:dartemis_toolbox/colors.dart';
import 'package:vector_math/vector_math.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:simple_audio/simple_audio_asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_asset_pack.dart';
import 'package:glf/glf_renderera.dart';
import 'package:game_loop/game_loop_html.dart';
import 'package:crypto/crypto.dart';
import 'package:google_games_v1_api/games_v1_api_browser.dart' as gamesbrowser;

import 'vdrone_info.pb.dart';
import 'cfg.dart' as cfg;
import 'events.dart';

part 'vdrones/components.dart';
part 'vdrones/system_physics.dart';
part 'vdrones/system_renderer.dart';
part 'vdrones/system_controller.dart';
part 'vdrones/system_hud.dart';
part 'vdrones/factory_physics.dart';
part 'vdrones/factory_entities.dart';
part 'vdrones/factory_animations.dart';
part 'vdrones/factory_renderables.dart';
part 'vdrones/stats.dart';
part 'vdrones/areadef.dart';
part 'vdrones/asset_loaders.dart';
part 'vdrones/storage.dart';
part 'vdrones/data_services.dart';


class VDrones {
  //var _evt = new Evt();
  var _devMode = true; //document.location.href.indexOf('dev=true') > -1;
  var _status = IGStatus.NONE;
  var _world;
  var _entitiesFactory;
  var _hudSystem;
  var _renderSystem;
  var _proto2dSystem;
  var _player = "u0";
  var areaReq;
  var _areaPack;
  var _stats = new Stats("u0", clean : false);
  var _assetManager;
  var _textures;
  var _gl;
  var _gameLoop;
  var _runReport;

  Element el;
  var audioManager;
  DataServices dataServices;
  var bus;

  init() {
    _world = new World();
    _gameLoop = new GameLoopHtml(el);

    _gl = _newRenderingContext(el.querySelectorAll("canvas")[0]);

    var bar = querySelector('#gameload');
    _assetManager = _newAssetManager(bar, _gl, audioManager);
    _preloadAssets();

    _textures = new glf.TextureUnitCache(_gl);
    _entitiesFactory = new Factory_Entities(_world, _assetManager, new Factory_Physics(), new Factory_Renderables(new glf.MeshDefTools(), _textures));
    _setupWorld(el);
    _setupGameLoop(el);

    el.tabIndex = -1;
    el.focus();
    bus.on(eventInGameReqAction).listen(onReqAction);
  }

  onReqAction(int req){
    switch(req) {
      case IGAction.INITIALIZE:
        _initialize();
        break;
      case IGAction.PLAY:
        _play();
        break;
      case IGAction.PAUSE:
        _pause();
        break;
      case IGAction.STOP:
        _stop(false, 0);
        break;
    }
  }

  get status => _status;
  void _updateStatus(int v) {
    _status = v;
    bus.fire(eventInGameStatus, new IGStatus()
    ..kind = v
    ..area = areaReq
    );
  }

  get area => (_areaPack == null) ? null : _areaPack.name;

  bool _play() {
    try {
    if  (!(_status == IGStatus.INITIALIZED || _status == IGStatus.STOPPING)){
      print("NOT playable : ${_status}");
      return false;
    }
    if (_status != IGStatus.INITIALIZED) {
      print("initialize : ${_status}");
      _initialize().then((_) => _start());
      return true;
    } else {
      _start();
      return true;
    }
    } on Object catch(e, st) {
      _handleError(e, st);
    }
  }

  _now() => new Int64(new DateTime.now().toUtc().millisecondsSinceEpoch);

  void _start() {
    _updateStatus(IGStatus.PLAYING);
    //TODO spawn drone
    //TODO start area (=> start chronometer)
    var es = _entitiesFactory.newFullArea(_areaPack, (e,t,t0){ _stop(false, 0); });
    es.forEach((e){
      e.addToWorld();
    });

    var n = _now();
    _runReport = new RunReport()
    ..cubeCount = 0
    ..exiting = false
    ..crashCount = 0
    ..nohit = true
    ..startTime = n
    ..endTime = n
    ..timeLeft = -1
    ;

    _resume();
  }

  bool _stop(bool viaExit, int cubesGrabbed) {
    if (_status == IGStatus.PLAYING) {
      _updateStatus(IGStatus.STOPPING);
      _gameLoop.stop();
    }
    _runReport
    ..cubeCount = cubesGrabbed
    ..exiting = viaExit
    ..crashCount = 0
    ..nohit = true
    ..endTime = _now()
    ..timeLeft = -1
    ;

    var result = dataServices.processRunReport(area, _runReport);
    bus.fire(eventRunResult, result);
    _initialize();
  }

  Future _initialize() {
    if (_status == IGStatus.INITIALIZING) {
      return new Future.error("already initializing an area");
    }
    _updateStatus(IGStatus.INITIALIZING);
    _hudSystem.reset();
    _world.deleteAllEntities();
    //_newWorld();
    return _loadArea(areaReq).then((pack){
      _areaPack = pack;
      _updateStatus(IGStatus.INITIALIZED);
      return _areaPack;
    });
  }

  Future _loadArea(String areaId) {
    var fpack = (_assetManager[areaId] == null) ?
        _assetManager.loadPack(areaId, '_areas/${areaId}.pack')
        : new Future.value(_assetManager[areaId]);
    var f0 = (_assetManager['0'] == null) ?
        _assetManager.loadPack('0', '_packs/0/_.pack')
        : new Future.value(_assetManager['0']);
    return Future.wait([fpack, f0]).then((l) => l[0]);
  }

  void _setupWorld(Element container) {
    //var collSpace = new Coll.Space_Noop();
    var collChecker = new collisions.Checker_MvtAsPoly4()
    ..printCollidePS = false
    ;
    var collSpace = new collisions.Space_XY0(collChecker, new _EntityContactListener(new ComponentMapper<Collisions>(Collisions,_world)));
    _renderSystem = new System_Render3D(_gl, _assetManager, _textures);
    _hudSystem = new System_Hud(container, _player);


    //var collSpace = new collisions.Space_QuadtreeXY(new collisions.Checker_MvtAsPoly4(), new _EntityContactListener(new ComponentMapper<Collisions>(Collisions,_world)), grid : new collisions.QuadTreeXYAabb(-10.0, -10.0, 220.0, 220.0, 5));
    _world.addManager(new PlayerManager());
    _world.addManager(new GroupManager());
    _world.addSystem(new System_DroneGenerator(_entitiesFactory, _player));
    _world.addSystem(new System_DroneController());
    _world.addSystem(new System_DroneHandler(_entitiesFactory, this));
    _world.addSystem(new System_CubeGenerator(_entitiesFactory));
    _world.addSystem(new System_EntityState());
    _world.addSystem(new System_Animator());

    // Simulator should run after entityState or any system thta can modify physics property (collision, positions, ...)
    // else some action could run twice (print frame to debug)
    _world.addSystem(new System_Simulator()
      ..globalAccs.setValues(0.0, 0.0, 0.0)
      ..steps = 3
      ..collSpace = collSpace
    );

    // Audio + Video display
    _world.addSystem(
        new System_CameraFollower()
        ..playerToFollow = _player
        ..collSpace = collSpace
    );

    _world.addSystem(_renderSystem, passive: true);
    var canvases = container.querySelectorAll("canvas");
    if (canvases.length > 1) {
      _proto2dSystem = new proto2d.System_Renderer(canvases[1])
      ..scale = 2.0
      ..translateX = 10
      ..translateY = 500
      ;
      _world.addSystem(_proto2dSystem, passive:true);
    }
    if (audioManager != null) _world.addSystem(new System_Audio(audioManager, clipProvider : (x) => _assetManager[x], handleError: _handleError), passive : false);
    _world.addSystem(_hudSystem, passive: true);
    _world.initialize();
  }

  _handleError(e, st) {
    bus.fire(eventErr, new Err()
    ..category = "ingame"
    ..exc = e
    ..stacktrace = st
    );
  }

  // TODO add notification of errors
  static AssetManager _newAssetManager(Element bar, gl, audioManager) {
    var tracer = new AssetPackTrace();
    var stream = tracer.asStream().asBroadcastStream();
    new ProgressControler(bar).bind(stream);
    new EventsPrintControler().bind(stream);

    var b = new AssetManager(tracer);
    b.loaders['img'] = new ImageLoader();
    b.importers['img'] = new NoopImporter();
    b.loaders['svg'] = new XmlLoader();
    b.importers['svg'] = new SvgImporter();
    b.loaders['area_svg'] = new XmlLoader();
    b.importers['area_svg'] = new AreaSvgImporter();
    b.loaders['area_json'] = new TextLoader();
    b.importers['area_json'] = new AreaJsonImporter();

    if (gl != null) registerGlfWithAssetManager(gl, b);
    if (audioManager != null) registerSimpleAudioWithAssetManager(audioManager, b);
    return b;
  }

  WebGL.RenderingContext _newRenderingContext(CanvasElement canvas) {
    return canvas.getContext3d(alpha: false, depth: true, antialias:false);
  }

  void _preloadAssets() {
    //_assetManager.loadAndRegisterAsset('explosion', 'audioclip', 'sfxr:3,,0.2847,0.7976,0.88,0.0197,,0.1616,,,,,,,,0.5151,,,1,,,,,0.72', null, null);
  }

  _setupGameLoop(element){
    _gameLoop.pointerLock.lockOnClick = false;
    _gameLoop.onVisibilityChange = (gameLoop){
      if (!gameLoop.isVisible) _pause();
    };
    _gameLoop.onUpdate = (gameLoop){
      try {
        _world.delta = gameLoop.dt * 1000.0;
        _world.process();
      } catch(e, s) {
        _handleError(e, s);
      }
    };
    _gameLoop.onRender = (gameLoop){
      try {
        _renderSystem.process();
        _hudSystem.process();
        if (_proto2dSystem != null) _proto2dSystem.process();
      } catch(e, s) {
        _handleError(e, s);
      }
    };
    return _gameLoop;
  }

  _pause() {
    audioManager.pauseAll();
    _gameLoop.stop();

    var pauseOverlay = querySelector("#pauseOverlay");
    if (pauseOverlay != null) {
      pauseOverlay.style.visibility = "visible";
      pauseOverlay.onClick.first.then((_){
        _resume();
      });
    }
  }

  _resume() {
    var pauseOverlay = querySelector("#pauseOverlay");
    if (pauseOverlay != null) {
      pauseOverlay.style.visibility = "hidden";
    }
    _gameLoop.start();
    audioManager.resumeAll();
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