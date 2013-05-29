part of vdrones;

const GROUP_CAMERA = "camera";
const GROUP_DRONE = "drone";

const EntityTypes_WALL    = 0x0001;
const EntityTypes_DRONE   = 0x0002;
const EntityTypes_GATEOUT = 0x0004;
const EntityTypes_SHIELD  = 0x0008;
const EntityTypes_ITEM    = 0x0010;

const State_CREATING = 1;
const State_DRIVING = 2;
const State_CRASHING = 3;
const State_EXITING = 4;
const State_RUNNING = 10;

class Factory_Entities {
  static final chronometerCT = ComponentTypeManager.getTypeFor(Chronometer);
  static final transformCT = ComponentTypeManager.getTypeFor(Transform);

  World _world;
  AssetManager _assetManager;

  Factory_Entities(this._world, this._assetManager);

  Entity _newEntity(List<Component> cs, {String group, String player, List<String> groups}) {
    var e = _world.createEntity();
    cs.forEach((c) => e.addComponent(c));
    if (group != null) {
      (_world.getManager(GroupManager) as GroupManager).add(e, group);
    }
    if (groups != null) {
      var gm = (_world.getManager(GroupManager) as GroupManager);
      groups.forEach((group) => gm.add(e, group));
    }
    if (player != null) {
      (_world.getManager(PlayerManager) as PlayerManager).setPlayer(e, player);
    }
    return e;
  }

//  Entity newCube() {
//      anims["spawn"] = (Animator animator, dynamic obj3d) => Animations.scaleIn(animator, obj3d).then((obj3d) => Animations.rotateXYEndless(animator, obj3d));
//      anims["despawnPre"] = Animations.scaleOut;
//      anims["none"] = Animations.noop;
  Entity newCube(x, y) => _newEntity([
    new Transform.w3d(new vec3(x, y, 1)),
    Factory_Physics.newCube(),
    Factory_Renderables.newCube(),
    new Animatable()
      ..add(Factory_Animations.newScaleIn()
        ..next = Factory_Animations.newRotateXYEndless()
      )
      ..add(Factory_Animations.newDelay(5 * 1000)
        ..next = (Factory_Animations.newScaleOut()
          ..onEnd = (e,t,t0) { e.deleteFromWorld() ; }
        )
      )

  ]);

  Entity newCubeGenerator(List<num> rects) => _newEntity([
    new CubeGenerator(rects),
    new Animatable()
  ]);

  Entity newStaticWalls(List<num> rects, num width, num height) => _newEntity([
    new Transform.w2d(0.0, 0.0, 0.0),
    Factory_Physics.newBoxes2d(rects, EntityTypes_WALL),
    Factory_Renderables.newBoxes3d(rects, 2, width, height)
  ]);

  Entity newGateIn(List<num> rects, List<num> rzs, AssetPack assetpack) {
    var points = new List<vec3>();
    for (var i = 0; i < rects.length; i += 4) {
      points.add(new vec3(
        rects[i],
        rects[i+1],
        radians(rzs[i~/4])
      ));
    }
    return  _newEntity([
      new Transform.w3d(new vec3(0, 0, 0.2)),
      //TODO use an animated texture (like wave, http://glsl.heroku.com/e#6603.0)
      Factory_Renderables.newSurface3d(rects, 0.5, assetpack["gate_in"]),
      new Animatable(),
      new DroneGenerator(points, [0])
    ]);
  }

  Entity newGateOut(List<num> rects, AssetPack assetpack) => _newEntity([
    new Transform.w3d(new vec3(0.0, 0.0, 0.2)),
    Factory_Physics.newCircles2d(rects, 0.3, EntityTypes_GATEOUT),
    Factory_Renderables.newSurface3d(rects, 0.5, assetpack["gate_out"])
  ]);

  Entity newMobileWall(num x0, num y0, num dx, num dy, num dz, num tx, num ty, num duration,  bool inout) => _newEntity([
    new Transform.w2d(x0, y0, 0.0),
    Factory_Physics.newMobileWall(dx, dy),
    Factory_Renderables.newMobileWall(dx, dy, dz),
    new Animatable()
      ..add(new Animation()
        ..onTick = (e, t, t0) {
          var trans = e.getComponent(transformCT);
          var ratio =  0;
          if (inout) {
            ratio = (t % (2 * duration));
            if (ratio > duration) {
              ratio = 2 * duration - ratio;
            }
          } else {
            ratio = (t % duration);
          }
          ratio = ratio / duration;
          trans.position3d.x = x0 + tx * ratio;
          trans.position3d.y = y0 + ty * ratio;
          return true;
        }
      )
  ]);


  Entity newArea(String name) => _newEntity([
    new Area(name)
  ]);

