part of vdrones;

class Factory_Renderables {
  static const _devMode = false;
  static const TEX_DIFFUSE = 1;
  static const TEX_DISSOLVEMAP = 3;
  RenderableDef _newRenderableDef(f) => new RenderableDef()..onInsert = ((gl, e) => null);
  static final _mdt = new glf.MeshDefTools();

  RenderableDef newCube(glf.ProgramContext ctx){
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var r = ps.radius[0];
      var geometry = new Geometry()
      ..meshDef = _mdt.makeBox24Vertices(dx: r, dy: r, dz: r)
      ..transforms.translate(ps.position3d[0])
      ;
      return new Renderable()
      ..geometry = geometry
      ..material = (new Material()
        ..ctx = ctx
        ..cfg = (ctx){
          ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.0, 0.8, 0.0);
        }
      )
      ..prepare = (new glf.RequestRunOn()
        ..beforeAll = (gl) {
          geometry.transforms.setTranslation(ps.position3d[0]);
          geometry.normalMatrixNeedUpdate = true;
        }
      )
      ;
    }
    ;
  }

  RenderableDef newMobileWall(num dx, num dy, num dz, glf.ProgramContext ctx) {
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var extrusion = new Vector3(0.0, 0.0, dz);
      var vertices = new Float32List(4 * 3);
      updateVertices() {
        for(var i = 0; i < 4; i++) {
          var v = ps.position3d[i + 1];
          vertices[i * 3 + 0] = v.x;
          vertices[i * 3 + 1] = v.y;
          vertices[i * 3 + 2] = v.z;
        }
      }
      updateVertices();
      var geometry = new Geometry()
      ..meshDef = _mdt.makeExtrude(vertices, extrusion)
      ..transforms.setIdentity()
      ;

      //mw_setPositions(geometry.meshDef, ps.position3d[1], ps.position3d[2], ps.position3d[3], ps.position3d[4], dz);
      //mw_setPositions(geometry.meshDef, new Vector3(-dx, -dy, 0.0), new Vector3(-dx, dy, 0.0), new Vector3(dx, dy, 0.0), new Vector3(dx, -dy, 0.0), dz);
      return new Renderable()
      ..geometry = geometry
      ..material = (new Material()
        ..ctx = ctx
        ..transparent = true
        ..cfg = (ctx) {
          ctx.gl.uniform1f(ctx.getUniformLocation('_DissolveRatio'), 0.0);
          ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.8, 0.1, 0.1, 0.7);
        }
      )
      ..prepare = (new glf.RequestRunOn()
        ..beforeAll = (gl) {
          // TODO optimize to reduce number of copy (position3d => Float32List => buffer)
          //updateVertices();
          //_mdt.extrudeInto(vertices, extrusion, geometry.meshDef);
          //geometry.verticesNeedUpdate = true;
          var vp0 = ps.position3d[1];
          var vm = geometry.meshDef.vertices;
          geometry..transforms.setTranslationRaw(vp0.x - vm[0], vp0.y - vm[1], vp0.z - vm[2]);
        }
      );
    };
  }

  /// default length of axis is 100
  RenderableDef newAxis(num scale) => _newRenderableDef((){
//    final THREE = (js.context as dynamic).THREE;
//    var o = new js.Proxy(THREE.AxisHelper) as dynamic;
//    o.scale.setValues(scale, scale, scale);
//    return js.retain(o);
  });

  RenderableDef newSurface3d(List<num> rects, num offz, glf.ProgramContext ctx, [WebGL.Texture img]){
    var mdAll = null;
    var tfs = new Matrix4.identity();
    for(var i = 0; i < rects.length; i+=4) {
      var dx = rects[i+2];
      var dy = rects[i+3];
      //var md = glf.makeMeshDef_cube8Vertices(dx: 1.0, dy: 1.0, dz: 0.5);
      var md = _mdt.makePlane(dx: dx * 2, dy: dy * 2);
      //TODO optim remove the ground face (never used/seen)
      tfs.setIdentity();
      tfs.translate(rects[i+0], rects[i+1], offz);
      _mdt.transform(md, tfs);
      mdAll = (mdAll == null) ? md : _mdt.merge(mdAll, md);
    }
//      mesh.castShadow = false;
//      mesh.receiveShadow = true;
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      return new Renderable()
      ..geometry = (new Geometry()
        ..meshDef = mdAll
      )
      ..material = (new Material()
        ..ctx = ctx
        ..transparent = true
        ..pre = false //no shadow, no SSAO
        ..cfg = (ctx) {
//        "map" : texture,
//        //"blending" : THREE.AdditiveBlending,
//        //"color": 0xffffff,
//        "transparent": true
        ctx.gl.uniform1f(ctx.getUniformLocation('_DissolveRatio'), 0.0);
        ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.8, 0.8, 0.8, 1.0);
          glf.injectTexture(ctx, img);
        }
      )
      ;
    };
  }

  RenderableDef newBoxes3d(List<num> rects, double dz, num width, num height, glf.ProgramContext ctx) {
    var mdAll = null;
    var tfs = new Matrix4.identity();
    tfs.setIdentity();
    for(var i = 0; i < rects.length; i+=4) {
      var dx = rects[i+2];
      var dy = rects[i+3];
      //var md = glf.makeMeshDef_cube8Vertices(dx: 1.0, dy: 1.0, dz: 0.5);
      var md = _mdt.makeBox24Vertices(dx: dx, dy: dy, dz: dz);
      //TODO optim remove the ground face (never used/seen)
      var iscw = _mdt.isClockwise(md.vertices, md.normals, md.triangles);
      tfs.setTranslationRaw(rects[i+0], rects[i+1], dz);
      _mdt.transform(md, tfs);
      mdAll = (mdAll == null) ? md : _mdt.merge(mdAll, md);
    }
    var floor = _mdt.makePlane(dx: width * 0.5, dy: height * 0.5);
    tfs.setTranslationRaw(width * 0.5, height * 0.5, 0.0);
    _mdt.transform(floor, tfs);
    _mdt.merge(mdAll, floor);
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      return new Renderable()
      ..geometry = (new Geometry()
        ..meshDef = mdAll
      )
      ..material = (new Material()
        ..ctx = ctx
        ..transparent = false
        ..cfg = (ctx) {
          ctx.gl.uniform1f(ctx.getUniformLocation('_DissolveRatio'), 0.0);
          ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.9, 0.9, 0.95, 1.0);
        }
      )
      ;
    };
  }

  Iterable<Component> newCamera(Aabb3 focusAabb){
    var c = new CameraFollower()
    ..focusAabb = focusAabb
    ..mode = CameraFollower.TPS
    ;

    var r = new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var vp = new glf.ViewportCamera.defaultSettings(gl.canvas)
      ..camera.position.setValues(0.0, 0.0, 1000.0)
      ..camera.focusPosition.setValues(1.0, 1.0, 0.0)
      ..camera.adjustNearFar(focusAabb, 0.1, 0.1)
      ;
      c.info = vp.camera;
      return new Renderable()
      ..viewportCamera = vp
      ;
    };
    return [r, c];
  }

  RenderableDef newDrone(glf.ProgramContext ctx, WebGL.Texture dissolveMap){
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var geometry = new Geometry()
      ..mesh.triangles.setData(gl, new Uint16List.fromList([
        DRONE_PFRONT, DRONE_PBACKR,  DRONE_PBACKL,
        DRONE_PCENTER, DRONE_PBACKL,  DRONE_PBACKR,
        DRONE_PCENTER, DRONE_PBACKR,  DRONE_PFRONT,
        DRONE_PCENTER, DRONE_PFRONT,  DRONE_PBACKL
      ]));
      var pos = new Float32List(ps.length * 3);
      geometry.mesh.vertices.setData(ctx.gl, pos);
      var uv = new Float32List(ps.length * 2);
      uv[DRONE_PFRONT * 2 + 0] = 0.5;
      uv[DRONE_PFRONT * 2 + 1] = 0.0;
      uv[DRONE_PCENTER * 2 + 0] = 0.5;
      uv[DRONE_PCENTER * 2 + 1] = 0.75;
      uv[DRONE_PBACKR * 2 + 0] = 1.0;
      uv[DRONE_PBACKR * 2 + 1] = 1.0;
      uv[DRONE_PBACKL * 2 + 0] = 0.0;
      uv[DRONE_PBACKL * 2 + 1] = 1.0;
      geometry.mesh.texCoords.setData(ctx.gl, uv);

      return new Renderable()
      ..geometry = geometry
      ..material = (new Material()
        ..ctx = ctx
        ..cfg = (ctx) {
          var dis = entity.getComponent(Dissolvable.CT) as Dissolvable;
          if (dis != null){
            ctx.gl.uniform1f(ctx.getUniformLocation('_DissolveRatio'), dis.ratio);
            glf.injectTexture(ctx, dissolveMap, TEX_DISSOLVEMAP, '_DissolveMap0');
          } else {
            ctx.gl.uniform1f(ctx.getUniformLocation('_DissolveRatio'), 0.0);
          }
          ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.2, 0.1, 0.5, 1.0);

        }
      )
      ..prepare = (new glf.RequestRunOn()
        ..beforeAll = (gl) {
          // vertices of the mesh can be modified in update loop, so update the data to GPU
          //geometry.transforms.translate(ps.position3d[DRONE_PCENTER]);
          geometry.transforms.setIdentity();
          for(var i = 0; i < ps.length; ++i) {
            var v = ps.position3d[i];
            pos[i*3] = v.storage[0];
            pos[i*3 + 1] = v.storage[1];
            pos[i*3 + 2] = v.storage[2];
          }
          geometry.mesh.vertices.setData(ctx.gl, pos);
        }
      )
      ;
    };
  }

  RenderableDef newAmbientLight(color) => _newRenderableDef((){
//    final THREE = (js.context as dynamic).THREE;
//    return js.retain(new js.Proxy(THREE.AmbientLight, color));
  });

  RenderableDef newLight() => _newRenderableDef((){
//    final THREE = (js.context as dynamic).THREE;
//    //var light = new js.Proxy.withArgList(THREE.DirectionalLight,  [0xffffff, 1, 0] );
//    var light = new js.Proxy.withArgList(THREE.SpotLight,  [0xffffff, 1.0, 0.0, math.PI, 1] ) as dynamic;
//
//    light.castShadow = true;
//
//    light.shadowCameraNear = 5;
//    light.shadowCameraFar = 200;
//    light.shadowCameraFov = 110;
//
//    light.shadowCameraVisible = _devMode;
//
//    light.shadowBias = 0.00001;
//    light.shadowDarkness = 0.5;
//
//    light.shadowMapWidth = 2048;
//    light.shadowMapHeight = 2048;
//    return js.retain(light);
  });

  RenderableDef newParticlesDebug(Particles ps, texturePath) => _newRenderableDef((){
//    final THREE = (js.context as dynamic).THREE;
//    var attributes = js.map({
//      "size": js.map({ "type": 'f', "value": new List(ps.length) }),
//      "ca":   js.map({ "type": 'c', "value": new List(ps.length) })
//    });
//
//    var uniforms = js.map({
//      "amplitude": js.map({ "type": "f", "value": 1.0 }),
//      "color":     js.map({ "type": "c", "value": new js.Proxy(THREE.Color, 0xffffff ) }),
//      "texture":   js.map({ "type": "t", "value": 0, "texture": THREE.ImageUtils.loadTexture(texturePath) })
//    });
//    var glsl_vs1 = """
//      attribute float size;
//      attribute vec3 ca;
//
//      varying vec3 vColor;
//
//      void main() {
//
//        vColor = ca;
//
//        vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );
//
//        //gl_PointSize = size;
//        gl_PointSize = size * ( 300.0 / length( mvPosition.xyz ) );
//
//        gl_Position = projectionMatrix * mvPosition;
//
//      }
//    """;
//    var glsl_fs1 = """
//      uniform vec3 color;
//      uniform sampler2D texture;
//
//      varying vec3 vColor;
//
//      void main() {
//
//        gl_FragColor = vec4( color * vColor, 1.0 );
//        gl_FragColor = gl_FragColor * texture2D( texture, gl_PointCoord );
//
//      }
//    """;
//    //uniforms.texture.texture.wrapS = uniforms.texture.texture.wrapT = THREE.RepeatWrapping;
//
//    var material = new js.Proxy(THREE.ShaderMaterial, js.map({
//      "uniforms":     uniforms,
//      "attributes":     attributes,
//      "vertexShader":   glsl_vs1,
//      "fragmentShader": glsl_fs1
//    }));
//    var geometry = new js.Proxy(THREE.Geometry) as dynamic;
//    var verts = new List(ps.length);
//    var sizes = attributes.size.value;
//    var colors = attributes.ca.value;
//    for (var i = 0; i < ps.length; ++i) {
//      verts[i] = new js.Proxy(THREE.Vector3, 0,0,0);
//      sizes[i] = 10.0 * ps.radius[i];
//      colors[i] = new js.Proxy(THREE.Color, ps.color[i] >> 2 ); //rgba => rgb
//    }
//    geometry.vertices = js.array(verts);
//    //_reset(attributes);
//    var obj3d = js.retain(new js.Proxy(THREE.ParticleSystem, geometry, material));
//    return obj3d;
//  })..sync = (Entity entity, obj3d) {
//    var ps0 = entity.getComponent(Particles.CT);
//    //print("sync : ${ps0.length} ... ${ps0.position3d[0].x}");
//    var vertices = obj3d.geometry.vertices;
//    for(var i = 0; i < ps0.length; ++i){
//      var src = ps0.position3d[i];
//      var dest = vertices[i];
//      dest.x = src.x;
//      dest.y = src.y;
//      dest.z = src.z;
//    }
//    obj3d.geometry.verticesNeedUpdate = true;
//    //window.console.log(vertices[0].x);
    });
