library vdrones_entities;

//import 'package:three/three.dart' as three;
//import 'package:three/extras/geometry_utils.dart' as GeometryUtils;


import 'package:box2d/box2d_browser.dart';
import 'animations.dart' as animations;
import 'events.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:json' as JSON;
import 'dart:html';
import 'dart:svg' as svg;

import 'package:js/js.dart' as js;

class EntityTypes {
  static const WALL =   0x0001;
  static const DRONE =  0x0002;
  static const BULLET = 0x0004;
  static const SHIELD = 0x0008;
  static const ITEM =   0x0010;
}

class Object2D {
  BodyDef bdef;
  List<FixtureDef> fdefs;
}

class EntityProvider {
  Object2D obj2dF() => null;
  js.Proxy obj3dF() => null;
  final anims = new Map<String, animations.Animate>();

  EntityProvider();
}

class EntityProvider4Static extends EntityProvider {
  Object2D _obj2d;
  js.Proxy _obj3d;

  Object2D obj2dF() => _obj2d;
  js.Proxy obj3dF() => _obj3d;
  final anims = new Map<String, animations.Animate>();
  List<num> cells;
  num cellr;

  EntityProvider4Static(this._obj2d, this._obj3d, this.cells, this.cellr);
}

//class EntityProvider4Axis extends EntityProvider {
//  js.Proxy obj3dF() {
//    var o;
//    js.scoped((){
//    final THREE = js.context.THREE;
//    o = new js.Proxy(THREE.AxisHelper);
//    o.scale.setValues(0.1, 0.1, 0.1); //# default length of axis is 100
//    o  = js.retain(o);
//    });
//    return o;
//  }
//}

class EntityProvider4Targetg102 extends EntityProvider {
  Object2D obj2dF() {
    var r = new Object2D();
    r.bdef = new BodyDef();
    var s = new CircleShape();
    s.radius = 1;
    var f = new FixtureDef();
    f.shape = s;
    f.isSensor = true;
    f.filter.groupIndex = EntityTypes.ITEM;
    r.fdefs = [f];
    return r;
  }

  js.Proxy obj3dF(){
    var o;
    js.scoped((){
    final THREE = js.context.THREE;
    var s = 1;
    var geometry = new js.Proxy(THREE.CubeGeometry, s, s, s);
    var material = new js.Proxy(THREE.MeshNormalMaterial);
    o = new js.Proxy(THREE.Mesh, geometry, material);
    o.position.z = 1;
    o = js.retain(o);
    });
    return o;
  }

  EntityProvider4Targetg102() {
    anims["spawn"] = (animations.Animator animator, js.Proxy obj3d) => animations.scaleIn(animator, obj3d).then((obj3d) => animations.rotateXYEndless(animator, obj3d));
    anims["despawnPre"] = animations.scaleOut;
    anims["none"] = animations.noop;
  }
}

class EntityProvider4Cube extends EntityProvider {
  js.Proxy obj3dF(){
    var o;
    js.scoped((){
    final THREE = js.context.THREE;
      num s = 20;
      var geometry = new js.Proxy(THREE.CubeGeometry, s, s, s);
      var material = new js.Proxy(THREE.MeshBasicMaterial, js.map({
        "color": 0xff0000,
        "wireframe": true
      }));
      o = new js.Proxy(THREE.Mesh, geometry, material);
      js.retain(o);
    });
    return o;
  }
  EntityProvider4Cube() {
    anims["spawn"] = animations.rotateXYEndless;
    anims["waiting"] = animations.rotateXYEndless;
  }
}

//  # Blenders euler order is 'XYZ', but the equivalent euler rotation order in Three.js is 'ZYX'
js.Proxy fixOrientation(js.Proxy obj3d){
  var y2 = obj3d.rotation.z;
  var z2 = -obj3d.rotation.y;
//    #m.rotation.x = ob.rot[0];
//    #obj3d.rotation.y = y2;
//    #obj3d.rotation.z = z2;
  obj3d.eulerOrder = "ZYX";
  obj3d.castShadow = true;
  obj3d.receiveShadow  = false;
  return obj3d;
}

Node makeHud(Document d){
  // I tried a lot to read SVG as text and then create svfelement but without success
  //(I also tried like https://github.com/IntersoftDev/dart-squid/blob/master/lib/svg_defs.dart)
  // But the better it to read responseXml and not responseTxt
  //return document.importNode(d.result.documentElement, true);
//  var svgElement = new Element.tag('div');
//  var svgElement = new svg.SvgElement.tag('svg');
//  svgElement.innerHtml = d;
//  var b = svgElement.nodes[0].clone(true);
//  return b;
  return d.documentElement.clone(true);
}

