part of vdrones;
/*
class vec2 extends Vector{
  vec2(x, y) : super(x,y);
  vec2.zero() : super(0,0);
}
*/
class Object2D {
  BodyDef bdef;
  List<FixtureDef> fdefs;
}

class EntityProvider {
  Object2D obj2dF() => null;
  dynamic obj3dF() => null;
  final anims = new Map<String, Animate>();

  EntityProvider();
}

class EntityProvider4Static extends EntityProvider {
  Object2D _obj2d;
  dynamic _obj3d;

  Object2D obj2dF() => _obj2d;
  dynamic obj3dF() => _obj3d;
  final anims = new Map<String, Animate>();
  List<num> cells;
  num cellr;

  EntityProvider4Static(this._obj2d, this._obj3d, this.cells, this.cellr);
}

//class EntityProvider4Axis extends EntityProvider {
//  dynamic obj3dF() {
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
    f.filter.groupIndex = EntityTypes_ITEM;
    r.fdefs = [f];
    return r;
  }

  dynamic obj3dF(){
    return js.scoped((){
      final THREE = js.context.THREE;
      var s = 1;
      var geometry = new js.Proxy(THREE.CubeGeometry, s, s, s);
      var material = new js.Proxy(THREE.MeshNormalMaterial);
      var o = new js.Proxy(THREE.Mesh, geometry, material);
      o.position.z = 1;
      o.castShadow = true;
      o.receiveShadow = true;
      return js.retain(o);
    });
  }

  EntityProvider4Targetg102() {
    anims["spawn"] = (Animator animator, dynamic obj3d) => Animations.scaleIn(animator, obj3d).then((obj3d) => Animations.rotateXYEndless(animator, obj3d));
    anims["despawnPre"] = Animations.scaleOut;
    anims["none"] = Animations.noop;
  }
}

class EntityProvider4Message extends EntityProvider {
  dynamic obj3dF(){
    //return js.scoped((){
      final THREE = js.context.THREE;
//      var x = js.context.document.createElement("canvas");
//      x.width = 300;
//      x.height = 15;
//      //var x = new CanvasElement(width: 300, height: 15);
//      var xc = x.getContext("2d");
//      xc.fillStyle = "#ffaa00";
//      xc.font = "bold 15px sans-serif";
//      xc.textBaseline = "top";
//      //xc.textAlign = "middle";
//      xc.fillText("+1 azertyui", 0, 0);
      var tx = THREE.ImageUtils.loadTexture("_images/one.png");
      var sm = new js.Proxy(THREE.SpriteMaterial, js.map({
        'map': tx, //new js.Proxy(THREE.Texture, x),
        'useScreenCoordinates': false
        //transparent: true
      }));
      sm.map.needsUpdate = true;
      var o = new js.Proxy(THREE.Sprite, sm);
      //o.position.set(50, 10, 50);
      o.scale.set( 23, 18, 1 );
      o.castShadow = false;
      o.receiveShadow = false;
      return js.retain(o);
    //});
  }
  EntityProvider4Message() {
    //anims["spawn"] = Animations.rotateXYEndless;
    anims["despawn"] = Animations.up;
  }
}

class EntityProvider4MobileWall extends EntityProvider {
  final double x0;
  final double y0;
  final double dx;
  final double dy;
  final double dz;
  final double speedx;
  final double speedy;
  final double duration;
  final bool inout;
  EntityProvider4MobileWall(this.x0, this.y0, this.dx, this.dy, this.dz, this.speedx, this.speedy, this.duration, this.inout);

  Object2D obj2dF(){
    var r = new Object2D();
    r.bdef = new BodyDef();
    r.bdef.type= b2_kinematicBody;
    //TODO optim replace boxes (polyshape) by segment + thick (=> change the display) if w or h is 0
    var shape = new PolygonShape();
    shape.setAsBox(this.dx/2, this.dy/2);
    var f = new FixtureDef();
    f.shape = shape;
    f.filter.groupIndex = EntityTypes_WALL;
    r.fdefs.add(f);
    return r;
  }
  dynamic obj3dF(){
    return js.scoped((){
      var texture = THREE.ImageUtils.loadTexture('_images/mobilewalls.png');
      texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
      texture.repeat.set( 2, 2 );
      material = new js.Proxy(THREE.MeshBasicMaterial, js.map({
        "map" : texture,
        //"blending" : THREE.AdditiveBlending,
        //"color": 0xffffff,
        "transparent": true
      }));
      //var mesh = (new js.Proxy(THREE.Mesh, new js.Proxy(THREE.PlaneGeometry, dx, dy), material);
      var mesh = new js.Proxy(THREE.Mesh, new js.Proxy(THREE.CubeGeometry, dx, dy, dz), material);
      //mesh.position.x = cells[i+0] * cellr + 1 + dx / 2;
      //mesh.position.y = cells[i+1] * cellr + 1 + dy / 2;
      mesh.castShadow = false;
      mesh.receiveShadow = false;
      return mesh;
    });
  }
}
////  # Blenders euler order is 'XYZ', but the equivalent euler rotation order in Three.js is 'ZYX'
//js.Proxy fixOrientation(js.Proxy obj3d){
//  var y2 = obj3d.rotation.z;
//  var z2 = -obj3d.rotation.y;
////    #m.rotation.x = ob.rot[0];
////    #obj3d.rotation.y = y2;
////    #obj3d.rotation.z = z2;
//  obj3d.eulerOrder = "ZYX";
//  obj3d.castShadow = true;
//  obj3d.receiveShadow  = false;
//  return obj3d;
//}

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