  Entity newChronometer(int millis, timeout) => _newEntity([
    new Chronometer(millis),
    new Animatable()
      ..add(new Animation()
        ..onTick = (e, t, t0) {
          e.getComponent(chronometerCT).millis = millis + (t - t0).toInt();
          return (millis >= 0) || (e.getComponent(chronometerCT).millis <= 0);
        }
        ..onEnd = timeout
      )
  ]);

  Entity newCamera(music) => _newEntity([
    new PlayerFollower(new vec3(0, -25, 30)),
    new Transform.w3d(new vec3(0, -25, 30)).lookAt(new vec3(0,0,0)),
    Factory_Renderables.newCamera(),
    new AudioDef()..add(music)..isAudioListener = true
  ], group : GROUP_CAMERA);

  Entity newLight(vec3 pos, vec3 lookAt) => _newEntity([
    new Transform.w3d(pos).lookAt(lookAt),
    Factory_Renderables.newLight()
  ]);

  Entity newAmbientLight(color) => _newEntity([
    new Transform.w3d(new vec3(0.0, 0.0, 10.0)),
    Factory_Renderables.newAmbientLight(color)
  ]);

  List<Entity> newFullArea(AssetPack assetpack, timeout) {
    var area = assetpack["area"];
    var cellr = area["cellr"].toDouble();

    makeBorderAsCells(num w, num h) {
      var cells = new List();
      cells..add(-1)..add(-1)..add(w+2)..add(  1);
      cells..add(-1)..add(-1)..add(  1)..add(h+2);
      cells..add( w)..add(-1)..add(  1)..add(h+2);
      cells..add(-1)..add( h)..add(w+2)..add(  1);
      return cells;
    }
    //print(JSON.stringify(area));
    var walls0 = new List<int>();
    if (area["walls"]["cells"] != null) {
      print("read cells");
      walls0.addAll(area["walls"]["cells"]);
    }
    if (area["walls"]["maze"] != null) {
      walls0.addAll(makeMaze(area["walls"]["maze"][1], area["walls"]["maze"][2], area["walls"]["maze"][3], 0, 0, area["width"], area["height"]));
    }
    var walls = new List<double>();
    walls.addAll(cells_rects(cellr, makeBorderAsCells(area["width"], area["height"]), 0));
    walls.addAll(cells_rects(cellr, walls0));

    var es = new List<Entity>();
    es.add(newCamera("${assetpack.name}.music"));
    var v = area["light_ambient"];
    v = (v == null) ? 0x444444 : v;
    es.add(newAmbientLight(v));
    area["lights_spots"].forEach((i) {
      es.add(newLight(new vec3(i[0]*cellr, i[1]*cellr, i[2]*cellr), new vec3(i[3]*cellr, i[4]*cellr, i[5]*cellr)));
    });
    es.add(newArea(assetpack.name));
    es.add(newChronometer(-60 * 1000, timeout));
    es.add(newStaticWalls(walls, area["width"] * cellr, area["height"] * cellr));
    es.add(newGateIn(cells_rects(cellr, area["zones"]["gate_in"]["cells"]), area["zones"]["gate_in"]["angles"], assetpack));
    es.add(newGateOut(cells_rects(cellr, area["zones"]["gate_out"]["cells"]), assetpack));
    es.add(newCubeGenerator(cells_rects(cellr, area["zones"]["cubes_gen"]["cells"])));
    if (area["zones"]["mobile_walls"] != null) {
      area["zones"]["mobile_walls"].forEach((t) {
        es.add(newMobileWall(
          (t[0] + t[2]/2) * cellr,
          (t[1] + t[3]/2) * cellr,
          math.max(1, t[2] * cellr),
          math.max(1, t[3] * cellr),
          math.max(2, cellr /2),
          t[4] * cellr,
          t[5] * cellr,
          t[6] * 1000,
          t[7] == 1
        ));
      });
    }
    print("nb entities for area : ${es.length}");
    return es;
  }

  Entity newDrone(String player, double x0, double y0, double rz0) {
    var rd = Factory_Renderables.makeModel(_assetManager.root["drone01"], '_models');
    return _newEntity([
        new Transform.w3d(new vec3(x0, y0, 0.3)),
        new DroneNumbers(),
        new EntityStateComponent(State_CREATING, _droneStates(rd))
      ], group : GROUP_DRONE, player : player)
    ;
  }