Map<String, EntityProvider> makeArea(jsonStr) {
  var area = JSON.parse(jsonStr);
  var cellr = area["cellr"];

  js.Proxy cells2boxes3d(List<num> cells, num width, num height){
    var o;
    js.scoped((){
    final THREE = js.context.THREE;
      var geometry = new js.Proxy(THREE.Geometry);
      //  #material = new js.Proxy(THREE.MeshNormalMaterial, )
      var materialW = new js.Proxy(THREE.MeshLambertMaterial, js.map({"color" : 0x8a8265, "transparent": false, "opacity": 1, "vertexColors" : THREE.VertexColors}));
      //var materialW = new js.Proxy(THREE.MeshBasicMaterial, color : 0x8a8265, wireframe : false);
      for(var i = 0; i < cells.length; i+=4) {
        var dx = math.max(1, cells[i+2] * cellr);
        var dy = math.max(1, cells[i+3] * cellr);
        var dz = math.max(2, cellr / 2);
        var mesh = new js.Proxy(THREE.Mesh, new js.Proxy(THREE.CubeGeometry, dx, dy, dz), materialW);
        mesh.position.x = cells[i+0] * cellr + dx / 2;
        mesh.position.y = cells[i+1] * cellr + dy / 2;
        THREE.GeometryUtils.merge(geometry, mesh);
      }
      var walls = new js.Proxy(THREE.Mesh, geometry, materialW);

      //var materialF = new three.MeshLambertMaterial (color : 0xe1d5a5, transparent: false, opacity: 1, vertexColors : three.VertexColors);
      var materialF = new js.Proxy(THREE.MeshPhongMaterial, js.map({"color" : 0xe1d5a5}));
      //var materialF = new js.Proxy(THREE.MeshBasicMaterial, color : 0xe1d5a5, wireframe : false);
      var floor = new js.Proxy(THREE.Mesh, new js.Proxy(THREE.PlaneGeometry, width * cellr, height * cellr), materialF);
      floor.position.x = width * cellr /2;
      floor.position.y = height * cellr /2;

      var obj3d = new js.Proxy(THREE.Object3D);
      obj3d.add(walls);
      obj3d.add(floor);
      o = js.retain(obj3d);
    });
    return o;
  }

  Object2D cells2boxes2d(List<num> cells) {
    var r = new Object2D();
    r.bdef = new BodyDef();
    //r.body.nodeIdleTime = double.INFINITY;
    r.fdefs = [];
    for(var i = 0; i < cells.length; i+=4) {
      //TODO optim replace boxes (polyshape) by segment + thick (=> change the display)
      var hx = math.max(1, cells[i+2] * cellr) / 2;
      var hy = math.max(1, cells[i+3] * cellr) /2;
      var x = cells[i+0] * cellr + hx;
      var y = cells[i+1] * cellr + hy;
      var shape = new PolygonShape();
      shape.setAsBoxWithCenterAndAngle(hx, hy, new Vector(x, y), 0);
      var f = new FixtureDef();
      f.shape = shape;
      f.filter.groupIndex = EntityTypes.WALL;
      r.fdefs.add(f);
    }
    return r;
  }

  void addBorderAsCells(num w, num h, List<num>cells) {
    cells..add(-1)..add(-1)..add(w+2)..add(  1);
    cells..add(-1)..add(-1)..add(  1)..add(h+2);
    cells..add( w)..add(-1)..add(  1)..add(h+2);
    cells..add(-1)..add( h)..add(w+2)..add(  1);
  }

  js.Proxy cells2surface3d(cells, offz) {
    var o;
    js.scoped((){
    final THREE = js.context.THREE;
    var geometry = new js.Proxy(THREE.Geometry );
    //#material = new js.Proxy(THREE.MeshNormalMaterial, )
    var material = new js.Proxy(THREE.MeshBasicMaterial, js.map({"color" : 0x000065, "wireframe" : false}));
    for(var i = 0; i < cells.length; i+=4) {
      var dx = cells[i+2] * cellr - 2;
      var dy = cells[i+3] * cellr - 2;
      var mesh = new js.Proxy(THREE.Mesh, new js.Proxy(THREE.PlaneGeometry, dx, dy), material);
      mesh.position.x = cells[i+0] * cellr + 1 + dx / 2;
      mesh.position.y = cells[i+1] * cellr + 1 + dy / 2;
      THREE.GeometryUtils.mergeMesh(geometry, mesh);
    }
    var obj3d = new js.Proxy(THREE.Mesh, geometry, material);
    obj3d.position.z = offz;
    o = js.retain(obj3d);
    });
    return o;
  }

  addBorderAsCells(area["width"], area["height"], area["walls"]["cells"]);
  var r = {
    "walls" : new EntityProvider4Static(
      cells2boxes2d(area["walls"]["cells"]),
      cells2boxes3d(area["walls"]["cells"], area["width"], area["height"]),
      area["walls"]["cells"],
      cellr
    ),
    "gate_in" : new EntityProvider4Static(
      null,
      null, //cells2surface3d(area["zones"]["gate_in"]["cells"], 0.5),
      area["zones"]["gate_in"]["cells"],
      cellr
    ),
    "targetg1_spawn" : new EntityProvider4Static(
      null,
      null,//cells2surface3d(area["zones"]["targetg1_spawn"]["cells"], 0.5),
      area["zones"]["targetg1_spawn"]["cells"],
      cellr
    )
  };
  print("AREA : ${r}");
  return r;
}

