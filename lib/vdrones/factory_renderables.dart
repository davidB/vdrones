part of vdrones;

class Factory_Renderables {
  static const _devMode = false;
  RenderableDef _newRenderableDef(f) => new RenderableDef()..onInsert = ((gl, e) => null);
  final glf.TextureUnitCache _textures;
  var _uCnt = 0;


  Factory_Renderables(this._textures);

  reset() {
    print("[DEBUG] reset");
    _uCnt = 0;
  }

  _vec3(Vector3 v) => "vec3(${v.x}, ${v.y}, ${v.z})";
  _vec4(Vector4 v) => "vec4(${v.x}, ${v.y}, ${v.z}, ${v.w})";

  _defaultShadeMats(l) {
    r.n_de(l);
    r.normalToColor(l);
    r.aoToColor(l);
    r.shade1(l);
    r.shade0(l);
    r.shadeOutdoor(l);
    _myshade(l);
  }
  _myshade(l) {
    r.softshadow(l);
    r.ao_de(l);
    l.add('''
#define HIGH
  // see http://www.altdevblogaday.com/2011/08/23/shader-code-for-physically-based-lighting/
  const vec3 light_colour = vec3(1.0, 1.0, 1.0);
  const float specular_power = 1.0;
  const float specular_colour = 0.5;
  const float PI_OVER_FOUR = PI / 4.0;
  const float PI_OVER_TWO = PI / 2.0;

  color myshade(color c, vec3 p, vec3 n, float t, vec3 rd) {
    vec3 light_direction = normalize( lightSegment(p) );
    float n_dot_l = clamp( dot( n, light_direction ), 0.0, 1.0 ); 
    //vec3 diffuse = light_colour * n_dot_l;
    float diffuse = n_dot_l;
    //diffuse =  mix ( diffuse, 0, somethingAboutSpecularLobeLuminance );

    vec3 hv = normalize(light_direction - rd);
    float n_dot_h = clamp( dot( n, hv ), 0.0, 1.0 );
    //float normalisation_term = ( specular_power + 2.0 ) / 2.0 * PI;
    float normalisation_term = ( specular_power + 2.0 ) / 8.0;
    float blinn_phong = pow( n_dot_h, specular_power );
    float specular_term = normalisation_term * blinn_phong;
    float cosine_term = n_dot_l;
    //vec3 specular = (PI / 4.0f) * specular_term * cosine_term * fresnel_term * visibility_term * light_colour;
    float specularCoeff = specular_term * cosine_term;
#if defined(MID) || defined(HIGH) 
    float h_dot_l = dot(hv, light_direction); // Dot product of half vector and light vector. No need to saturate as it can't go above 90 degrees
    float base = 1.0 - h_dot_l;    
    float exponential = pow( base, 5.0 );
    float fresnel_term = specular_colour + ( 1.0 - specular_colour ) * exponential;
    specularCoeff = specularCoeff * fresnel_term;
#endif
#ifdef HIGH
    float n_dot_v = dot(n, -rd);
    float alpha = 1.0 / ( sqrt( PI_OVER_FOUR * specular_power + PI_OVER_TWO ) );
    float visibility_term = ( n_dot_l * ( 1.0 - alpha ) + alpha ) * ( n_dot_v * ( 1.0 - alpha ) + alpha ); // Both dot products should be saturated
    visibility_term = 1.0 / visibility_term;
    specularCoeff = specularCoeff * visibility_term;
#endif
    vec3 albedo = c.rgb;
    float ao = ao_de(p, n);
    float ambient = 0.5;
    diffuse = clamp(diffuse, ambient, 1.0);
    float sh = softshadow( p, light_direction, 0.02, 10.0, 7.0 );
    // sh = min(sh, ao);
    c.rgb = albedo * diffuse * sh + light_colour * specularCoeff;
    return c;
//
//    float ao = ao_de(p, n);
//
//    float amb = clamp( 0.5+0.5*n.z, 0.0, 1.0 );
//    float dif = clamp( dot( n, lig ), 0.0, 1.0 );
//    float bac = clamp( dot( n, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-p.y,0.0,1.0);
//
//    float sh = 1.0;
//    if( dif>0.02 ) { sh = softshadow( p, lig, 0.02, 10.0, 7.0 ); dif *= sh; }
//
//    vec3 brdf = vec3(0.0);
//    brdf += 0.20*amb*vec3(0.10,0.11,0.13)*ao;
//    brdf += 0.20*bac*vec3(0.15,0.15,0.15)*ao;
//    brdf += 1.20*dif*vec3(1.00,0.90,0.70);
//
//    float pp = clamp(dot(reflect(rd, n), lig), 0.0, 1.0 );
//    float spe = sh*pow(pp, 16.0);
//    float fre = ao*pow(clamp(1.0+dot(n, rd),0.0,1.0), 2.0 );
//
//    vec3 col = c.rgb;
//    col = col*brdf + col * vec3(1.0)*spe + 0.2*fre*(0.5+0.5*col);
//    col *= exp( -0.01*t*t );
//    c.rgb = col;
//    return c;
  }
    ''');
  }
  _defaultShade({String c : "normalToColor(n)", String n : "n_de(o, p)"}) {
    return """
        vec3 n = $n;
        vec3 nf = faceforward(n, rd, n);
        return myshade($c, p, nf, t, rd);
        //return shade1($c, p, nf, t, rd);
        //return shade0($c, p, nf);
        //return shadeOutdoor($c, p, nf);
        //return aoToColor(p, nf);
        //return normalToColor(nf);
        //return $c * ao_de(p, nf);
        """;
  }