class AreaDef {
  EntityProvider walls;
  EntityProvider gateIn;
  EntityProvider gateOut;
  EntityProvider targetg1Spawn;
  List<EntityProvider> mobileWalls;
}

AreaDef makeArea(jsonStr) {
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
        mesh.castShadow = true;
        mesh.receiveShadow = true;
        THREE.GeometryUtils.merge(geometry, mesh);
      }
      var walls = new js.Proxy(THREE.Mesh, geometry, materialW);
      walls.castShadow = true;
      walls.receiveShadow = true;

      //var materialF = new three.MeshLambertMaterial (color : 0xe1d5a5, transparent: false, opacity: 1, vertexColors : three.VertexColors);
      var materialF = new js.Proxy(THREE.MeshPhongMaterial, js.map({"color" : 0xe1d5a5}));
      //var materialF = new js.Proxy(THREE.MeshBasicMaterial, color : 0xe1d5a5, wireframe : false);
      var floor = new js.Proxy(THREE.Mesh, new js.Proxy(THREE.PlaneGeometry, width * cellr, height * cellr), materialF);
      floor.position.x = width * cellr /2;
      floor.position.y = height * cellr /2;
      floor.castShadow = false;
      floor.receiveShadow = true;

      var obj3d = new js.Proxy(THREE.Object3D);
      obj3d.add(walls);
      obj3d.add(floor);
      o = js.retain(obj3d);
    });
    return o;
  }

  Object2D cells2boxes2d(List<num> cells, groupIndex) {
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
      shape.setAsBoxWithCenterAndAngle(hx, hy, new vec2(x, y), 0);
      var f = new FixtureDef();
      f.shape = shape;
      f.filter.groupIndex = groupIndex;
      r.fdefs.add(f);
    }
    return r;
  }

  Object2D cells2circles2d(List<num> cells, double radius, int groupIndex) {
    var r = new Object2D();
    r.bdef = new BodyDef();
    r.fdefs = [];
    for(var i = 0; i < cells.length; i+=4) {
      for (var x = cells[i+0]; x < (cells[i+0] + cells[i+2]); x++) {
        for (var y = cells[i+1]; y < (cells[i+1] + cells[i+3]); y++) {
          var s = new CircleShape();
          s.radius = radius * cellr/2;
          s.position.x = (x + 0.5 ) * cellr;
          s.position.y = (y + 0.5 ) * cellr;
          var f = new FixtureDef();
          f.shape = s;
          f.isSensor = true;
          f.filter.groupIndex = groupIndex;
          r.fdefs.add(f);
        }
      }
    }
    return r;
  }

  void addBorderAsCells(num w, num h, List<num>cells) {
    cells..add(-1)..add(-1)..add(w+2)..add(  1);
    cells..add(-1)..add(-1)..add(  1)..add(h+2);
    cells..add( w)..add(-1)..add(  1)..add(h+2);
    cells..add(-1)..add( h)..add(w+2)..add(  1);
  }

  js.Proxy cells2surface3d(cells, offz, [String imgUrl]) {
    var o;
    js.scoped((){
    final THREE = js.context.THREE;
    var geometry = new js.Proxy(THREE.Geometry );
    //#material = new js.Proxy(THREE.MeshNormalMaterial, )
    var material0 = new js.Proxy(THREE.MeshBasicMaterial, js.map({"color" : 0x000065, "wireframe" : false}));
    var material = material0;
    if (?imgUrl) {
      var texture = THREE.ImageUtils.loadTexture(imgUrl);
      material = new js.Proxy(THREE.MeshBasicMaterial, js.map({
        "map" : texture,
        //"blending" : THREE.AdditiveBlending,
        //"color": 0xffffff,
        "transparent": true
      }));
      //material.map.needsUpdate = true;
    }
    for(var i = 0; i < cells.length; i+=4) {
      var dx = cells[i+2] * cellr - 2;
      var dy = cells[i+3] * cellr - 2;

      var mesh = new js.Proxy(THREE.Mesh, new js.Proxy(THREE.PlaneGeometry, dx, dy), material);
      mesh.position.x = cells[i+0] * cellr + 1 + dx / 2;
      mesh.position.y = cells[i+1] * cellr + 1 + dy / 2;
      mesh.castShadow = false;
      mesh.receiveShadow = true;
      THREE.GeometryUtils.merge(geometry, mesh);
    }
    var obj3d = new js.Proxy(THREE.Mesh, geometry, material);
    obj3d.position.z = offz;
    obj3d.castShadow = false;
    obj3d.receiveShadow = true;

    o = js.retain(obj3d);
    });
    return o;
  }

  addBorderAsCells(area["width"], area["height"], area["walls"]["cells"]);
  var r = new AreaDef();
  r.walls = new EntityProvider4Static(
      cells2boxes2d(area["walls"]["cells"], EntityTypes_WALL),
      cells2boxes3d(area["walls"]["cells"], area["width"], area["height"]),
      area["walls"]["cells"],
      cellr
  );
    //TODO use an animated texture (like wave, http://glsl.heroku.com/e#6603.0)
  r.gateIn = new EntityProvider4Static(
      null,
      cells2surface3d(area["zones"]["gate_in"]["cells"], 0.5, "_images/gate_in.png"),
      area["zones"]["gate_in"]["cells"],
      cellr
  );
  r.gateOut = new EntityProvider4Static(
      cells2circles2d(area["zones"]["gate_out"]["cells"], 0.3, EntityTypes_ITEM),
      cells2surface3d(area["zones"]["gate_out"]["cells"], 0.5, "_images/gate_out.png"),
      area["zones"]["gate_out"]["cells"],
      cellr
  );
  r.targetg1Spawn = new EntityProvider4Static(
      null,
      null,//cells2surface3d(area["zones"]["targetg1_spawn"]["cells"], 0.5),
      area["zones"]["targetg1_spawn"]["cells"],
      cellr
  );
  r.mobileWalls = ((area["zones"]["mobile_walls"] != null) ?
    area["zones"]["mobile_walls"].map((t) => new EntityProvider4MobileWalls(
          t[0] * cellr,
          t[1] * cellr,
          math.max(1, t[2] * cellr),
          math.max(1, t[3] * cellr),
          math.max(2, cellr /2),
          t[4] * cellr,
          t[5] * cellr,
          t[6],
          t[7] == 1
    )).toList(false)
    : new List()
  );
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
    shape.setFrom([new vec2(3, 0), new vec2(-1, 2), new vec2(-1, -2)], 3);
    var f = new FixtureDef();
    f.shape = shape;
    //s.sensor = false;
    f.filter.groupIndex = EntityTypes_DRONE;
    r.fdefs = [f];
    return r;
  }

  js.Proxy obj3dF() {
    _obj3dPattern.position.z = 0.3;
    _obj3dPattern.castShadow = true;
    _obj3dPattern.receiveShadow = true;
    return _obj3dPattern;//.clone();
  }

  EntityProvider4Drone(this._obj3dPattern) {
    anims["spawn"] = Animations.scaleIn;
    anims["despawnPre"] = Animations.scaleOut;
    anims["crash"] = Animations.explodeOut;
    anims["none"] = Animations.noop;
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
      var r = loader.parse(js.map(JSON.parse(jsonStr)), texturePath);
      //var material0 = new js.Proxy(THREE.MeshNormalMaterial);
      //var material = new js.Proxy(THREE.MeshNormalMaterial,  { shading: three.SmoothShading } );
      //geometry.materials[ 0 ].shading = three.FlatShading;
      //var material = new js.Proxy(THREE.MeshFaceMaterial, );
      //var material0 = geometry.materials[0];
      var material0 = r.materials[0];
      //material.transparent = true
      //material = new js.Proxy(THREE.MeshFaceMaterial, materials)
      //TODO should create a new object or at least change the timestamp
      //var material0 = new three.MeshLambertMaterial (color : 0xe7bf90, transparent: false, opacity: 1, vertexColors : three.VertexColors);
      var obj3d = new js.Proxy(THREE.Mesh, r.geometry, material0);
      //obj3d = fixOrientation(obj3d);
      deferred.complete(js.retain(obj3d));
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
  return HttpRequest.request(src, responseType : 'text').then((httpRequest) => httpRequest.responseText);
}

Future<Document> _loadXml(src) {
  return HttpRequest.request(src, responseType : 'document').then((httpRequest) => httpRequest.responseXml);
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

    Future<EntityProvider> r = null;

    switch(kind) {
  //    case 'scene' :
  //      result = result.then(makeScene);
  //      load0(type : PreloadJS.JSON, src: src || '_models/' + id + '.scene.js');
  //      break;
      case 'model' :
        if (id == "message") {
          r = new Future.immediate(new EntityProvider4Message());
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
        return x;
      },
      onError : (err) {
        print("preload $kind $id FAILURE $err");
        throw err;
      }
    );
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