class EntityProvider4Drone extends EntityProvider {
  js.Proxy _obj3dPattern;

  Object2D obj2dF() {
    var r = new Object2D();
    r.bdef = new BodyDef();
    r.bdef.linearDamping = 5;
    var s = new PolygonShape();
    PolygonShape shape = new PolygonShape();
    shape.setAsEdge(new Vector(3, 0), new Vector(-1, -2));
    shape.setAsEdge(new Vector(-1, -2), new Vector(-1, 2));
    shape.setAsEdge(new Vector(-1, 1), new Vector(3, 0));
    var f = new FixtureDef();
    f.shape = shape;
    //s.sensor = false;
    f.filter.groupIndex = EntityTypes.DRONE;
    r.fdefs = [f];
    return r;
  }

  js.Proxy obj3dF() {
    _obj3dPattern.position.z = 1;
    return _obj3dPattern;//.clone();
  }

  EntityProvider4Drone(this._obj3dPattern) {
    anims["spawn"] = animations.scaleIn;
    anims["despawnPre"] = animations.scaleOut;
    anims["crash"] = animations.explodeOut;
    anims["none"] = animations.noop;
  }

}
//
//  makeScene = (d) ->
//    deferred = Q.defer()
//    try
//      new js.Proxy(THREE.SceneLoader, ).parse(JSON.parse(d.result), (result) ->
//        _.each(result.objects, fixOrientation)
//        deferred.resolve(result)
//      , d.src)
//    catch exc
//      deferred.reject(exc)
//    deferred.promise
//
Future<js.Proxy> makeModel(jsonStr, texturePath) {
  var deferred = new Completer();
  try {
    js.scoped((){
    final THREE = js.context.THREE;
    var loader = new js.Proxy(THREE.JSONLoader);
    //texturePath = loader.extractUrlBase( d.src )
    loader.createModel(
      js.map(JSON.parse(jsonStr)),
      new js.Callback.once((geometry, materials) {
        print("geometry ${geometry} .... ${materials}");
        //var material0 = new js.Proxy(THREE.MeshNormalMaterial);
        //var material = new js.Proxy(THREE.MeshNormalMaterial,  { shading: three.SmoothShading } );
        //geometry.materials[ 0 ].shading = three.FlatShading;
        //var material = new js.Proxy(THREE.MeshFaceMaterial, );
        //var material0 = geometry.materials[0];
        var material0 = materials[0];
        //material.transparent = true
        //material = new js.Proxy(THREE.MeshFaceMaterial, materials)
        //TODO should create a new object or at least change the timestamp
        //var material0 = new three.MeshLambertMaterial (color : 0xe7bf90, transparent: false, opacity: 1, vertexColors : three.VertexColors);
        var obj3d = fixOrientation(new js.Proxy(THREE.Mesh, geometry, material0));
        deferred.complete(js.retain(obj3d));
      }),
      texturePath
    );
    });
  } catch(exc) {
    deferred.completeError(exc);
  }
  return deferred.future;
}
//
//  makeSprite = (d) ->
//    deferred = Q.defer()
//    try
//      texture = new js.Proxy(THREE.Texture,  d.result )
//      texture.needsUpdate = true
//      texture.sourceFile = d.src
//      material = new js.Proxy(THREE.SpriteMaterial,  { map: texture, alignment: three.SpriteAlignment.topLeft, opacity: 1, transparent : true} )
//      obj3d = new js.Proxy(THREE.Sprite, material)
//      obj3d.scale.set( t.image.width, t.image.height, 1 )
//      obj3d.computeBoundingBox()
//      obj2d = { box : [obj3d.boundingBox.max.x, obj3d.boundingBox.max.y] }
//      r = {obj3d : obj3d, obj2d : obj2d}
//      deferred.resolve(r)
//    catch exc
//      deferred.reject(exc)
//
//  makeBox = (rx, ry, rz, color) ->
//    geometry = new js.Proxy(THREE.CubeGeometry, rx, ry, rz || 1)
//    material = new js.Proxy(THREE.MeshBasicMaterial, {
//      color: color || 0xff0000
//      wireframe: false
//    })
//    {
//      obj3d : new js.Proxy(THREE.Mesh, geometry, material)
//      obj2d : { box : [rx, ry] }
//    }
//

