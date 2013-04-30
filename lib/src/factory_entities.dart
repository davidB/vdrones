part of vdrones;

const GROUP_CAMERA = "camera";
const GROUP_DRONE = "drone";
const GROUP_AUDIOLISTENER = "audiolistener";

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

  Entity newCubeGenerator(num cellr, List<num> cells) => _newEntity([
    new CubeGenerator(cellr, cells),
    new Animatable()
  ]);

  Entity newStaticWalls(num cellr, List<num> cells, num width, num height) => _newEntity([
    new Transform.w2d(0, 0, 0),
    Factory_Physics.cells2boxes2d(cellr, cells, EntityTypes_WALL),
    Factory_Renderables.cells2boxes3d(cellr, cells, width, height)
  ]);

  Entity newGateIn(num cellr, List<num> cells, List<num> rzs, AssetPack assetpack) {
    var points = new List<vec3>();
    for (var i = 0; i < cells.length; i += 4) {
      points.add(new vec3(
        (cells[i] + cells[i+2] / 2) * cellr,
        (cells[i+1] + cells[i+3] / 2) * cellr,
        radians(rzs[i~/4])
      ));
    }
    return  _newEntity([
      new Transform.w3d(new vec3(0, 0, 0.2)),
      //TODO use an animated texture (like wave, http://glsl.heroku.com/e#6603.0)
      Factory_Renderables.cells2surface3d(cellr, cells, 0.5, assetpack["gate_in"]),
      new Animatable(),
      new DroneGenerator(points, [0])
    ]);
  }

  Entity newGateOut(num cellr, List<num> cells, AssetPack assetpack) => _newEntity([
    new Transform.w3d(new vec3(0, 0, 0.2)),
    Factory_Physics.cells2circles2d(cellr, cells, 0.3, EntityTypes_GATEOUT),
    Factory_Renderables.cells2surface3d(cellr, cells, 0.5, assetpack["gate_out"])
  ]);

  Entity newMobileWall(num x0, num y0, num dx, num dy, num dz, num tx, num ty, num duration,  bool inout) => _newEntity([
    new Transform.w2d(x0, y0, 0),
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
    new AudioDef()..add(music)
  ], groups : [GROUP_CAMERA, GROUP_AUDIOLISTENER]);

  Entity newLight() => _newEntity([
    new Transform.w3d(new vec3(40, 40, 100)).lookAt(new vec3(90, 90, 0)),
    Factory_Renderables.newLight()
  ]);

  Entity newAmbientLight() => _newEntity([
    new Transform.w2d(0, 0, 0),
    Factory_Renderables.newAmbientLight()
  ]);

  List<Entity> newFullArea(AssetPack assetpack, timeout) {
    var area = assetpack["area"];
    var cellr = area["cellr"].toDouble();

    void addBorderAsCells(num w, num h, List<num>cells) {
      cells..add(-1)..add(-1)..add(w+2)..add(  1);
      cells..add(-1)..add(-1)..add(  1)..add(h+2);
      cells..add( w)..add(-1)..add(  1)..add(h+2);
      cells..add(-1)..add( h)..add(w+2)..add(  1);
    }
    //print(JSON.stringify(area));
    addBorderAsCells(area["width"], area["height"], area["walls"]["cells"]);
    var es = new List<Entity>();
    es.add(newCamera("${assetpack.name}.music"));
    es.add(newAmbientLight());
    es.add(newLight());
    es.add(newArea(assetpack.name));
    es.add(newChronometer(-60 * 1000, timeout));
    es.add(newStaticWalls(cellr, area["walls"]["cells"], area["width"], area["height"]));
    es.add(newGateIn(cellr, area["zones"]["gate_in"]["cells"], area["zones"]["gate_in"]["angles"], assetpack));
    es.add(newGateOut(cellr, area["zones"]["gate_out"]["cells"], assetpack));
    es.add(newCubeGenerator(cellr, area["zones"]["cubes_gen"]["cells"]));
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


