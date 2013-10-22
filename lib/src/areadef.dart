part of vdrones;

// TODO document conversion (API or blog, md)
class AreaReader4Svg {
  area(svg.SvgElement e) {
    var cache = new Map<svg.GraphicsElement, Matrix4>();
    //e.children.removeWhere((e) => e.classes.contains("ignore"));
    var out = new AreaDef()
    ..gateIns = e.queryAll(".gate_in circle").map((x) => gateIn(x, cache))
    ..gateOuts = e.queryAll(".gate_out circle").map((x) => gateOut(x, cache))
    ..staticWalls = e.queryAll(".static_wall").map((x) => staticWall(x, cache))
    ..mobileWalls = e.queryAll(".mobile_wall").map((x) => mobileWall(x, cache))
    ..cubeGenerators = e.queryAll(".cube_generator").map((x) => cubeGenerator(x, cache))
    ;
    out.aabb3 = out.staticWalls.fold(out.aabb3, (acc, v){
      return v.shapes.fold(acc, (acc1, v1){
        return Math2.updateAabbPoly(v1.points, acc1);
      });
    });
    return out;
  }

  gateIn(svg.CircleElement geom, Map<svg.GraphicsElement, Matrix4> cache) {
    var t = findTransform(geom, cache);
    return new GateIn()
    ..ellipse = (new Ellipse()
      ..position = t.transform3(new Vector3(geom.cx.baseVal.value, geom.cy.baseVal.value, 0.5))
      ..rx = geom.r.baseVal.value
      ..ry = geom.r.baseVal.value
    )
    ;
  }

  gateOut(svg.CircleElement geom, Map<svg.GraphicsElement, Matrix4> cache) {
    Matrix4 t = findTransform(geom, cache);
    return new GateOut()
    ..ellipse = (new Ellipse()
      ..position = t.transform3(new Vector3(geom.cx.baseVal.value, geom.cy.baseVal.value, 0.5))
      ..rx = geom.r.baseVal.value
      ..ry = geom.r.baseVal.value
    )
    ;
  }

  staticWall(svg.GElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    var shapes = new List();
    e.queryAll("rect").fold(shapes, (acc, x) => acc..add(rectToShape(x, 0.0, cache)));
    e.queryAll("path").fold(shapes, (acc, x) => acc..addAll(pathToShapes(x, 0.0, cache)));
    return new StaticWall()
    ..shapes = shapes
    ;
  }

  mobileWall(svg.GElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    return new MobileWall()
    ..shapes = e.queryAll('rect').map((x) => rectToShape(x, 0.1, cache))
    ..animation = pathToAnimationMvt(e.query('path'), cache)
    ;
  }

  cubeGenerator(svg.GElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    return new CubeGen()
    ..subZones = e.queryAll('rect').map((x) => rectToShape(x, 0.0, cache))
    ;
  }

  findTransform(svg.GraphicsElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    var out = (e != null)? cache[e] :  new Matrix4.identity();
    if (out == null) {
      var parentM = findTransform(e.parent, cache);
      var ts = e.transform.baseVal;
      out = ts.isEmpty ? parentM : toMatrix4(ts.first.matrix).multiply(parentM);
      cache[e] = out;
    }
    return out;
  }

  rectToShape(svg.RectElement e, double z, Map<svg.GraphicsElement, Matrix4> cache) {
    Matrix4 t = findTransform(e, cache);
    var x = e.x.baseVal.value;
    var y = e.y.baseVal.value;
    var w = e.width.baseVal.value;
    var h = e.height.baseVal.value;
    return new Polygone()
    ..points = [new Vector3(x, y, z), new Vector3(x+w, y, z), new Vector3(x+w, y+h, z), new Vector3(x, y+h, z)].map(t.transform3).toList(growable:false)
    ;
  }

