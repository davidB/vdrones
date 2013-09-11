part of vdrones;

typedef Renderable RenderableF(WebGL.RenderingContext gl, Entity e);
//typedef void SyncObject3D(Entity, dynamic);
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

  //ComponentMapper<Transform> _transformMapper;
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
    //_transformMapper = new ComponentMapper<Transform>(Transform, world);
    _objDefMapper = new ComponentMapper<RenderableDef>(RenderableDef, world);
    _objCacheMapper = new ComponentMapper<RenderableCache>(RenderableCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;

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
    _initSSAO(fboN.texture, fboV.texture, _am['texNormalsRandom']);
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

  _initSSAO(WebGL.Texture texNormals, WebGL.Texture texVertices, WebGL.Texture texNormalsRandom) {
    var ssao = new glf.Filter2D.copy(_am['filter2d_blend_ssao'])
    ..cfg = (ctx) {
      ctx.gl.uniform2f(ctx.getUniformLocation('_Attenuation'), 1.0, 5.0); // (0,0) -> (2, 10) def (1.0, 5.0)
      ctx.gl.uniform1f(ctx.getUniformLocation('_SamplingRadius'), 15.0); // 0 -> 40
      ctx.gl.uniform1f(ctx.getUniformLocation('_OccluderBias'), 0.05); // 0.0 -> 0.2, def 0.05
      glf.injectTexture(ctx, texNormals, TexNormalsN, TexNormalsL);
      glf.injectTexture(ctx, texVertices, TexVerticesN, TexVerticesL);
      glf.injectTexture(ctx, texNormalsRandom, TexNormalsRandomN, TexNormalsRandomL);
    };
//    var ssao = _am['filter2d_identity'];
    _renderer.filters2d.insert(0, ssao);
  }

}
/*
class Renderer {
  final gl;

  final glf.ProgramsRunner lightRunner;
  final glf.ProgramsRunner cameraRunner;
  final glf.ProgramsRunner postRunner;

  var lightCtx = null;

  Renderer(gl) : this.gl = gl,
    lightRunner = new glf.ProgramsRunner(gl),
    cameraRunner = new glf.ProgramsRunner(gl),
    postRunner = new glf.ProgramsRunner(gl)
  ;


  init() {
    _initCamera();
    _initLight();
    _initPost();
  }

  _initCamera() {
    // Camera default setting for perspective use canvas area full
    var viewport = new glf.ViewportCamera.defaultSettings(gl.canvas);
    viewport.camera.position.setValues(0.0, 0.0, 6.0);

    cameraRunner.register(new glf.RequestRunOn()
      ..setup= (gl) {
        if (true) {
          // opaque
          gl.disable(wgl.BLEND);
          gl.depthFunc(wgl.LEQUAL);
          //gl.depthFunc(wgl.LESS); // default value
          gl.enable(wgl.DEPTH_TEST);
//        } else {
//          // blend
//          gl.disable(wgl.DEPTH_TEST);
//          gl.blendFunc(wgl.SRC_ALPHA, wgl.ONE);
//          gl.enable(wgl.BLEND);
        }
        gl.colorMask(true, true, true, true);
      }
      ..beforeAll = (gl) {
        gl.viewport(viewport.x, viewport.y, viewport.viewWidth, viewport.viewHeight);
        //gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clearColor(1.0, 0.0, 0.0, 1.0);
        //gl.clearColor(1.0, 1.0, 1.0, 1.0);
        gl.clear(wgl.COLOR_BUFFER_BIT | wgl.DEPTH_BUFFER_BIT);
        //gl.clear(wgl.COLOR_BUFFER_BIT);
      }
//      ..onRemoveProgramCtx = (prunner, ctx) {
//        ctx.delete();
//      }
    );


    cameraRunner.register(viewport.makeRequestRunOn());
  }

  _initLight() {
    var _light = new glf.Viewport()
      ..viewWidth = 1024
      ..viewHeight = 1024
      ..sfname_projectionmatrix = "lightProj"
      ..sfname_viewmatrix = "lightView"
      ..sfname_rotmatrix = "lightRot"
      ..sfname_projectionviewmatrix = "lightProjView"
      ..camera.fovRadians = degrees2radians * 70.0
      ..camera.aspectRatio = 1.0
      ..camera.position.setValues(0.0, 0.0, 100.0)
      ..camera.focusPosition.setValues(50.0, 50.0, 0.0)
      ;
    _light.camera.far = (_light.camera.focusPosition - _light.camera.position).length * 3.0;
    _light.camera.near = 90.0;//math.max(0.5, (_light.camera.focusPosition - _light.camera.position).length - 3.0);
    //_light.camera.updateProjectionViewMatrix();

    lightRunner.enableFrameBuffer(_light.viewWidth, _light.viewHeight);
    lightCtx = new glf.ProgramContext(gl, lightVert, lightFrag);
    lightRunner.register(_light.makeRequestRunOn()
      ..ctx = lightCtx
      ..beforeAll = (gl) {
        gl.viewport(0, 0, _light.viewWidth, _light.viewHeight);
        gl.clearColor(1.0, 1.0, 1.0, 1.0);
        gl.clear(wgl.COLOR_BUFFER_BIT | wgl.DEPTH_BUFFER_BIT);
      }
      ..before =(ctx) {
        ctx.gl.uniform1f(ctx.getUniformLocation('lightFar'), _light.camera.far);
        ctx.gl.uniform1f(ctx.getUniformLocation('lightNear'), _light.camera.near);
      }
    );

    cameraRunner.register(new glf.RequestRunOn()
      ..autoData = (new Map()
        ..addAll(_light.autoData)
        ..["sLightDepth"] = ((ctx) => glf.injectTexture(ctx, lightRunner.frameTexture, 31, "sLightDepth"))
        ..["lightFar"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightFar'), _light.camera.far))
        ..["lightNear"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightNear'), _light.camera.near))
        ..["lightConeAngle"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightConeAngle'), _light.camera.fovRadians * radians2degrees))
      )
    );
  }

  _initPost() {
    var md = glf.makeMeshDef_plane()
        ..normals = null
        ;
    var mesh = new glf.Mesh()..setData(gl, md);
    postRunner.register(new glf.RequestRunOn()
    ..ctx = new glf.ProgramContext(gl, texVert, texFrag)
    ..beforeAll =(ctx) {
      gl.viewport(10, 0, 256, 256);
      //gl.clearColor(1.0, 1.0, 1.0, 1.0);
      //gl.clear(wgl.COLOR_BUFFER_BIT | wgl.DEPTH_BUFFER_BIT);
    }
    ..at =(ctx){
      if (lightRunner.fbo.texture != null) {
        glf.injectTexture(ctx, lightRunner.fbo.texture, 0);
        mesh.injectAndDraw(ctx);
      }
    }
    );
  }
  run() {
    lightRunner.run();
    cameraRunner.run();
    postRunner.run();
  }

  var lightVert = """
      attribute vec3 _Vertex;

      uniform mat4 _ModelMatrix;

      varying vec4 vVertex;

      uniform mat4 lightProj, lightView;

      void main(){
      vVertex = _ModelMatrix * vec4(_Vertex, 1.0);
      gl_Position = lightProj * lightView * vVertex;
      }
      """;
  var lightFrag = """
      #ifdef GL_ES
      precision mediump float;
      #endif
      //#define SHADOW_VSM 1

      varying vec4 vVertex;

      uniform mat4 lightProj, lightView;
      uniform float lightFar, lightNear;

/// Pack a floating point value into an RGBA (32bpp).
/// Used by SSM, PCF, and ESM.
///
/// Note that video cards apply some sort of bias (error?) to pixels,
/// so we must correct for that by subtracting the next component's
/// value from the previous component.
/// @see http://devmaster.net/posts/3002/shader-effects-shadow-mapping#sthash.l86Qm4bE.dpuf
      vec4 pack (float depth) {
      const vec4 bias = vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
      float r = depth;
      float g = fract(r * 255.0);
      float b = fract(g * 255.0);
      float a = fract(b * 255.0);
      vec4 colour = vec4(r, g, b, a);
      return colour - (colour.yzww * bias);
      }


/// Unpack an RGBA pixel to floating point value.
      float unpack (vec4 colour) {
      const vec4 bitShifts = vec4(1.0, 1.0 / 255.0, 1.0 / (255.0 * 255.0), 1.0 / (255.0 * 255.0 * 255.0));
      return dot(colour, bitShifts);
      }

/// Pack a floating point value into a vec2 (16bpp).
/// Used by VSM.
      vec2 packHalf (float depth) {
      const vec2 bias = vec2(1.0 / 255.0, 0.0);
      vec2 colour = vec2(depth, fract(depth * 255.0));
      return colour - (colour.yy * bias);
      }

/// Unpack a vec2 to a floating point (used by VSM).
      float unpackHalf (vec2 colour) {
      return colour.x + (colour.y / 255.0);
      }

      float depthOf(vec3 lPosition) {
      //float depth = lPosition.z / lightFar;
      float depth = (length(lPosition) - lightNear)/(lightFar - lightNear);
      return clamp(depth, 0.0, 1.0);
      }


      void main(){
      vec3 lPosition = (lightView * vVertex).xyz;
      float depth = depthOf(lPosition);
      #ifdef SHADOW_VSM
      float moment2 = depth * depth;
      gl_FragColor = vec4(packHalf(depth), packHalf(moment2));
      #else
      gl_FragColor =  pack(depth);
      #endif
      }
      """;


  var texVert = """
      attribute vec3 _Vertex;
      attribute vec2 _TexCoord0;
      varying vec2 vTexCoord0;
      void main() {
      vTexCoord0 = _TexCoord0.xy;
      gl_Position = vec4(vTexCoord0 * 2.0 - 1.0, 0.0, 1.0);
      }""";
  var texFrag = """
      #ifdef GL_ES
      precision mediump float;
      #endif

      uniform sampler2D _Tex0;
      varying vec2 vTexCoord0;
      void main() {
      //gl_FragColor = vec4(vTexCoord0, 0.0, 1.0);
      gl_FragColor = texture2D(_Tex0, vTexCoord0);
      //gl_FragColor = vec4(1.0);
      }
      """;
}
*/