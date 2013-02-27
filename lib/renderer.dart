library vdrones_renderer;

//import 'package:three/three.dart' as three;
import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'events.dart';
import 'entities.dart';
import 'animations.dart';
import 'package:logging/logging.dart';

import 'package:js/js.dart' as js;

class CameraMove {
  num offsetX = -1;
  num offsetY = -1;
  num deltaX = 0;
  num deltaY = 0;
  num x = 0;
  num y = 0;

  CameraMove(Element container) {
    x = container.clientWidth / 2;
    y = container.clientHeight / 2;
  }
}

void setupRenderer(Evt evt, Element container, Animator animator) {
js.scoped((){
    final THREE = js.context.THREE;
    js.retain(THREE);
//  if (!webglDetector.webgl) {
//    // #TODO display message if Webgl required
//    //#_renderer = new js.Proxy(THREE.CanvasRenderer, )
//    throw new UnsupportedError('WebGL unsupported');
//  }

  var _anims = new Map<String, Map<String, Animate>>();
  var _logger = new Logger("renderer");
  var _scene = new js.Proxy(THREE.Scene);
  js.retain(_scene);
  var _devMode = false;
  var _areaBox = null;
  var _cameraTargetObjId = null;
  var _cameraTargetObj = null;

  //#_camera = new js.Proxy(THREE.PerspectiveCamera, 75, 1, 1, 500)
  var _camera = new js.Proxy.withArgList(THREE.OrthographicCamera, [10,10,10,10, 1, 1000]);
  //#_camera =  new js.Proxy(THREE.CombinedCamera, -20, -20, 45, 1, 500, 1, 1000)
  //#_camera.toOrthographic()
  //_camera.gameDriven = true;
  //#HACK to clean
  //#see http://help.dottoro.com/ljorlllt.php
  js.retain(_camera);


  var cmove = new CameraMove(container);
  void nLookAt(camera, v3) {
    var dx = ( (cmove.x + cmove.deltaX) / container.clientWidth - 0.5 ) * 100;
    var dy =- ( (cmove.y + cmove.deltaY) / container.clientHeight - 0.5 ) * 100;
    camera.position.z = v3.z + 30;
    camera.position.y = v3.y + dy;
    camera.position.x = v3.x + dx;
    camera.lookAt(v3);
  }


  Element.mouseMoveEvent.forTarget(container, useCapture: false).listen((evt){
    if (cmove.offsetX > -1)
      cmove.deltaX = evt.clientX - cmove.offsetX;
    if (cmove.offsetY > -1)
      cmove.deltaY = evt.clientY - cmove.offsetY;
  });
  Element.mouseDownEvent.forTarget(container).listen((evt){
    cmove.offsetX = evt.clientX;
    cmove.offsetY = evt.clientY;
  });
  Element.mouseUpEvent.forTarget(container).listen((evt){
    cmove.offsetX = -1;
    cmove.offsetY = -1;
    cmove.x = cmove.x + cmove.deltaX;
    cmove.y = cmove.y + cmove.deltaY;
    cmove.deltaX = 0;
    cmove.deltaY = 0;
  });
  nLookAt(_camera, _scene.position);
  _scene.add(_camera);
  //#_cameraControls = new js.Proxy(THREE.DragPanControls, _camera)

  var _renderer = new js.Proxy(THREE.WebGLRenderer, js.map({
    "clearAlpha": 1,
    "antialias": true
    //#preserveDrawingBuffer: true # to allow screenshot
  }));
  //_renderer.shadowMapEnabled = true;
  //_renderer.shadowMapSoft = true;
  _renderer.shadowMapEnabled = true;
  //_renderer.shadowMapSoft = true # to antialias the shadow;
  //_renderer.shadowMapType = three.PCFShadowMap;
  _renderer.setClearColorHex(0xEEEEEE, 1.0);
  _renderer.autoClear = true;
  _renderer.clear();
  js.retain(_renderer);

  void updateViewportSize(evt){
    var w = container.clientWidth; //window.innerWidth
    var h = container.clientHeight; //window.innerHeight
    var unitperpixel = 0.1;
    _renderer.setSize(w, h);
    //_camera.aspect = w /  h;
    _camera.left = w / -2 * unitperpixel;
    _camera.right = w / 2 * unitperpixel;
    _camera.top = h /2 * unitperpixel;
    _camera.bottom = h / -2 * unitperpixel;
    _camera.updateProjectionMatrix();
    //_controls.handleResize();
  }

  updateViewportSize(null);
  container.children.add(_renderer.domElement);
  Window.resizeEvent.forTarget(window).listen(updateViewportSize);


  var v3zero = new js.Proxy(THREE.Vector3, 0,0,0);
  js.retain(v3zero);

  void render() {
  js.scoped((){

    // you need to update lookAt every frame
    if (_cameraTargetObj != null) {
      if (_cameraTargetObj.position.z != Z_HIDDEN) {
        nLookAt(_camera, _cameraTargetObj.position);
      }
    } else {
      nLookAt(_camera, v3zero);
    }
    _renderer.render(_scene, _camera);
});

  }

  void addLights(scene, camera) {
    var ambient= new js.Proxy(THREE.AmbientLight,  0x444444 );
    scene.add(ambient);

    var light = new js.Proxy.withArgList(THREE.SpotLight,  [0xffffff, 1, 0, math.PI, 1] );
    light.position.set( 0, 10, 100 );
    light.target.position.set( 0, 0, 0 );

    light.castShadow = true;

    light.shadowCameraNear = 700;
    light.shadowCameraFar = camera.far;
    light.shadowCameraFov = 50;

    light.shadowCameraVisible = _devMode;

    light.shadowBias = 0.0001;
    light.shadowDarkness = 0.5;

    light.shadowMapWidth = 128;
    light.shadowMapHeight = 128;

    scene.add(light);

//    var mainlight = new js.Proxy(THREE.DirectionalLight,  0xffffff );
//    //shadow stuff
//    mainlight.shadowCameraNear = 10;
//    mainlight.shadowCameraFar = 500;
//
//    mainlight.castShadow = true;
//    mainlight.shadowDarkness = 0.5;
//    mainlight.shadowCameraVisible = true;
//    mainlight.shadowMapWidth = 2048;
//    mainlight.shadowMapHeight = 2048;
//    mainlight.target = _scene;
//    mainlight.position.set(0,-10,50);
//    mainlight.rotation.set(0,-0.5,1); //setting elevation and azimuth via mainlight's parent
//
//    //group
//    lights = new js.Proxy(THREE.Object3D, );
//    lights.name = "lights";
//
//    lights.add( mainlight ); //adding mainlight as child to lightTarget (easy rotation controls via parent)
//    lights.add( ambient );
  }

  void start(){
    js.scoped((){
    addLights(_scene, _camera);
//    if (_devMode)
//      evt.SetupDatGui.dispatch((gui) ->
//        f2 = gui.addFolder("Camera")
//        f2.add(_camera, "gameDriven")
//        f2.add(_camera.position, "x").listen()
//        f2.add(_camera.position, "y").listen()
//        f2.add(_camera.position, "z").listen()
//        f2.add(_camera, "fov").listen() if _camera.fov?
//        f2.add(_camera, "inPerspectiveMode").onFinishChange((value) ->
//          updateViewportSize()
//        ) if _camera.inPerspectiveMode?
//        gui.remember(_camera)
//      )
//    else
//      null
    });
  }

  void spawnObj(String id, Position pos, EntityProvider gpof, [options]) {
    js.scoped((){
    print("spawnObj ${id}");
    var ids = id.split('>');
    var parent = _scene;
    for(var i = 0; i< (ids.length - 1); i++) {
      if (parent != null) {
        parent = parent.getChildByName(ids[i], false);
      } else {
        _logger.warning("parent not found ${id}  ${ids[i]}");
      }
    }
    if (parent == null) return;
    var name = ids[ids.length - 1];
    var obj = parent.getChildByName(name, false);
    if (obj != null) {
      _logger.warning("ignore spawnObj with exiting id ${id} ${obj}");
      //#console.trace();
      return;
    }

    obj = gpof.obj3dF();
    if (obj == null) {
      print("can't create ${id}");
      return;
    }

    obj.name = name;
    obj.position.x = pos.x;
    obj.position.y = pos.y;
    //obj.position.z = 0.0;
    obj.rotation.z = pos.a;
    parent.add(obj);
    _anims[id] = gpof.anims; //clone ?
    if (gpof.anims["spawn"] != null) {
      gpof.anims["spawn"](animator, obj);
    }

    if (_cameraTargetObjId == name) {
      _cameraTargetObj = obj;
    }
    js.retain(obj);
    });
  }

  void despawnObj(String id, [options]) {
    var p = new Future.of((){
      var obj;
      js.scoped((){
      obj = js.retain(_scene.getChildByName(id, false));
      if (obj == null) throw new StateError("obj not found : ${id}");
      });
      return obj;
    }).then((obj){
      var b = obj;
      js.scoped((){
        var anims = _anims[id];
        var preAnim = anims[options["preAnimName"]];
        preAnim = preAnim != null ? preAnim : anims['despawnPre'];
        if (preAnim != null) {
          b = preAnim(animator, obj);
        }
      });
      return b;
    }).then((obj){
      js.scoped((){
      if (_cameraTargetObjId == obj.name) {
        _cameraTargetObj = null;
      }
      _scene.remove(obj);
      if (options["deferred"] != null) {
        options["deferred"].complete(id);
      }
      });
      js.release(obj);
    });
  }

//  void spawnScene(String id, Position pos, List<three.Object3D> scene3d){
//
//    //_camera = scene3d.cameras.Camera; // if exists, Camera is the id of the object
//    //_scene.add(_camera);
//    //_scene = scene3d.scene;
//    scene3d.objects.ea, (obj3d) ->
//
//      #obj3d.castShadow = false;
//      #obj3d.receiveShadow  = false;
//      _scene.add(obj3d)
//    )
//    _.each(scene3d.lights, (light) ->
//      light.castShadow = true
//      _scene.add(light)
//    )
//    wall = scene3d.objects.wall
//    updateAreaBox(wall.geometry.vertices, wall.scale, wall.position)

//  updateAreaBox = (vertices, scale, position) ->
//    _areaBox = _.reduce(vertices, (acc, v) ->
//      acc.xmin = Math.min(acc.xmin, v.x)
//      acc.ymin = Math.min(acc.ymin, v.y)
//      acc.xmax = Math.max(acc.xmax, v.x)
//      acc.ymax = Math.max(acc.ymax, v.y)
//      acc
//    ,{
//      xmin: vertices[0].x
//      ymin: vertices[0].y
//      xmax: vertices[0].x
//      ymax: vertices[0].y
//    })
//    _areaBox.xmin = _areaBox.xmin * scale.x + position.x
//    _areaBox.ymin = _areaBox.ymin * scale.y + position.y
//    _areaBox.xmax = _areaBox.xmax * scale.x + position.x
//    _areaBox.ymax = _areaBox.ymax * scale.y + position.y
//    console.debug("_areaBox", _areaBox)
//    _areaBox

  void moveObjTo(String objId, Position pos) {
    js.scoped((){
    var obj = _scene.getChildByName(objId, false);
    if (obj != null) {
      obj.position.x = pos.x;
      obj.position.y = pos.y;
      obj.rotation.z = pos.a;
    }
    });
  }

  evt.DevMode.add((){
    _devMode = true;
  });
  evt.GameStart.add(start);
  evt.Render.add(render);
  evt.SetLocalDroneId.add((objId){
  js.scoped((){
    _cameraTargetObjId = objId;
    _cameraTargetObj = _scene.getChildByName(_cameraTargetObjId, false);
  });
  });
  evt.AreaSpawn.add(spawnObj);
  evt.ObjSpawn.add(spawnObj);
  evt.ObjMoveTo.add(moveObjTo);
  evt.ObjDespawn.add(despawnObj);
});
}