  _droneStates(RenderableDef c){
    var renderable = new ComponentProvider(RenderableDef, (e) => c);
    var control = new ComponentProvider(DroneControl, (e) => new DroneControl());
    var pbody = new ComponentProvider(PhysicBody, (e) => Factory_Physics.newDrone());
    var pmotion = new ComponentProvider(PhysicMotion, (e) => new PhysicMotion(0.0, 0.0));
    var pcollisions = new ComponentProvider(PhysicCollisions, (e) => new PhysicCollisions());
    var animatable = new ComponentProvider(Animatable, (e) => new Animatable());
    var animatableCreating = new ComponentModifier<Animatable>(Animatable, (a){
      a.add(Factory_Animations.newScaleIn()
        ..onEnd = (e, t, t0) {
          var esc = e.getComponentByClass(EntityStateComponent) as EntityStateComponent;
          esc.state = State_DRIVING;
        }
      )
      ;
    });
    return new Map<int, EntityState>()
      ..[State_CREATING] = (new EntityState()
        ..add(renderable)
        ..add(animatable)
        ..modifiers.add(animatableCreating)
      )
      ..[State_DRIVING] = (new EntityState()
        ..add(renderable)
        ..add(pbody)
        ..add(pmotion)
        ..add(pcollisions)
        ..add(control)
        ..add(animatable)
      )
//      ..[State_CRASHING] = (new EntityState()
//        ..add(renderable)
//        ..add(animatable)
//      )
//      ..[State_EXITING] = (new EntityState()
//        ..add(renderable)
//        ..add(animatable)
//      )
      ;
  }

  Entity newExplosion(Transform t) => _newEntity([
    new Transform.w3d(t.position3d, t.rotation3d), // no need to clone the vec3 of transform
    Factory_Renderables.newExplode(),
    new Animatable()..l.add(
      Factory_Animations.newExplodeOut()
        ..onEnd = (e, t ,t0) { e.deleteFromWorld();}
    ),
    new AudioDef()..add("explosion")
  ]);

  /// convert a list of cells [bottom0, left0, width0, height0, bottom1, left1,...] + cellr into
  /// [centerx0, centery0, halfdx0, halfdy0, centerx1, centery1, ...] in the final unit (renderable + physics)
  /// special rules:
  /// * if width == 0 then halfdx = cellr/20
  /// * if height == 0 then halfdy = cellr/20
  /// * if width > 0 then haldx = width * cellr - 2 * cellr
  /// * if height > 0 then haldy = height * cellr - 2 * cellr
  static List<num> cells_rects(num cellr, List<num> cells, [margin = -1]) {
    margin = (margin < 0) ? cellr/20 : margin;
    var b = new List<num>(cells.length);
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


/*
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
*/


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

var _randomSplitter = new math.Random();
_newWallsSplitter0(int w, int h) {
  if (w < 2 || h < 2) return null;
  var b = new List<int>(3);
  // position of wall (split) along w axis
  b[0] = (w > 2)? 1 + _randomSplitter.nextInt(w - 2) : 1;
  // position of the passage in the wall (or length of the first wall)
  b[1] = _randomSplitter.nextInt(h - 1);
  // length of the passage in the wall
  var rest = h - b[1];
  b[2] = (rest > 1) ? 1 + _randomSplitter.nextInt(rest - 1) : 1;
  return b;
}
_newWallsSplitter1(int x, int y, int w, int h) {
  var b = new List<int>();
  var wsplit = _newWallsSplitter0(w, h);
  if (wsplit != null) {
    if (wsplit[1] > 0) {
      b..add(x + wsplit[0])..add(y)..add(0)..add(wsplit[1]);
    }
    var d = wsplit[1] + wsplit[2];
    if ( d < h) {
      b..add(x + wsplit[0])..add(y + d)..add(0)..add(h-d);
    }
  }
  return b;
}
_newWallsSplitter(bool splitX, int x, int y, int w, int h) {
  var b = null;
  if (splitX) {
    b = _newWallsSplitter1(x, y, w, h);
  } else {
    // swap x/y and w/h, an other alternative : rotate 90deg
    b = _newWallsSplitter1(y, x, h, w);
    var tmp = null;
    for(var i = 0; i < b.length; i = i + 2) {
      tmp = b[i];
      b[i] = b[i+1];
      b[i+1] = tmp;
    }
  }
  return b;
}
makeMaze(int maxdepth, bool splitAlt, bool splitX, int x, int y, int w, int h) {
  if (maxdepth == 0) return [];
  var b = _newWallsSplitter(splitX, x, y, w, h);
  if (!b.isEmpty) {
    var nsplitX = splitAlt ? !splitX : splitX;
    if (splitX) {
      var d = b[0] - x;
      b.addAll(makeMaze((maxdepth - 1), splitAlt, nsplitX, x, y , d, h));
      b.addAll(makeMaze((maxdepth - 1), splitAlt, nsplitX, b[0], y , w - d, h));
    } else {
      var d = b[1] - y;
      b.addAll(makeMaze((maxdepth - 1), splitAlt, nsplitX, x, y , w, d));
      b.addAll(makeMaze((maxdepth - 1), splitAlt, nsplitX, x, b[1] , w, h - d));
    }
  }
  return b;
}