  //TODO : support relative, closed (=> convex polygone)
  // the stroke calculation at linejoin is wrong
  pathToShapes(svg.PathElement e, double z, Map<svg.GraphicsElement, Matrix4> cache) {
    Matrix4 t = findTransform(e, cache);
    var p = (e.normalizedPathSegList != null) ?
        e.normalizedPathSegList
          : e.pathSegList;
    var l = p.length;
    var points = new List<Vector3>(l * 2);
    var r = styleToDouble(e, 'stroke-width');
    var strokesV = new List<Vector3>(l);
    var symI = (i) => 2 * l -1 -i;
    // points in absolute position
    for (var i = 0; i < l; ++i) {
      switch(p[i].pathSegType){
        case svg.PathSeg.PATHSEG_LINETO_ABS :
          var pi = p[i] as svg.PathSegLinetoAbs;
          points[i] = new Vector3(pi.x, pi.y, z);
          break;
        case svg.PathSeg.PATHSEG_MOVETO_ABS :
          var pi = p[i] as svg.PathSegMovetoAbs;
          points[i] = new Vector3(pi.x, pi.y, z);
          break;
        case svg.PathSeg.PATHSEG_LINETO_REL:
          var pi = p[i] as svg.PathSegLinetoRel;
          points[i] = new Vector3(points[i - 1].x + pi.x, points[i - 1].y + pi.y, z);
          break;
        default:
          print("Unsupported path element : ${p[i].pathSegType} in ${e}");
          points[i] = new Vector3.zero();
      }
      points[symI(i)] = new Vector3.copy(points[i]);
    }
    // stroke of frag
    for (var i = 0; i < l; ++i) {
      if (i == (l - 1)) {
        strokesV[i] = strokesV[i - 1];
      } else {
        strokesV[i] = Math2.rot90V2(new Vector3.copy(points[i + 1]).sub(points[i])).normalize().scale(r);
      }
    }
    // stroke of points (join stroke of frag)
    for (var i = l-2; i > 0; --i) {
      strokesV[i].add(strokesV[i-1]).normalize().scale(r);
    }
    // move points to stroke
    for (var i = 0; i < l; ++i) {
      points[i].add(strokesV[i]);
      points[symI(i)].sub(strokesV[i]);
    }
    // create a list of quad (no concave polygone)
    var quads = new List<Polygone>();
    for (var i = 1; i < l; ++i) {
      quads.add(new Polygone()
        ..points = [points[i-1], points[i], points[symI(i)], points[symI(i - 1)]]//.map(t.transform3).toList(growable:false)
      )
      ;
    }
    return quads;
  }

  pathToAnimationMvt(svg.PathElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    Matrix4 t = findTransform(e, cache);
    var p = (e.normalizedPathSegList != null) ?
        e.normalizedPathSegList
          : e.pathSegList;
    var v;
    if (p.first.pathSegType == svg.PathSeg.PATHSEG_MOVETO_ABS) {
      var p0 = p.first as svg.PathSegMovetoAbs;
      var p1 = p.last as svg.PathSegLinetoAbs;
      v = t.transform3(new Vector3(p1.x - p0.x, p1.y - p0.y, 0.0));
    } else if (p.first.pathSegType == svg.PathSeg.PATHSEG_MOVETO_REL) {
      var p1 = p.last as svg.PathSegLinetoRel;
      v = new Vector3(p1.x, p1.y, 0.0);
    }
    return new AnimationMvt()
    ..duration = toDouble(e, 'x-duration')
    ..loop = e.attributes['x-loop'] == "true"
    ..pingpong = e.attributes['x-pingpong'] == "true"
    ..ratioInit = 0.0
    ..deplacement = v
    ;
  }
  toDouble(svg.GraphicsElement e, String k) {
    var v = e.attributes[k];
    if (v == null) throw new Exception("attribute '$k' not found in element <${e.tagName} id='${e.id}' ...>");
    return double.parse(v);
  }

  styleToDouble(svg.GraphicsElement e, String k) {
    var v = e.style.getPropertyValue(k);
    if (v == null || v.length == 0) throw new Exception("style '$k' not found in element <${e.tagName} id='${e.id}' ...>");
    if (!v.endsWith('px')) throw new Exception("style not in 'px' in element <${e.tagName} id='${e.id}' style='$k:$v;...' ...>");
    return double.parse(v.substring(0, v.length - 2));
  }

