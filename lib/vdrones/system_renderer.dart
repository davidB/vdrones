part of vdrones;

typedef Renderable RenderableF(WebGL.RenderingContext gl, Entity e);

class Renderable {
  Geometry geometry;
  Material material;
  glf.RequestRunOn prepare;
  glf.RequestRunOn main;
  List<glf.Filter2D> filters;
  glf.ViewportCamera viewportCamera;
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

class Const3D {
  static const TexNormalsRandomL = "_TexNormalsRandom";
  static const TexVerticesL = "_TexVertices";
  static const TexNormalsL = "_TexNormals";
}

class System_Render3D extends EntitySystem {


  ComponentMapper<RenderableDef> _objDefMapper;
  ComponentMapper<RenderableCache> _objCacheMapper;
  GroupManager _groupManager;

  final RendererA _renderer;
  AssetManager _am;
  Future<AssetManager> _assets;
  bool _hasCamera = false;
  var _passes = null;
  var _sceneAabb;
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
    _renderer = new RendererA(gl)
  ;

  void initialize(){
    _objDefMapper = new ComponentMapper<RenderableDef>(RenderableDef, world);
    _objCacheMapper = new ComponentMapper<RenderableCache>(RenderableCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
    _renderer.clearColor.setValues(0.9, 0.9, 1.0, 1.0);
    _renderer.init();
    _assets = _loadAssets();
    _renderer.debugView = null;

  }

  bool checkProcessing() => _hasCamera;

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
        if (v.viewportCamera != null){
          _renderer.cameraViewport = v.viewportCamera;
          _sceneAabb = (entity.getComponent(CameraFollower.CT) as CameraFollower).focusAabb;
          _assets.then((_){
            _passes = _makePasses(_renderer, _am, _sceneAabb);
            _passes.add();
            _hasCamera = true;
          });
        }
        if( v.geometry != null ) _renderer.addSolid(v.geometry, v.material);
        if( v.filters != null ) _renderer.filters2d.addAll(v.filters);
        if( v.prepare != null ) _renderer.addPrepare(v.prepare);
        if( v.main != null ) _renderer.add(v.main);
//      } else {
//        print("DEBUG: failed to insert 3d ${entity} : provide null ");
      }
    }
  }

  void removed(Entity entity){
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) {
      var v = cache.v;
      if (v != null) {
        //TODO if (v.viewportCamera != null) _renderer.cameraViewport = v.viewportCamera;
        if (v.viewportCamera != null){
          if (_passes != null) _passes.remove();
          _renderer.cameraViewport = null;
          _hasCamera = false;
        }
        if( v.geometry != null ) _renderer.removeSolid(v.geometry);
        if( v.filters != null ) v.filters.forEach((e) => _renderer.filters2d.remove(e));
        if( v.prepare != null ) _renderer.removePrepare(v.prepare);
        if( v.main != null ) _renderer.remove(v.main);
      }
      cache.v = null;
      entity.removeComponentByType(RenderableCache.CT);
    }
  }

  Future<AssetManager> _loadAssets() {
    return Future.wait([
      //factory_filter2d.init(),
      _am.loadAndRegisterAsset('shader_depth_light', 'shaderProgram', 'packages/glf/shaders/depth_light{.vert,.frag}', null, null),
      _am.loadAndRegisterAsset('shader_deferred_normals', 'shaderProgram', 'packages/glf/shaders/deferred{.vert,_normals.frag}', null, null),
      _am.loadAndRegisterAsset('shader_deferred_vertices', 'shaderProgram', 'packages/glf/shaders/deferred{.vert,_vertices.frag}', null, null),
      _am.loadAndRegisterAsset('filter2d_blend_ssao', 'filter2d', 'packages/glf/shaders/filters_2d/blend_ssao.frag', null, null),
      _am.loadAndRegisterAsset('filter2d_identity', 'filter2d', 'packages/glf/shaders/filters_2d/identity.frag', null, null),
      _am.loadAndRegisterAsset('texNormalsRandom', 'tex2d', '_images/normalmap.png', null, null)
    ]).then((l) => _am);
  }


  _makeLightPass(renderer, am, sceneAabb) {
    var light = new glf.ViewportCamera()
      ..viewWidth = 1024
      ..viewHeight = 1024
      ..camera.fovRadians = degrees2radians * 55.0
      ..camera.aspectRatio = 1.0
      ..camera.isOrthographic = true
      ..camera.left = -50.0 * 1.2
      ..camera.right = 50.0 * 1.2
      ..camera.top = 50.0 * 1.2
      ..camera.bottom = -50.0 * 1.2
      ..camera.position.setValues(10.0, 10.0, 80.0)
      //..camera.focusPosition.setValues(50.0, 50.0, 0.0)
      ..camera.focusPosition.setFrom(sceneAabb.center)
      ..camera.adjustNearFar(sceneAabb, 0.1, 0.1)
      ;
    var lightFbo = new glf.FBO(renderer.gl)..make(width : light.viewWidth, height : light.viewHeight);
    var lightCtx = am['shader_depth_light'];
    var lightR = light.makeRequestRunOn()
      ..ctx = lightCtx
      ..setup = light.setup
      ..before =(ctx) {
        ctx.gl.bindFramebuffer(WebGL.FRAMEBUFFER, lightFbo.buffer);
        ctx.gl.viewport(light.x, light.y, light.viewWidth, light.viewHeight);
        ctx.gl.clearColor(1.0, 1.0, 1.0, 1.0);
        ctx.gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
        light.injectUniforms(ctx);
      }
    ;

    var r = new glf.RequestRunOn()
      ..autoData = (new Map()
        ..["sLightDepth"] = ((ctx) => _textures.inject(ctx, lightFbo.texture, "sLightDepth"))
        ..["lightFar"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightFar'), light.camera.far))
        ..["lightNear"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightNear'), light.camera.near))
        ..["lightConeAngle"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightConeAngle'), light.camera.fovRadians * radians2degrees))
        ..["lightProj"] = ((ctx) => glf.injectMatrix4(ctx, light.camera.projectionMatrix, "lightProj"))
        ..["lightView"] = ((ctx) => glf.injectMatrix4(ctx, light.camera.viewMatrix, "lightView"))
        ..["lightRot"] = ((ctx) => glf.injectMatrix3(ctx, light.camera.rotMatrix, "lightRot"))
        ..["lightProjView"] = ((ctx) => glf.injectMatrix4(ctx, light.camera.projectionViewMatrix, "lightProjView"))
        //..["lightVertex"] = ((ctx) => ctx.gl.uniform1fv(ctx.getUniformLocation('lightVertex'), light.camera.position.storage))
      )
      ;
    return new _RendererPass()
    ..data = lightFbo
    ..add  = () {
      renderer.add(r);
      renderer.addPrepare(r);
      renderer.addPrepare(lightR);
    }
    ..remove = () {
      renderer.remove(r);
      renderer.removePrepare(r);
      renderer.removePrepare(lightR);
    }
    ;
  }

  _makePasses(renderer, AssetManager am, sceneAabb) {
    var deferred = _makeDeferredPass(renderer, am);
    var texVertices = deferred.data[0].texture;
    var texNormals = deferred.data[1].texture;
    var ssao = _makeSSAOPass(renderer, am, texNormals, texVertices, _am['texNormalsRandom']);
    var identity = _makeIndentityPass(renderer, am);
    var light = _makeLightPass(renderer, am, sceneAabb);
    var pass = new _RendererPass()
    ..data = deferred.data
    ..add = () {
      light.add();
      deferred.add();
      //identity.add();
      ssao.add();
    }
    ..remove = (){
      ssao.remove();
      //identity.remove();
      deferred.remove();
      light.remove();
    }
    ;
    return pass;
  }

  _makeIndentityPass(renderer, am) {
    var filter0 = am['filter2d_identity'];
    var pass = new _RendererPass()
    ..data = filter0
    ..add = () {
      renderer.filters2d.insert(0, filter0);
    }
    ..remove = (){
      renderer.filters2d.remove(filter0);
    }
    ;
    return pass;
  }

  _makeSSAOPass(renderer, am, WebGL.Texture texNormals, WebGL.Texture texVertices, WebGL.Texture texNormalsRandom) {
    var filter0 = _makeSSAOFilter(am, texNormals, texVertices, texNormalsRandom);
    //var filter0 = _am['filter2d_identity'];
    var pass = new _RendererPass()
    ..data = filter0
    ..add = () {
      renderer.filters2d.insert(0, filter0);
    }
    ..remove = (){
      renderer.filters2d.remove(filter0);
    }
    ;
    return pass;
  }

  _makeSSAOFilter(am, WebGL.Texture texNormals, WebGL.Texture texVertices, WebGL.Texture texNormalsRandom) {
    return new glf.Filter2D.copy(am['filter2d_blend_ssao'])
    ..cfg = (ctx) {
      ctx.gl.uniform2f(ctx.getUniformLocation('_Attenuation'), 2.0, 10.0); // (0,0) -> (2, 10) def (1.0, 5.0)
      ctx.gl.uniform1f(ctx.getUniformLocation('_SamplingRadius'), 2.0); // 0 -> 40
      ctx.gl.uniform1f(ctx.getUniformLocation('_OccluderBias'), 0.1); // 0.0 -> 0.2, def 0.05
      _textures.inject(ctx, texNormals, Const3D.TexNormalsL);
      _textures.inject(ctx, texVertices, Const3D.TexVerticesL);
      _textures.inject(ctx, texNormalsRandom, Const3D.TexNormalsRandomL);
    };
  }

  _makeDeferredPass(renderer, AssetManager am) {
    var n = _makePrePass(renderer, am['shader_deferred_normals'], Const3D.TexNormalsL);
    var v = _makePrePass(renderer, am['shader_deferred_vertices'], Const3D.TexVerticesL);
    var pass = new _RendererPass()
    ..data = [v.data, n.data]
    ..add = () {
      v.add();
      n.add();
    }
    ..remove = () {
      n.remove();
      v.remove();
    }
    ;
    return pass;
  }

  _makePrePass(renderer, ctx, texName) {
    var vp = renderer.cameraViewport;
    var fbo = new glf.FBO(renderer.gl)..make(width : vp.viewWidth, height : vp.viewHeight, type: WebGL.FLOAT);
    var pre = new glf.RequestRunOn()
      ..ctx = ctx
      ..before =(ctx) {
        ctx.gl.bindFramebuffer(WebGL.FRAMEBUFFER, fbo.buffer);
        ctx.gl.viewport(vp.x, vp.y, vp.viewWidth, vp.viewHeight);
        ctx.gl.clearColor(1.0, 1.0, 1.0, 1.0);
        ctx.gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
        vp.injectUniforms(ctx);
      }
    ;

    var r = new glf.RequestRunOn()
      ..autoData = (new Map()
        ..[texName] = ((ctx) => _textures.inject(ctx, fbo.texture, texName))
      )
      ;

    var pass = new _RendererPass()
    ..data = fbo
    ..add = () {
      renderer.add(r);
      renderer.addPrepare(r);
      renderer.addPrepare(pre);
    }
    ..remove = () {
      renderer.remove(r);
      renderer.removePrepare(r);
      renderer.removePrepare(pre);
      fbo.dispose();
    }
    ;
    return pass;
  }

}

class _RendererPass {
  var data;
  Function add;
  Function remove;
}
