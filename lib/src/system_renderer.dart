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


class System_Render3D extends EntitySystem {
  static const TexNormalsRandomL = "_TexNormalsRandom";
  static const TexNormalsRandomN = 28;
  static const TexVerticesL = "_TexVertices";
  static const TexVerticesN = 29;
  static const TexNormalsL = "_TexNormals";
  static const TexNormalsN = 30;

  ComponentMapper<RenderableDef> _objDefMapper;
  ComponentMapper<RenderableCache> _objCacheMapper;
  GroupManager _groupManager;

  RendererA _renderer;
  AssetManager _am;
  Future<AssetManager> _assets;
  bool _hasCamera = false;
  var _sceneAabb;

  System_Render3D(WebGL.RenderingContext gl, this._am): super(Aspect.getAspectForAllOf([RenderableDef])) {
    //TODO better feedback
    if (gl == null) {
      throw new Exception("webgl not supported");
    }
    _renderer = new RendererA(gl);
  }

  void initialize(){
    _objDefMapper = new ComponentMapper<RenderableDef>(RenderableDef, world);
    _objCacheMapper = new ComponentMapper<RenderableCache>(RenderableCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
    _renderer.clearColor.setValues(0.9, 0.9, 1.0, 1.0);
    _renderer.init();
    _assets = _loadAssets();
  }

  bool checkProcessing() => _hasCamera;

  void processEntities(ReadOnlyBag<Entity> entities) {
    _renderer.run();
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
            _initRendererPre();
            _hasCamera = true;
          });
        }
        if( v.geometry != null ) _renderer.addSolid(v.geometry, v.material);
        if( v.filters != null ) _renderer.filters2d.addAll(v.filters);
        if( v.prepare != null ) _renderer.addPrepare(v.prepare);
        if( v.main != null ) _renderer.add(v.main);
      } else {
        print("failed to insert 3d ${entity} : provide null ");
      }
    }
  }

  void removed(Entity entity){
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) {
      var v = cache.v;
      if (v != null) {
        //TODO if (v.viewportCamera != null) _renderer.cameraViewport = v.viewportCamera;
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

  _initRendererPre() {
    _initRendererPreLight();
    _initRendererPreDeferred();
    _renderer.debugView = null;
  }
  _initRendererPreLight() {
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
      ..camera.focusPosition.setFrom(_sceneAabb.center)
      ..camera.adjustNearFar(_sceneAabb, 0.1, 0.1)
      ;
    var lightFbo = new glf.FBO(_renderer.gl)..make(width : light.viewWidth, height : light.viewHeight);
    var lightCtx = _am['shader_depth_light'];
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
        ..["sLightDepth"] = ((ctx) => glf.injectTexture(ctx, lightFbo.texture, 31, "sLightDepth"))
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
    _renderer.add(r);
    _renderer.addPrepare(r);
    _renderer.addPrepare(lightR);
    //_renderer.debugView = lightFbo.texture;
  }

  _initRendererPreDeferred() {
    var fboN = _initRendererPreDeferred0(_renderer.cameraViewport, _am['shader_deferred_normals'], TexNormalsL, TexNormalsN);
    var fboV = _initRendererPreDeferred0(_renderer.cameraViewport, _am['shader_deferred_vertices'], TexVerticesL, TexVerticesN);
    _renderer.debugView = fboN.texture;
    var filter0 = _makeSSAOFilter(fboN.texture, fboV.texture, _am['texNormalsRandom']);
    //var filter0 = _am['filter2d_identity'];
    _renderer.filters2d.insert(0, filter0);
  }

  _initRendererPreDeferred0(vp, ctx, texName, texNum) {
    var fbo = new glf.FBO(_renderer.gl)..make(width : vp.viewWidth, height : vp.viewHeight, type: WebGL.FLOAT);
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
        ..[texName] = ((ctx) => glf.injectTexture(ctx, fbo.texture, texNum, texName))
      )
      ;
    _renderer.add(r);
    _renderer.addPrepare(r);
    _renderer.addPrepare(pre);
    return fbo;
  }

  _makeSSAOFilter(WebGL.Texture texNormals, WebGL.Texture texVertices, WebGL.Texture texNormalsRandom) {
    return new glf.Filter2D.copy(_am['filter2d_blend_ssao'])
    ..cfg = (ctx) {
      ctx.gl.uniform2f(ctx.getUniformLocation('_Attenuation'), 2.0, 10.0); // (0,0) -> (2, 10) def (1.0, 5.0)
      ctx.gl.uniform1f(ctx.getUniformLocation('_SamplingRadius'), 2.0); // 0 -> 40
      ctx.gl.uniform1f(ctx.getUniformLocation('_OccluderBias'), 0.1); // 0.0 -> 0.2, def 0.05
      glf.injectTexture(ctx, texNormals, TexNormalsN, TexNormalsL);
      glf.injectTexture(ctx, texVertices, TexVerticesN, TexVerticesL);
      glf.injectTexture(ctx, texNormalsRandom, TexNormalsRandomN, TexNormalsRandomL);
    };
  }

}