  toMatrix4(svg.Matrix m) {
    return new Matrix4.identity()
    ..setUpper2x2(new Matrix2(m.a, m.c, m.b, m.d))
    ..setTranslationRaw(m.e, m.f, 0.0)
    ;
  }
}

class AreaReader4Json1 {
  area(Map json) {
    var cellr = json['cellr'].toDouble();
    var out = new AreaDef()
    ..gateIns = gateIns(json["zones"]["gate_in"], cellr)
    ..gateOuts = gateOuts(json["zones"]["gate_out"], cellr)
    ..staticWalls = staticWalls(json, cellr)
    ..mobileWalls = mobileWalls(json["zones"]["mobile_walls"], cellr)
    ..cubeGenerators = cubeGenerators(json["zones"]["cubes_gen"], cellr)
    ;
    out.aabb3 = out.staticWalls.fold(out.aabb3, (acc, v){
      return v.shapes.fold(acc, (acc1, v1){
        return Math2.updateAabbPoly(v1.points, acc1);
      });
    });
    return out;
  }

  gateIns(json, cellr){
    var rects = cells_rects(cellr, json["cells"], 2.0);
    var rzs = json["angles"];
    var out = new List<GateIn>();
    for (var i = 0; i < rects.length; i += 4) {
      var angle = radians(rzs[i~/4]);
      out.add(new GateIn()
        ..ellipse = (new Ellipse()
          ..position = new Vector3(rects[i+0], rects[i+1], 0.5)
          ..rx = rects[i+2] * 0.5
          ..ry = rects[i+3] * 0.5
        )
        ..vdroneDirection.setValues(math.cos(angle), math.sin(angle), 0.0)
      );
    }
    return out;
  }

  gateOuts(json, cellr){
    var rects = cells_rects(cellr, json["cells"], 1.0);
    var out = new List<GateOut>();
    for (var i = 0; i < rects.length; i += 4) {
      out.add(new GateOut()
        ..ellipse = (new Ellipse()
          ..position = new Vector3(rects[i+0], rects[i+1], 0.5)
          ..rx = rects[i+2] * 0.5
          ..ry = rects[i+3] * 0.5
        )
      );
    }
    return out;
  }

  staticWalls(json, cellr) {
    var width = json['width'];
    var height = json['height'];

    makeBorderAsCells(num w, num h) {
      var cells = new List<num>();
      cells..add(-1)..add(-1)..add(w+2)..add(  1);
      cells..add(-1)..add(-1)..add(  1)..add(h+2);
      cells..add( w)..add(-1)..add(  1)..add(h+2);
      cells..add(-1)..add( h)..add(w+2)..add(  1);
      return cells;
    }
    var walls0 = new List<int>();
    if (json["walls"]["cells"] != null) {
      walls0.addAll(json["walls"]["cells"]);
    }
    if (json["walls"]["maze"] != null) {
      walls0.addAll(makeMaze(json["walls"]["maze"][1], json["walls"]["maze"][2], json["walls"]["maze"][3], 0, 0, width, height));
    }
    var walls = new List<double>();
    walls.addAll(cells_rects(cellr, makeBorderAsCells(width, height), 0));
    walls.addAll(cells_rects(cellr, walls0));
    var shapes = new List<Polygone>()
    ;
    for(var i = 0; i < walls.length; i+=4) {
      var x = walls[i + 0];
      var y = walls[i + 1];
      var dx = walls[i + 2];
      var dy = walls[i + 3];
      var shape = new Polygone()
      ..points = [
         new Vector3(x - dx, y - dy, 0.0),
         new Vector3(x - dx, y + dy, 0.0),
         new Vector3(x + dx, y + dy, 0.0),
         new Vector3(x + dx, y - dy, 0.0)
      ]
      ;
      shapes.add(shape);
    }
    var out = new StaticWall()
    ..shapes = shapes
    ;
    return [out];
  }