//
//  //static var _explode = newExplode(100);
//  static var _explode = new Explode(100).particles;
//  static RenderableDef newExplode() {
//    return new RenderableDef(() => _explode);
//  }
}

//// based on http://webglplayground.net/?gallery=BeIrChLZoJ
//class Explode {
//  var particles;
//
//  final random = new math.Random();
//
//  var glsl_vs1 = """
//    //uniform vec3 center;
//    uniform float time;
//    attribute vec3 aPosition;
//    attribute vec3 aVelocity;
//    attribute vec3 aDirection;
//    attribute float aAcceleration;
//    attribute float aLifeTime;
//    varying vec4 vColor;
//
//    void main()
//    {
//      float t = time;
//      vec3 direction = normalize(aDirection);
//      vec3 velocity = 30.0*normalize(aVelocity);
//      //below two different variations of explosions
//      //vec3 velocity = 30.0*(aLifeTime/4.1*length(aVelocity))*normalize(aVelocity);
//      //vec3 velocity = 30.0*(abs(3.0*sin(t/20.0))*aLifeTime/4.1*length(aVelocity))*normalize(aVelocity);
//      float acceleration = 20.0*aAcceleration;
//      //vec3 p = center + aPosition + velocity*t + direction*(acceleration*t*t*0.5);
//      vec3 p = aPosition + velocity*t + direction*(acceleration*t*t*0.5);
//      gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
//      float lifeLeft = 1.0-smoothstep(0.0, aLifeTime, t);
//      float ta = t/aAcceleration;
//      gl_PointSize = min(12.0, t/aAcceleration);
//      vColor = vec4(1.0, pow(1.0-aAcceleration, 6.0), pow((1.0-aAcceleration), 14.0)-0.3, lifeLeft/(2.0*gl_PointSize));
//    }
//  """;
//  var glsl_fs1 = """
//    #ifdef GL_ES
//    precision highp float;
//    #endif
//
//    uniform float time;
//    varying vec4 vColor;
//    void main()
//    {
//      gl_FragColor = vColor;
//    }
//  """;
//  //http://mathworld.wolfram.com/SpherePointPicking.html
//  List<num> randomPointOnSphere() {
//    var x1 = (random.nextDouble()-0.5)*2.0;
//    var x2 = (random.nextDouble()-0.5)*2.0;
//    var ds = x1*x1+x2*x2;
//    while (ds>=1) {
//      x1 = (random.nextDouble()-0.5)*2.0;
//      x2 = (random.nextDouble()-0.5)*2.0;
//      ds = x1*x1+x2*x2;
//    }
//    var ds2 = math.sqrt(1.0-x1*x1-x2*x2);
//    var point = [
//      2.0*x1*ds2,
//      2.0*x2*ds2,
//      1.0-2.0*ds
//    ];
//    return point;
//  }
//
//  var uniforms;
//
//  static dynamic a(String s, int l) {
//    return js.map({
//      'type' : s,
//      'value' : new List(l)
//    });
//  }
//
//  num nParticles;
//
//  Explode(this.nParticles) {
//    js.scoped((){
//    final THREE = (js.context as dynamic).THREE;
//    uniforms = js.retain(js.map({
//      "time": { "type" :"f", "value" : 0}
////      "center": { "type" : "v3", "value" : new js.Proxy(THREE.Vector3, 0, 0, 1.0)}
//    }));
//
//    var attributes = js.map({
//      "aPosition": a("v3", nParticles),
//      "aVelocity": a("v3", nParticles),
//      "aDirection": a("v3", nParticles),
//      "aAcceleration": a("f", nParticles),
//      "aLifeTime": a("f", nParticles)
//    });
//    var material = new js.Proxy(THREE.ShaderMaterial, js.map({
//      "uniforms": uniforms,
//      "attributes": attributes,
//      "vertexShader": glsl_vs1,
//      "fragmentShader": glsl_fs1,
//      "blending": THREE.AdditiveBlending,
//      "transparent": false
//      //"depthTest": false
//    }));
//
//    var geometry = new js.Proxy(THREE.Geometry) as dynamic;
//    var verts = new List(nParticles);
//    for (var i=0; i<nParticles; i++) {
//      verts[i] = new js.Proxy(THREE.Vector3, 0,0,0);
//    }
//    geometry.vertices = js.array(verts);
//    _reset(attributes);
//    particles = js.retain(new js.Proxy(THREE.ParticleSystem, geometry, material));
//    });
//  }
//
//  void _reset(attributes) {
//    final THREE = (js.context as dynamic).THREE;
//    for (var i=0; i<nParticles; i++) {
//      // position
//      var point = randomPointOnSphere();
//      attributes["aPosition"].value[i] = new js.Proxy(THREE.Vector3,
//                                                        point[0],
//                                                        point[1],
//                                                        point[2]);
//
//      // velocity
//      point = randomPointOnSphere();
//      attributes["aVelocity"].value[i] = new js.Proxy(THREE.Vector3,
//                                                        point[0],
//                                                        point[1],
//                                                        point[2]);
//
//      // direction
//      point = randomPointOnSphere();
//      attributes["aDirection"].value[i] = new js.Proxy(THREE.Vector3,
//                                                         point[0],
//                                                         point[1],
//                                                         point[2]);
//
//      // acceleration
//      attributes["aAcceleration"].value[i] = random.nextDouble();
//      attributes["aLifeTime"].value[i] = (6.0*(random.nextDouble()*0.3+0.3));
//    }
//  }
//}