  sd_merge(String fname, Iterable<String> sds, {String init : ""}) {
    var s = '''
    float ${fname}(vec3 p){
      float dfinal = ${glf.SFNAME_FAR} * ${glf.SFNAME_FAR};
      float d = dfinal;
      ${sds.fold(init, (acc, x)=> acc + x + '\ndfinal = min(d, dfinal);\n')}
      return dfinal;
    }
    ''';
    return (l) => l.add(s);
  }

  RenderableDef newCube(){
    _uCnt++;
    var ut = 'ut${_uCnt}';
    var uq = 'uq${_uCnt}';
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      var ps = entity.getComponent(Particles.CT) as Particles;
      var rad = ps.radius[0];
      var q = (entity.getComponent(Orientation.CT) as Orientation).q;
      return new Renderable()
      ..obj = (new r.ObjectInfo()
        ..uniforms = 'uniform vec3 ${ut}; uniform vec4 ${uq};'
        ..sds = [r.qrot, r.sd_box]
        ..de = "sd_box(qrot(${uq}, p - ${ut}), vec3($rad))"
        ..mats = [_defaultShadeMats]
        ..sh = _defaultShade()
        ..at = (ctx) {
          ctx.gl.uniform3fv(ctx.getUniformLocation(ut), ps.position3d[0].storage);
          ctx.gl.uniform4fv(ctx.getUniformLocation(uq), q.storage);
        }
      )
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
        ..sds = [r.sd_flatFloor(0.0)]
        ..mats = [r.mat_chessboardXY0(1.0, new Vector4(0.9,0.0,0.5,1.0), new Vector4(0.2,0.2,0.8,1.0)), _defaultShadeMats]
        //..sh = _defaultShade(c: "mat_chessboardXY0(p)")
        ..sh = _defaultShade(c: "vec4(1.0)")
      )
      ;
    }
    ;
  }

  RenderableDef newMobileWall(Iterable<Polygone> shapes, num dz, Vector4 color) {
    var utx = 'utx${_uCnt++}';
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
        ..mats = [_defaultShadeMats]
        ..sh = _defaultShade(c : _vec4(color))
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

  RenderableDef newCylindersZ(Iterable<Ellipse> es, double zSize, Vector4 color) {
    _uCnt++;
    var sd = 'sd_cyl${_uCnt}';
    var sdm = sd_merge(sd, es.map((x){
      return "d = sd_cylinder(p - ${_vec3(x.position)}, ${x.rx}, ${zSize * 0.5});";
    }));
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      //var ps = entity.getComponent(Particles.CT) as Particles;
      var obj = new r.ObjectInfo()
      ..sds = [r.sd_cylinder, sdm]
      ..de = "$sd(p)"
      ..mats = [_defaultShadeMats]
      ..sh = _defaultShade(c : _vec4(color))
      ;
      return new Renderable()..obj = obj;
    };
  }

  RenderableDef newPolygonesExtrudesZ(Iterable<Polygone> shapes, num dz, glf.ProgramContext ctx, Vector4 color, {isMobile : false, includeFloor : false}) {
    _uCnt++;
    var utx = 'pezTx${_uCnt}';
    var utex = 'pezTex${_uCnt}';
    var sd = 'sd${_uCnt}';
    return new RenderableDef()
    ..onInsert = (gl, Entity entity) {
      //var ps = entity.getComponent(Particles.CT) as Particles;
      //QUESTION use shapes or segment from entity ??
      var transform = new Matrix4.identity();
      var aabb = new Aabb3();
      shapes.forEach((shape){
        math2.updateAabbPoly(shape.points, aabb);
      });
      var sdm = sd_merge(sd, shapes.map((shape){
          var s = 'd = -10000.0;\n';
          for(var i=0; i < shape.points.length; i++) {
            var p0 = shape.points[i];
            var p1 = shape.points[(i + 1) % shape.points.length];
            s += 'd = max(d, sd_lineXY(pxy, vec2(${p0.x}, ${p0.y}), vec2(${p1.x}, ${p1.y})));\n';
          }
          return s;
        }),
        init:'''vec2 pxy = p.xy;'''
      );
      var obj = new r.ObjectInfo()
      ..uniforms = 'uniform mat4 ${utx};'
      ..sds = [r.sd_lineXY, sdm]
      ..de = "${sd}(p)"
      ..at = (ctx) {
          glf.injectMatrix4(ctx, transform, utx);
          transform.setIdentity();
          //transform.setTranslation(-ps.position3d[0]);
      };
      var unit = math.max(aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y);
      var zSize = 10.0;
      obj = r.makeExtrudeZinTex(gl, _textures, utex, aabb.center, zSize, unit, [obj], color: color)
      ..mats = [r.n_tex2d, _defaultShadeMats]
      ..sh = _defaultShade(c: "vec4(1.0,1.0,1.0,1.0)"/*, n : "n_tex2d(p, ${utex}, vec3(${aabb.center.x}, ${aabb.center.y}, ${aabb.center.z}), $zSize, ${1/unit}, ${unit})"*/)
      //..sh = defaultShade()
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
      ..sds = [
        (l) => l.add("""
            float thalfspace(vec3 p, vec3 a1, vec3 a2, vec3 a3){
            vec3 c = vec3(a1);
            c = c + (a2 - c) * 0.5;
            c = c + (a3 - c) * 0.5;
            
            //vec3 c = (a1 + a2 + a3) * TIER;
            vec3 n = -normalize(cross(a2 - a1, a3 - a1));
            float b = length(a1 - c);
            return max(0.0, dot(p-a1, n));
            }
        """),
        (l) => l.add("""  
            float sd_drone(vec3 p, vec3 a1, vec3 a2, vec3 a3, vec3 a4){
            float d = 0.0;
            d = max(thalfspace(p, a1, a3, a2),d);
            d = max(thalfspace(p, a1, a2, a4),d);
            d = max(thalfspace(p, a4, a2, a3),d);
            d = max(thalfspace(p, a1, a4, a3),d);
            return d;
            }
        """)
        ]
      ..mats = [_defaultShadeMats]
      ..sh = _defaultShade(c : "vec4(0.5, 0.0, 0.0, 1.0)")
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
