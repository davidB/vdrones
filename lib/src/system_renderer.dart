part of vdrones;

typedef dynamic ProvideObject3D();
class RenderableDef extends Component {
  ProvideObject3D provide;

  RenderableDef(this.provide);
}
class RenderableCache extends Component {
  var obj;

  RenderableCache(this.obj);
}


class System_Render3D extends EntitySystem {
  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<RenderableDef> _objDefMapper;
  ComponentMapper<RenderableCache> _objCacheMapper;
  GroupManager _groupManager;

  var _scene;
  var _renderer;
  var _camera;
  Element _container;

  System_Render3D(this._container):super(Aspect.getAspectForAllOf([Transform, RenderableDef]));

  void initialize(){
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _objDefMapper = new ComponentMapper<RenderableDef>(RenderableDef, world);
    _objCacheMapper = new ComponentMapper<RenderableCache>(RenderableCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
    js.scoped((){
      var THREE = (js.context as dynamic).THREE;
      _renderer = _newRenderer(THREE);
      _scene = _clearScene(THREE, null);
      // attach into the page
      _container.children.add(_renderer.domElement);
      Window.resizeEvent.forTarget(window).listen(_updateViewportSize);
    });
  }

  void _updateViewportSize(evt){
    js.scoped((){
      var w = _container.client.width; //window.innerWidth
      var h = _container.client.height; //window.innerHeight
      var unitperpixel = 0.1;
      _renderer.setSize(w, h);
      //TODO support enable/change of camera,...
      if (_camera != null) {
        //_camera.aspect = w /  h;
        _camera.left = w / -2 * unitperpixel;
        _camera.right = w / 2 * unitperpixel;
        _camera.top = h /2 * unitperpixel;
        _camera.bottom = h / -2 * unitperpixel;
        _camera.updateProjectionMatrix();
//_controls.handleResize();
      }
    });
  }


  bool checkProcessing() => _camera != null;

  void processEntities(ReadOnlyBag<Entity> entities) {
    js.scoped((){
      entities.forEach((entity){
        var cache = _objCacheMapper.getSafe(entity);
        if (cache != null) {
          var obj = cache.obj;
          var t = _transformMapper.get(entity);
          _applyTransform(obj, t);
        }
      });
    });
  }

  void end() {
    js.scoped((){
      _renderer.clear();
      _renderer.render(_scene, _camera);
    });
  }

  void inserted(Entity entity){
    js.scoped((){
      var objDef = _objDefMapper.get(entity);
      if (objDef != null) {
        var obj = objDef.provide();
        entity.addComponent(new RenderableCache(obj));
        entity.changedInWorld();
        var t = _transformMapper.get(entity);
        obj.name = entity.uniqueId.toString();
        _applyTransform(obj, t);
        _scene.add(obj);
        if (_groupManager.isInGroup(entity, GROUP_CAMERA)) {
          print("set camera");
          _camera = obj;
          _updateViewportSize(null);
        }
      }
    });
    print("inserted into 3d ${entity}");
  }

  void removed(Entity entity){
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) js.scoped((){
      _scene.remove(cache.obj);
      cache.obj = null;
    });
    entity.removeComponent(RenderableCache);
    print("removed 3d ${entity}");
  }

  //TODO on deleted entity with Renderable3D, free the js object

  static void _applyTransform(obj, Transform t) {
    obj.position.set(t.position3d.x, t.position3d.y, t.position3d.z);
    obj.scale.set(t.scale3d.x, t.scale3d.y, t.scale3d.z);
    //obj.position.z = 0.0;
    if (!(obj.rotation is num)) {
      obj.rotation.set(t.rotation3d.x, t.rotation3d.y, t.rotation3d.z);
    }
  }

  static dynamic _newRenderer(THREE) {
    var renderer = new js.Proxy(THREE.WebGLRenderer, js.map({
      "clearAlpha": 1,
      "antialias": true
      //#preserveDrawingBuffer: true # to allow screenshot
    }));
    renderer.shadowMapEnabled = true;
    renderer.shadowMapSoft = true; // to antialias the shadow;
    renderer.shadowMapType = THREE.PCFShadowMap;
    renderer.setClearColorHex(0x010109, 1.0);
    renderer.autoClear = false;
    //_renderer.sortObjects = false;
    //_renderer.setSize(container.client.width, container.client.height);
    return js.retain(renderer);
  }

  static dynamic _clearScene(THREE, scene) {
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
}
