part of vdrones;

class Factory_Renderables {
  static const _devMode = false;
  static const TEX_DIFFUSE = 1;
  static const TEX_DISSOLVEMAP = 3;
  RenderableDef _newRenderableDef(f) => new RenderableDef()..onInsert = ((gl, e) => null);
  final glf.TextureUnitCache _textures;

  Factory_Renderables(this._textures);

  RenderableDef newCube(glf.ProgramContext ctx){
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var rad = ps.radius[0];
      var transform = new Matrix4.identity();
      return new Renderable()
      ..obj = (new r.ObjectInfo()
        ..uniforms = 'uniform mat4 cubeTx0;'
        ..de = "sd_box(opTx(p,cubeTx0), vec3($rad, $rad, $rad))"
        ..sh = """return shadeNormal(o, p);"""
        ..at = (ctx) {
          glf.injectMatrix4(ctx, transform, "cubeTx0");
          transform.setIdentity();
          transform.setTranslation(-ps.position3d[0]);
        }
      )
//      ..ext['transform'] = transform
      ;
    }
    ;
  }

  RenderableDef newFloor() {
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      return new Renderable()
      ..obj = (new r.ObjectInfo()
        ..de = "sd_flatFloor(p)"
        ..sd = r.sd_flatFloor(0.0)
        ..mat = r.mat_chessboardXY0(1.0, new Vector4(0.9,0.0,0.5,1.0), new Vector4(0.2,0.2,0.8,1.0))
        ..sh = """return shade0(mat_chessboardXY0(p), getNormal(o, p), o, p);"""
      )
      ;
    }
    ;
  }

  var _mwCnt = 0;
  RenderableDef newMobileWall(Iterable<Polygone> shapes, num dz, Vector4 color) {
    _mwCnt++;
    var utx = 'mwTx${_mwCnt}';
          // TODO optimize to reduce number of copy (position3d => Float32List => buffer)
          //updateVertices();
          //_mdt.extrudeInto(vertices, extrusion, geometry.meshDef);
          //geometry.verticesNeedUpdate = true;
//          var vp0 = ps.position3d[1];
//          var vm = geometry.meshDef.vertices;
//          geometry..transforms.setTranslationRaw(vp0.x - vm[0], vp0.y - vm[1], vp0.z - vm[2]);
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var transform = new Matrix4.identity();
      var obj = new r.ObjectInfo()
        ..uniforms = 'uniform mat4 ${utx};'
        ..de = "sd_box(opTx(p, ${utx}), vec3(1.0, 3.0, $dz))"
        ..sh = """return shade0(vec4(${color.r}, ${color.g}, ${color.b}, ${color.a}), getNormal(o, p), o, p);"""
        ..at = (ctx) {
            glf.injectMatrix4(ctx, transform, utx);
            transform.setIdentity();
            //transform.setTranslation(-ps.position3d[0]);
            //print("$shapes, $dz');
        }
      ;
      return new Renderable()..obj = obj;
    }
    ;
  }
  ud_seg() {
    return '''
      float distance2(vec2 v, vec2 w) {
        float x = w.x - v.x;
        float y = w.y - v.y;
        return x * x + y * y;
      }
      float ud_segXY(vec2 p, vec2 v, vec2 w) {
        float l = distance2(v, w);
        if (l < 0.001) return distance2(p, v);
        float t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l;
        if (t < 0.0) return distance2(p, v);
        if (t > 1.0) return distance2(p, w);
        return distance2(p, vec2(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)));
      }
      
      float ud_seg(vec3 p, vec2 v, vec2 w, float dz) {
        return ud_segXY(p.xy, v, w);
      }
    ''';
  }

  var _pezCnt = 0;
  RenderableDef newPolygonesExtrudesZ(Iterable<Polygone> shapes, num dz, glf.ProgramContext ctx, Vector4 color, {isMobile : false, includeFloor : false}) {
    _pezCnt++;
    var utx = 'pezTx${_pezCnt}';
    var ud = 'ud_pez${_pezCnt}';
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      //var ps = entity.getComponent(Particles.CT) as Particles;
      //QUESTION use shapes or Segment from entity ??
      var transform = new Matrix4.identity();
      var ud_merge = '';
      shapes.forEach((shape){
        for(var i=0; i < shape.points.length; i++) {
          var p0 = shape.points[i];
          var p1 = shape.points[(i + 1) % shape.points.length];
          ud_merge += 'd = min(d, ud_segXY(pxy, vec2(${p0.x}, ${p0.y}), vec2(${p1.x}, ${p1.y})));\n';
        }
      });
      ud_merge = '''
        float ${ud}(vec3 p){
          vec2 pxy = p.xy;
          float d = ${glf.SFNAME_FAR} * ${glf.SFNAME_FAR};
          ${ud_merge}
          float z = max(0.0, (p.z - $dz));
          return sqrt(d + z * z);
        }''';
      var obj = new r.ObjectInfo()
        ..uniforms = 'uniform mat4 ${utx};'
        ..sds = [ud_seg(), ud_merge]
        ..de = "${ud}(p)"
        ..sh = """return shade0(vec4(${color.r}, ${color.g}, ${color.b}, ${color.a}), getNormal(o, p), o, p);"""
        ..at = (ctx) {
            glf.injectMatrix4(ctx, transform, utx);
            transform.setIdentity();
            //transform.setTranslation(-ps.position3d[0]);
            //print("$shapes, $dz');
        }
      ;
      return new Renderable()..obj = obj;
    }
    ;
  }
