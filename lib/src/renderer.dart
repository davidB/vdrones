part of vdrones;

class CameraMove {
  num offsetX = -1;
  num offsetY = -1;
  num deltaX = 0;
  num deltaY = 0;
  num x = 0;
  num y = 0;

  CameraMove(Element container) {
    x = container.client.width / 2;
    y = container.client.height / 2;
  }
}
// for addition of SSAO (ambient occlusion, take a look at http://mrdoob.com/projects/htmleditor/#B/tRfbbptI9Nn9iln3oaQh4KQbbdeXrBLn0oemieJU1arqwwCDmQYYdmaI41T+9565gMEmVaNtLdlmzn3OnfEfp1fT23+vz1Ais/Toxdj89cYJwRH898YZkRiFCeaCyEm/lPHe275GCLlMiXrqBSxaom/qqRfg8G7OWZlHeyFLGR+ilwP9GWl0hvmc5kNkj+ye8DhliyFKaBSRXENXSrhfSR/71pKx0mIUh5wWEgkeTvqJlMXQ9zMeMRZ4cyqTMvBClvky4YR4X4UflDSN7DGjOYD6RyBey1Dini+RPOCsSInw4VkkOCJc+FNWLGf6eUvBL5A+mx1fPSH9/ykomJAFZyERguZz/yyOSSinLAP4r73JhqIbksNlrrEQv1HJJRZ3v1mFCUqnkrWeoxcqrX0fLRi/w7o4UMw4FBVnGUFBOYf8N1aELCLenLF5SrQNha+JaJn5VIgSbIigHGn6D40mbw7/fjt4Ge4fKOk0Rg5a0DxiC4/mOeGfaCQTNJlM0ADtoG9dOFRgTnLZgI1aZO8InSdyg84AR2ilC7in79m7x3AbnBGOXSRCkhMXcR1hwkcVXnWFoj5FpJDJJZaEU5y65ngLzYFIF4U2/0babzSn0tnRjDinGbCokzrGZR5KynJkSKADaZsqzWB4Thbo9t3N2Zn3iQQX728sxoqrKT1obTP6SDo86HZ5xLJHLCwz5RjVmTxcFCBumkC3cerbexHLzlKiqCou/WOc1bLwGgq9gOqj92SqsQ7669DtiJvfYZKL9gfqOxhUaowGDxxJlY+8R1B2qNqwxuogtdTPFKTybE8Hq4W/Cr6CcW9OK99pCR6O4LKGuHk9HW8CyS35siVlWgbkwiIca7P6VtyKMbNZ0WK8JCI5wYKGVc44kNN2wgwe4liNGLRClf2qvBykpFEQMxjB31i5Rz3s7qqCWBtrlIL8LYVOfQl3bZW1tKc41u59AGYwLfE4hthkkI2v0Z9g0h46qGbfBsfy2RyPP8vBmcTdVnVSbVnSSbWlvUklQgwdS6lrHJftY5f5EPldtG8l6TwyKaXDUWnQv6t1wKCT6n7RzjcNMv0YFNmk1sf3NPiM+hp/c3Fy3EdfRm2ujzmFhMlEzVcBPkqaCi9MGZRGU4FXVhxVwrX6WbuwNEczbWOO56ojGMywJbiNcxEsSJI8dFE2MS6qDBpu3GhVN6umgV6QQoOCAVbf+AM7sSB7IXBye9Y1mpftz61rtleHdQes+1G1VEB81bx0GrzrbcCpxodtkDttB5sJ8VRjN9ifbOIuBALWwXOaSuVZ6wUCk05IA1Q1P/8hXrkYywqpcutcQ9Zer/OMaPd0JIa5tYXUa17Fb9jqdPuMXslT5YhX6It3j9NS9fCGZ55iEjDcahY17Z456bYlmvgofzRNsUMnB/CPGc87+eINNpNDt2wWwiaWA53kJXkqnayHG45ftbeEentYLwr/wUYljzUcKM45mOFUdFshlDTTOV/AO4sKcx4SL2cLp0lnWlir/xq212jgwYg6GHWRLTfJ9hsizaBVb0qcRqTRYloVvbHQmIeNamqtWXVhPSk/L9N0w9lWbMVaO7mx9459854G723qTfI7)
void setupRenderer(Evt evt, Element container, Animator animator) {
  const FAR = 1000;
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
  var _devMode = false;

  String _cameraTargetObjId = null;
  var _cameraTargetObj = null;

  //#_camera = new js.Proxy(THREE.PerspectiveCamera, 75, 1, 1, 500)
  var _camera = new js.Proxy.withArgList(THREE.OrthographicCamera, [10,10,10,10, 1, FAR]);
  //#_camera =  new js.Proxy(THREE.CombinedCamera, -20, -20, 45, 1, 500, 1, 1000)
  //#_camera.toOrthographic()
  //_camera.gameDriven = true;
  //#HACK to clean
  //#see http://help.dottoro.com/ljorlllt.php
  js.retain(_camera);

  dynamic clearScene(scene) {
    // create a new Scene for each call or set children.length to 0 generate (stranges) error at runtime
    // so the working solution in to reuse scene instance, and to remove every object3D
    if (scene == null) {
      scene = js.retain(new js.Proxy(THREE.Scene));
      //scene.fog = new js.Proxy(THREE.Fog, 0x59472b, 1000, FAR );
    }
    void clearChildren( obj ) {
      for ( var i = obj.children.length - 1; i > -1; i--) {
        //clearChildren(obj.children[ i ]);
        //scene.__removeObject(obj.children[ i ]);
        obj.remove(obj.children[ i ]);
      }
    }
    clearChildren(scene);
    return scene;
  }
  var _scene = clearScene(null);

  var cmove = new CameraMove(container);
  void nLookAt(camera, v3) {
    var dx = ( (cmove.x + cmove.deltaX) / container.client.width - 0.5 ) * 100;
    var dy =- ( (cmove.y + cmove.deltaY) / container.client.height - 0.5 ) * 100;
    camera.position.z = v3.z + 30;
    camera.position.y = v3.y + dy;
    camera.position.x = v3.x + dx;
    camera.lookAt(v3);
  }

  List<StreamSubscription> sssMouseMotionToControlCamera = null;
  void registerMouseMotionToControlCamera() {
    if (sssMouseMotionToControlCamera != null) return;
    //#_cameraControls = new js.Proxy(THREE.DragPanControls, _camera)
    sssMouseMotionToControlCamera = [
      Element.mouseMoveEvent.forTarget(container, useCapture: false).listen((evt){
        if (cmove.offsetX > -1)
          cmove.deltaX = evt.client.x - cmove.offsetX;
        if (cmove.offsetY > -1)
          cmove.deltaY = evt.client.y - cmove.offsetY;
      }),
      Element.mouseDownEvent.forTarget(container).listen((evt){
        cmove.offsetX = evt.client.x;
        cmove.offsetY = evt.client.y;
      }),
      Element.mouseUpEvent.forTarget(container).listen((evt){
        cmove.offsetX = -1;
        cmove.offsetY = -1;
        cmove.x = cmove.x + cmove.deltaX;
        cmove.y = cmove.y + cmove.deltaY;
        cmove.deltaX = 0;
        cmove.deltaY = 0;
      })
    ];
  }
  void unregisterMouseMotionToControlCamera() {
    if (sssMouseMotionToControlCamera != null) return;
    sssMouseMotionToControlCamera.forEach((x) => x.cancel());
    sssMouseMotionToControlCamera = null;
  }

  var _renderer = new js.Proxy(THREE.WebGLRenderer, js.map({
    "clearAlpha": 1,
    "antialias": true
    //#preserveDrawingBuffer: true # to allow screenshot
  }));
  _renderer.shadowMapEnabled = true;
  _renderer.shadowMapSoft = true; // to antialias the shadow;
  _renderer.shadowMapType = THREE.PCFShadowMap;
  _renderer.setClearColorHex(0xEEEEEE, 1.0);
  _renderer.autoClear = false;
  //_renderer.sortObjects = false;
  //_renderer.setSize(container.client.width, container.client.height);
  js.retain(_renderer);

  void updateViewportSize(evt){
    js.scoped((){
      var w = container.client.width; //window.innerWidth
      var h = container.client.height; //window.innerHeight
      var unitperpixel = 0.1;
      _renderer.setSize(w, h);
      //_camera.aspect = w /  h;
      _camera.left = w / -2 * unitperpixel;
      _camera.right = w / 2 * unitperpixel;
      _camera.top = h /2 * unitperpixel;
      _camera.bottom = h / -2 * unitperpixel;
      _camera.updateProjectionMatrix();
      //_controls.handleResize();
    });
  }

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
    _renderer.clear();
    _renderer.render(_scene, _camera);
  });

  }

  void addLights(scene, camera) {
    var ambient= new js.Proxy(THREE.AmbientLight,  0x444444 );
    scene.add(ambient);

    //var light = new js.Proxy.withArgList(THREE.DirectionalLight,  [0xffffff, 1, 0] );
    var light = new js.Proxy.withArgList(THREE.SpotLight,  [0xffffff, 1.0, 0.0, math.PI, 1] );
    light.position.set( 40, 40, 100 );
    light.target.position.set( 90, 90, 0 );

    light.castShadow = true;

    light.shadowCameraNear = 5;
    light.shadowCameraFar = 200;
    light.shadowCameraFov = 110;

    light.shadowCameraVisible = _devMode;

    light.shadowBias = 0.00001;
    light.shadowDarkness = 0.5;

    light.shadowMapWidth = 2048;
    light.shadowMapHeight = 2048;

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
      _cameraTargetObjId = null;
      _cameraTargetObj = null;
      _scene = clearScene(_scene);
      addLights(_scene, _camera);
      _renderer.clear();
      nLookAt(_camera, _scene.position);
      updateViewportSize(null);
      registerMouseMotionToControlCamera();
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

  Future spawnObj(String id, Position pos, EntityProvider gpof, [options]) {
    return js.scoped((){
      try {
        var parent = _scene;
        var obj = parent.getChildByName(id, false);
        if (obj != null) {
          throw new Exception("ignore spawnObj with exiting id ${id} ${obj}");
        }
        obj = gpof.obj3dF();
        if (obj == null) {
          print("can't create obj ${id}");
          return new Future.immediate(null);
          //throw new Exception("can't create obj ${id}");
        }

        obj.name = id;
        obj.position.x = pos.x;
        obj.position.y = pos.y;
        //obj.position.z = 0.0;
        if (!(obj.rotation is num)) obj.rotation.z = pos.a;
        //obj.castShadow = true;
        //obj.receiveShadow = true;
        parent.add(obj);
        if (_cameraTargetObjId == id) {
          _cameraTargetObj = obj;
        }
        _anims[id] = gpof.anims; //clone ?
        obj = js.retain(obj);

        var anim = _anims[id]["spawn"];
        return ( anim != null) ? anim(animator, obj) : new Future.immediate(obj);
      } catch (err) {
        return new Future.immediateError(err);
      }
    });
  }

  Future _despawnObj0(dynamic obj, [options]) {
    return js.scoped((){
      var anims = _anims[obj.name];
      var preAnim = (options == null) ? null : anims[options["preAnimName"]];
      preAnim = (preAnim != null) ? preAnim : anims['despawnPre'];
      return (preAnim != null) ? preAnim(animator, obj) : new Future.immediate(obj);
    }).then((obj) => js.scoped((){
      if (_cameraTargetObjId == obj.name || _cameraTargetObj == obj) {
        _cameraTargetObj = null;
      }
      _scene.remove(obj);
      if (options != null && options["deferred"] != null) {
        options["deferred"].complete(obj.name);
      }
      js.release(obj);
    })).catchError((err){print(err); throw err;});
  }

  Future despawnObj(String id, [options]) {
    return new Future.of(() => js.scoped((){
      var obj0 = _scene.getChildByName(id, false);
      if (obj0 == null) throw new StateError("obj not found : ${id}");
      return js.retain(obj0);
    })).then((obj) => _despawnObj0(obj, options));
  }

  Future popObj(String id, Position pos, EntityProvider gpof, [options]) {
    return spawnObj(id, pos, gpof, options).then((obj) => _despawnObj0(obj, options));
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
    if (_cameraTargetObj != null) {
      js.retain(_cameraTargetObj);
    }
  });
  });
  evt.AreaSpawn.add(spawnObj);
  evt.ObjSpawn.add(spawnObj);
  evt.ObjMoveTo.add(moveObjTo);
  evt.ObjDespawn.add(despawnObj);
  evt.ObjPop.add(popObj);
});
}