  //newMobileWall(double x0, double y0, double dx, double dy, double dz, num tx, num ty, num duration,  bool inout
  mobileWalls(json, cellr) {
    return (json == null) ? [] : json.map((t) {
      var x = (t[0] + t[2] * 0.5) * cellr;
      var y = (t[1] + t[3] * 0.5) * cellr;
      var dx = math.max(1.0, t[2] * 0.5 * cellr);
      var dy = math.max(1.0, t[3] * 0.5 * cellr);
      //var dz = math.max(2.0, 1.0  * 0.3  * cellr);
      return new MobileWall()
      ..shapes = [
        new Polygone()
        ..points = [
          new Vector3(x - dx, y - dy, 0.0),
          new Vector3(x - dx, y + dy, 0.0),
          new Vector3(x + dx, y + dy, 0.0),
          new Vector3(x + dx, y - dy, 0.0)
        ]
      ]
      ..animation = (new AnimationMvt()
        ..deplacement = new Vector3(t[4] * cellr, t[5] * cellr, 0.0)
        ..duration = t[6] * 1000
        ..pingpong = t[7] == 1
      )
      ;
    });
  }

  cubeGenerators(json, cellr) {
    var rects = cells_rects(cellr, json["cells"]);
    var l = new List<Polygone>();
    for(var i = 0; i < rects.length; i += 4) {
      //1.0 around for wall
      //0.5 half size of generated cube;
      var dx = rects[i + 2] - 1.5;
      var dy = rects[i + 3] - 1.5;
      var x = rects[i + 0];
      var y = rects[i + 1];
      l.add(new Polygone()
        ..points = [
          new Vector3(x - dx, y - dy, 0.0),
          new Vector3(x - dx, y + dy, 0.0),
          new Vector3(x + dx, y + dy, 0.0),
          new Vector3(x + dx, y - dy, 0.0)
        ]
      );
    }
    var out = new CubeGen()
    ..subZones = l
    ;
    return [out];
  }
  /// convert a list of cells [bottom0, left0, width0, height0, bottom1, left1,...] + cellr into
  /// [centerx0, centery0, halfdx0, halfdy0, centerx1, centery1, ...] in the final unit (renderable + physics)
  /// special rules:
  /// * if width == 0 then halfdx = cellr/20
  /// * if height == 0 then halfdy = cellr/20
  /// * if width > 0 then haldx = width * cellr - 2 * cellr
  /// * if height > 0 then haldy = height * cellr - 2 * cellr
  List<double> cells_rects(num cellr, List<num> cells, [margin = -1.0]) {
    margin = (margin < 0) ? cellr/20 : margin;
    var b = new List<double>(cells.length);
    for(var i = 0; i < cells.length; i+=4) {
      var hx = cells[i+2] * cellr / 2;
      var hy = cells[i+3] * cellr / 2;
      b[i+0] = cells[i+0] * cellr + hx;
      b[i+1] = cells[i+1] * cellr + hy;
      b[i+2] = (hx == 0) ? margin : hx - 2 * margin;
      b[i+3] = (hy == 0) ? margin : hy - 2 * margin;
    }
    return b;
  }
}

class AreaDef {
  Iterable<GateIn> gateIns;
  Iterable<GateOut> gateOuts;
  Iterable<MobileWall> mobileWalls;
  Iterable<StaticWall> staticWalls;
  Iterable<CubeGen> cubeGenerators;
  var chronometer = -60 * 1000; //millis
  var aabb3 = new Aabb3();
  var ambient = 0x444444;
}

class Polygone {
  List<Vector3> points;
}

class Ellipse {
  Vector3 position;
  double rx = 1.0;
  double ry = 1.0;
}

class StaticWall {
  Iterable<Polygone> shapes;
  Vector4 color = new Vector4(0.9, 0.9, 0.95, 1.0);
}

class AnimationMvt {
  double ratioInit = 0.0;
  Vector3 deplacement = new Vector3.zero();
  num duration;
  //String easeName = "linear";
  bool loop = true;
  bool pingpong = false;
}

class MobileWall {
  Iterable<Polygone> shapes;
  AnimationMvt animation;
  Vector4 color = new Vector4(0.8, 0.1, 0.1, 0.7);
}

class GateIn {
  Ellipse ellipse;
  Vector3 vdroneDirection = new Vector3(1.0, 0.0, 0.0);
}

class GateOut {
  Ellipse ellipse;
}
class CubeGen {
  Iterable<Polygone> subZones;
}