//  RenderableDef newPolygonesExtrudesZ(Iterable<Polygone> shapes, num dz, glf.ProgramContext ctx, Vector4 color, {isMobile : false, includeFloor : false}) {
//    return new RenderableDef()
//    ..onInsert = (gl, Entity entity) {
//      var extrusion = new Vector3(0.0, 0.0, dz);
//      shapeToMeshDef(shape) {
//        var points = shape.points.toList();
//        var vertices = new Float32List(points.length * 3);
//        for(var i = 0; i < points.length; i++) {
//          var v = points[i];
//          vertices[i * 3 + 0] = v.x;
//          vertices[i * 3 + 1] = v.y;
//          vertices[i * 3 + 2] = v.z;
//        }
//        return _mdt.makeExtrude(vertices, extrusion);
//      }
//      var mdAll = shapes.fold(null, (acc, x){
//        var md = shapeToMeshDef(x);
//        return (acc == null) ? md : _mdt.merge(acc, md);
//      });
//      if (includeFloor) {
//        var tmp = new Aabb3();
//        var aabb = shapes.fold(null, (acc, x){
//          var t0 = Math2.extractAabbPoly(x.points.toList(), tmp);
//          return (acc == null) ? new Aabb3.copy(t0) : acc..hull(t0);
//        });
//        var center = new Vector3.zero();
//        var halfExtents = new Vector3.zero();
//        aabb.copyCenterAndHalfExtents(center, halfExtents);
//        var floor = _mdt.makePlane(dx: halfExtents.x, dy: halfExtents.y);
//        //HACK until makeExtrude set TexCoords
//        floor.texCoords = null;
//        var tfs = new Matrix4.identity();
//        tfs.setTranslationRaw(center.x, center.y, 0.0);
//        _mdt.transform(floor, tfs);
//        _mdt.merge(mdAll, floor);
//      }
//      var geometry = new Geometry()
//      ..meshDef = mdAll
//      ..transforms.setIdentity()
//      ;
//
//      //mw_setPositions(geometry.meshDef, ps.position3d[1], ps.position3d[2], ps.position3d[3], ps.position3d[4], dz);
//      //mw_setPositions(geometry.meshDef, new Vector3(-dx, -dy, 0.0), new Vector3(-dx, dy, 0.0), new Vector3(dx, dy, 0.0), new Vector3(dx, -dy, 0.0), dz);
//      var out = new Renderable()
//      ..geometry = geometry
//      ..material = (new Material()
//        ..ctx = ctx
//        ..transparent = true
//        ..cfg = (ctx) {
//          ctx.gl.uniform1f(ctx.getUniformLocation('_DissolveRatio'), 0.0);
//          ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), color.r, color.g, color.b, color.a);
//        }
//      )
//      ;
//      if (isMobile) {
//        var ps = entity.getComponent(Particles.CT) as Particles;
//        out.prepare = (new glf.RequestRunOn()
//          ..beforeAll = (gl) {
//            // TODO optimize to reduce number of copy (position3d => Float32List => buffer)
//            //updateVertices();
//            //_mdt.extrudeInto(vertices, extrusion, geometry.meshDef);
//            //geometry.verticesNeedUpdate = true;
//            var vp0 = ps.position3d[0];
//            var vm = geometry.meshDef.vertices;
//            geometry..transforms.setTranslationRaw(vp0.x - vm[0], vp0.y - vm[1], vp0.z - vm[2]);
//          }
//        );
//      }
//      return out;
//    };
//  }

  Iterable<Component> newCamera(Aabb3 focusAabb){
    var c = new CameraFollower()
    ..focusAabb = focusAabb
    ..mode = CameraFollower.TPS
    ;

    var r = new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var camera = new glf.CameraInfo()
      ..fovRadians = degrees2radians * 45.0
      ..near = 1.0
      ..far = 100.0
//      ..left = vp.x.toDouble()
//      ..right = vp.x.toDouble() + vp.viewWidth.toDouble()
//      ..top = vp.y.toDouble()
//      ..bottom = vp.y.toDouble() + vp.viewHeight.toDouble()
      ..isOrthographic = false
//      ..aspectRatio = vp.viewWidth.toDouble() / vp.viewHeight.toDouble()
      ..position.setValues(0.0, 0.0, 1000.0)
      ..focusPosition.setValues(1.0, 1.0, 0.0)
      ..adjustNearFar(focusAabb, 0.1, 0.1)
//      ..updateProjectionMatrix()
      ;
      c.info = camera;
      return new Renderable()
      ..camera = camera
      ;
    };
    return [r, c];
  }

  RenderableDef newDrone(glf.ProgramContext ctx, WebGL.Texture dissolveMap){
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var obj = new r.ObjectInfo()
      ..uniforms = """
      uniform vec3 drone1, drone2, drone3, drone4;
      """
      ..de = "sd_drone(p, drone1, drone2, drone3, drone4)"
      ..sd = """
      float thalfspace(vec3 p, vec3 a1, vec3 a2, vec3 a3) {
        vec3 c = vec3(a1);
        c = c + (a2 - c) * 0.5;
        c = c + (a3 - c) * 0.5;
        
        //vec3 c = (a1 + a2 + a3) * TIER;
        vec3 n = -normalize(cross(a2 - a1, a3 - a1));
        float b = length(a1 - c);
        return max(0.0, dot(p-a1, n));
      }
        
      float sd_drone(vec3 p, vec3 a1, vec3 a2, vec3 a3, vec3 a4){
        float d = 0.0;
        d = max(thalfspace(p, a1, a3, a2),d);
        d = max(thalfspace(p, a1, a2, a4),d);
        d = max(thalfspace(p, a4, a2, a3),d);
        d = max(thalfspace(p, a1, a4, a3),d);
        return d;
      }
      """
      ..sh = """return shadeUniformBasic(vec4(0.5, 0.0, 0.0, 1.0), o, p);"""
      ..at = (ctx){
        ctx.gl.uniform3fv(ctx.getUniformLocation("drone1"), ps.position3d[DRONE_PCENTER].storage);
        ctx.gl.uniform3fv(ctx.getUniformLocation("drone2"), ps.position3d[DRONE_PBACKL].storage);
        ctx.gl.uniform3fv(ctx.getUniformLocation("drone3"), ps.position3d[DRONE_PBACKR].storage);
        ctx.gl.uniform3fv(ctx.getUniformLocation("drone4"), ps.position3d[DRONE_PFRONT].storage);
        //print(ps.position3d);
      }
      ;


      return new Renderable()
      ..obj = obj
      ;
    };
  }

}
