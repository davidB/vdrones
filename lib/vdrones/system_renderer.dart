part of vdrones;

typedef Renderable RenderableF(WebGL.RenderingContext gl, Entity e);

class Renderable {
  glf.CameraInfo camera;
  r.ObjectInfo obj;
  List<glf.Filter2D> filters;
  Map ext = {};
}
class RenderableDef extends Component {
  static final CT = ComponentTypeManager.getTypeFor(RenderableDef);

  RenderableF onInsert;

  RenderableDef();
}
class RenderableCache extends Component {
  static final CT = ComponentTypeManager.getTypeFor(RenderableCache);

  Renderable v;

  RenderableCache(this.v);
}

class System_Render3D extends EntitySystem {


  ComponentMapper<RenderableDef> _objDefMapper;
  ComponentMapper<RenderableCache> _objCacheMapper;
  GroupManager _groupManager;

  final r.RendererR _renderer;
  AssetManager _am;
  Future<AssetManager> _assets;
  final glf.TextureUnitCache _textures;

  factory System_Render3D(WebGL.RenderingContext gl, AssetManager am, glf.TextureUnitCache textures)  {
    //TODO better feedback
    if (gl == null) {
      throw new Exception("webgl not supported");
    }
    return new System_Render3D._(gl, am, textures);
  }

  System_Render3D._(gl, this._am, this._textures) :
    super(Aspect.getAspectForAllOf([RenderableDef])),
    _renderer = new r.RendererR(gl)
  ;

  void initialize(){
    _objDefMapper = new ComponentMapper<RenderableDef>(RenderableDef, world);
    _objCacheMapper = new ComponentMapper<RenderableCache>(RenderableCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
    _assets = _loadAssets();
    //_renderer.nearLight = r.nearLight_SpotGrid(10.0);
    _renderer.nearLight = r.nearLight_SpotAt(new Vector3(50.0, 50.0, 10.0));
  }

  bool checkProcessing() => _renderer.camera != null;

  void processEntities(ReadOnlyBag<Entity> entities) {
    _renderer.run();
    //call gl.finish() doesn't prevente frame "tearing" (when you rotate vdrones)
    //see http://www.opengl.org/wiki/Swap_Interval
    //_renderer.gl.finish();
  }

  void inserted(Entity entity){
    var objDef = _objDefMapper.get(entity);
    if (objDef != null) {
      var v = objDef.onInsert(_renderer.gl, entity);
      var cache = new RenderableCache(v);
      if (v != null) {
        entity.addComponent(cache);
        entity.changedInWorld();
        if (v.camera != null) _renderer.camera = v.camera;
        if (v.obj != null) _renderer.register(v.obj);
        if (v.filters != null) _renderer.filters2d.addAll(v.filters);
      }
    }
  }

  void removed(Entity entity){
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) {
      var v = cache.v;
      if (v != null) {
        //TODO if (v.viewportCamera != null) _renderer.cameraViewport = v.viewportCamera;
        if (v.camera != null) _renderer.camera = null;
        if( v.obj != null ) _renderer.unregister(v.obj);
        if( v.filters != null ) v.filters.forEach((e) => _renderer.filters2d.remove(e));
      }
      cache.v = null;
      entity.removeComponentByType(RenderableCache.CT);
    }
  }

  Future<AssetManager> _loadAssets() {
    return Future.wait([
      //factory_filter2d.init(),
      _am.loadAndRegisterAsset('filter2d_fxaa', 'filter2d', 'packages/glf/shaders/filters_2d/fxaa.frag', null, null),
    ]).then((l) => _am);
  }
}

