part of vdrones;

class AreaReader4Svg {
  area(svg.SvgElement e) {
    var cache = new Map<svg.GraphicsElement, Matrix4>();
    return new AreaDef()
    ..gateIns = e.queryAll(".gate_in path").map((x) => gateIn(x, cache)).toList(growable: false)
    ..gateOuts = e.queryAll(".gate_out path").map((x) => gateOut(x, cache)).toList(growable: false)
    ..staticWalls = e.queryAll(".static_wall").map((x) => staticWall(x, cache)).toList(growable: false)
    ..mobileWalls = e.queryAll(".mobile_wall").map((x) => mobileWall(x, cache)).toList(growable: false)
    ;
  }

  gateIn(svg.GraphicsElement geom, Map<svg.GraphicsElement, Matrix4> cache) {
    var t = findTransform(geom, cache);
    return new GateIn()
    ..ellipse = (new Ellipse()
      ..position = t.transform3(new Vector3(toDouble(geom, 'sodipodi:cx'), toDouble(geom, 'sodipodi:cy'), 2.0))
      ..rx = toDouble(geom, 'sodipodi:rx')
      ..ry = toDouble(geom, 'sodipodi:ry')
    )
    ;
  }

  gateOut(svg.GraphicsElement geom, Map<svg.GraphicsElement, Matrix4> cache) {
    Matrix4 t = findTransform(geom, cache);
    return new GateOut()
    ..ellipse = (new Ellipse()
      ..position = t.transform3(new Vector3(toDouble(geom, 'sodipodi:cx'), toDouble(geom, 'sodipodi:cy'), 0.0))
      ..rx = toDouble(geom, 'sodipodi:rx')
      ..ry = toDouble(geom, 'sodipodi:ry')
    )
    ;
  }

  staticWall(svg.GElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    return new StaticWall()
    ..shapes = e.queryAll("rect").map((x) => rectToShape(x, cache))
    ;
  }

  mobileWall(svg.GElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    return new MobileWall()
    ..shapes = e.queryAll("rect").map((x) => rectToShape(x, cache))
    ..animation = new AnimationMvt()
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
    print("$out $e");
    return out;
  }

  rectToShape(svg.RectElement e, Map<svg.GraphicsElement, Matrix4> cache) {
    Matrix4 t = findTransform(e, cache);
    var x = e.x.baseVal.value;
    var y = e.y.baseVal.value;
    var w = e.width.baseVal.value;
    var h = e.height.baseVal.value;
    return new Polygone()
    ..points = [new Vector3(x, y, 0.0), new Vector3(x+w, y, 0.0), new Vector3(x+w, y+h, 0.0), new Vector3(x, y+h, 0.0)].map(t.transform3)
    ;
  }
  toDouble(svg.GraphicsElement e, String k) => double.parse(e.attributes[k]);

  toMatrix4(svg.Matrix m) {
    return new Matrix4.identity()
    ..setUpper2x2(new Matrix2(m.a, m.c, m.b, m.d))
    ..setTranslationRaw(m.e, m.f, 0.0)
    ;
  }
}

class AreaReader4Json1 {
  area(Map json) {

//    return new AreaDef()
//    ..gateIns = e.queryAll(".gate_in path").map((x) => gateIn(x, cache)).toList(growable: false)
//    ..gateOuts = e.queryAll(".gate_out path").map((x) => gateOut(x, cache)).toList(growable: false)
//    ..staticWalls = e.queryAll(".static_wall").map((x) => staticWall(x, cache)).toList(growable: false)
//    ..mobileWalls = e.queryAll(".mobile_wall").map((x) => mobileWall(x, cache)).toList(growable: false)
//    ;
    var cellr = json['cellr'].toDouble();

//    var es = new List<Entity>();
//    es.add(newCamera("${assetpack.name}.music", new Aabb3.minmax(new Vector3(-0.1, -0.1, -0.1), new Vector3(width * cellr + 0.1, height * cellr + 0.1, 2.0 * cellr +0.1))));
//    var v = json["light_ambient"];
//    v = (v == null) ? 0x444444 : v;
//    es.add(newAmbientLight(v));
//    json["lights_spots"].forEach((i) {
//      es.add(newLight(new Vector3(i[0]*cellr, i[1]*cellr, i[2]*cellr), new Vector3(i[3]*cellr, i[4]*cellr, i[5]*cellr)));
//    });
//    es.add(newArea(assetpack.name));
//    es.add(newChronometer(-60 * 1000, timeout));
//    es.add(newCubeGenerator(cells_rects(cellr, json["zones"]["cubes_gen"]["cells"])));
//    if (json["zones"]["mobile_walls"] != null) {
//      json["zones"]["mobile_walls"].forEach((t) {
//        es.add(newMobileWall(
//          (t[0] + t[2] * 0.5) * cellr,
//          (t[1] + t[3] * 0.5) * cellr,
//          math.max(1.0, t[2] * 0.5 * cellr),
//          math.max(1.0, t[3] * 0.5 * cellr),
//          math.max(2.0, 1.0  * 0.3  * cellr),
//          t[4] * cellr,
//          t[5] * cellr,
//          t[6] * 1000,
//          t[7] == 1,
//          assetpack
//        ));
//      });
//    }
    return new AreaDef()
    ..gateIns = gateIns(json["zones"]["gate_in"], cellr)
    ..gateOuts = gateOuts(json["zones"]["gate_out"], cellr)
    ..staticWalls = staticWalls(json, cellr)
    ..mobileWalls = mobileWalls(json["zones"]["mobile_walls"], cellr)
    ..cubeGens = cubeGens(json["zones"]["cubes_gen"], cellr)
    ;

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
      print("read cells");
      walls0.addAll(json["walls"]["cells"]);
    }
    if (json["walls"]["maze"] != null) {
      walls0.addAll(makeMaze(json["walls"]["maze"][1], json["walls"]["maze"][2], json["walls"]["maze"][3], 0, 0, width, height));
    }
    var walls = new List<double>();
    walls.addAll(cells_rects(cellr, makeBorderAsCells(width, height), 0));
    walls.addAll(cells_rects(cellr, walls0));
    var out = new StaticWall()
    ..shapes = new List<Polygone>()
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
      out.shapes.add(shape);
    }
    return [out];
  }

  //newMobileWall(double x0, double y0, double dx, double dy, double dz, num tx, num ty, num duration,  bool inout
  mobileWalls(json, cellr) {
    return [];
  }

  cubeGens(json, cellr) {
    return [];
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
  List<GateIn> gateIns;
  List<GateOut> gateOuts;
  List<MobileWall> mobileWalls;
  List<StaticWall> staticWalls;
  List<CubeGen> cubeGens;
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
  List<Polygone> shapes;
  Vector4 color = new Vector4(0.9, 0.9, 0.95, 1.0);
}

class AnimationMvt {
  double ratioInit = 0.0;
  Vector3 deplacement = new Vector3.zero();
  String easeName = "linear";
  bool loop = true;
  bool pingpong = false;
}

class MobileWall {
  List<Polygone> shapes;
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
  List<Polygone> areas;
}