Future<String> _loadTxt(src) {
  var completer = new Completer<String>();
  var httpRequest = new HttpRequest();
  //httpRequest.responseType = 'text';
  httpRequest.onLoadEnd.listen(
    (data) {
      if (httpRequest.status == 200) {
        completer.complete(httpRequest.responseText);
      } else {
        completer.complete(null);
      }
    },
    onError : (err) {
      print("FAILURE $err");
      completer.completeError(err.error, err.stackTrace);
    }
  );
  //httpRequest.open('GET', src);
  httpRequest.open('GET', src, true);
  httpRequest.send();
  return completer.future;
}

Future<Document> _loadXml(src) {
  var completer = new Completer<Document>();
  var httpRequest = new HttpRequest();
  httpRequest.onLoadEnd.listen(
    (data) {
      if (httpRequest.status == 200) {
        completer.complete(httpRequest.responseXml);
      } else {
        completer.complete(null);
      }
    },
    onError : (err) {
      print("FAILURE $err");
      completer.completeError(err.error, err.stackTrace);
    }
  );
  //httpRequest.open('GET', src);
  httpRequest.open('GET', src, true);
  httpRequest.send();
  return completer.future;
}


Future<ImageElement> _loadImage(src) {
  var completer = new Completer<ImageElement>();
  ImageElement image = new ImageElement();
  image.onLoad.listen(
    (event) {
      completer.complete(image);
    },
    onError : (err) {
      completer.completeError(err.error, err.stackTrace);
    }
  );
  image.src = src;
  return completer.future;
}

class Entities {
  var _cache = new Map<String, Future>();

  Future preload(Evt evt, String kind, String id) {
    var progressMax = evt.GameStates.progressMax;
    if ( progressMax.v == evt.GameStates.progressCurrent.v) {
      evt.GameStates.progressCurrent.v = 0;
      progressMax.v = 1;
    } else {
      progressMax.v = progressMax.v + 1;
    }

    print("preload $kind $id");
    Future<EntityProvider> r = null;

    switch(kind) {
  //    case 'scene' :
  //      result = result.then(makeScene);
  //      load0(type : PreloadJS.JSON, src: src || '_models/' + id + '.scene.js');
  //      break;
      case 'model' :
        if (id == "cube0") {
          r = new Future.immediate(new EntityProvider4Cube());
        } else if (id == "targetg101") {
          r = new Future.immediate(new EntityProvider4Targetg102());
        } else {
          r = _loadTxt("_models/${id}.js")
            .then((x) => makeModel(x, '_models'))
            .then((x) => new EntityProvider4Drone(x))
            ;
        }
        break;
      case 'hud' :
        r = _loadXml("_images/${id}.svg")
          .then(makeHud)
          ;
        break;
      case 'area':
        r = _loadTxt("_areas/${id}.json")
          .then(makeArea)
          ;
        break;
    }
    r = r.then(
      (x) {
        evt.GameStates.progressCurrent.v = evt.GameStates.progressCurrent.v + 1;
        print("preload $kind $id DONE");
        return x;
      },
      onError : (err) {
        print("preload $kind $id FAILURE $err");
      }
    );
    print("store id ${id}");
    _cache[id] = r;
    return r;
  }

  Future find(String id){
    Future r = _cache[id];
    if (r == null) throw new Exception("id not found : ${id} in ${_cache.length}");
    return r;
    //return r == null ? new Future.immediateError(new Exception("id not found : ${id}")) : r;
  }
}


//  Q.onerror = (err) -> evt.Error.dispatch("failure ", err)
//  {
//    types : _types
//    find : (id) ->
//      r = _cache[id] || Q.reject("id not found " + id )
//      r.done()
//      r
//    clear: () ->
//      _cache = {}
//      _preload.close()
//    preload : preload
//  }
//)
//
