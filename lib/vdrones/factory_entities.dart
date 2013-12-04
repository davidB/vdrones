part of vdrones;

const GROUP_DRONE = "drone";

const EntityTypes_WALL    = 0x0001;
const EntityTypes_DRONE   = 0x0002;
const EntityTypes_GATEOUT = 0x0004;
const EntityTypes_SHIELD  = 0x0008;
const EntityTypes_ITEM    = 0x0010;
const EntityTypes_MWALL    = 0x0011;

const State_CREATING = 1;
const State_DRIVING = 2;
const State_CRASHING = 3;
const State_EXITING = 4;
const State_WAITING = 5;
const State_GRABBING = 6;
const State_RUNNING = 10;

var foregroundcolor = 0xe3e3f8ff;
var foregroundcolors = hsl_tetrad(irgba_hsl(foregroundcolor)).map((hsl) => irgba_rgbaString(hsl_irgba(hsl))).toList();
var foregroundcolorsM = hsv_monochromatic(irgba_hsv(foregroundcolor), 4).map((hsv) => irgba_rgbaString(hsv_irgba(hsv))).toList(); //monochromatique


class Factory_Entities {
  final Factory_Physics physicFact;
  final Factory_Renderables renderFact;

  World _world;
  AssetManager _assetManager;

  Factory_Entities(
    this._world,
    this._assetManager,
    this.physicFact,
    this.renderFact
  );

  var defaultDraw = proto2d.drawComponentType([
    new proto2d.DrawComponentType(Particles.CT, proto2d.particles(5.0, fillStyle : foregroundcolors[0], strokeStyle : foregroundcolors[1], radiusMin: 2.0)),
    new proto2d.DrawComponentType(Segments.CT, proto2d.segments(distanceStyleCollide : "#e20000"))
  ]);

  Entity _newEntity(List<Component> cs, {String group, String player, List<String> groups}) {
    addComponents(cs, e) {
      cs.forEach((c){
        if (c is List) addComponents(c, e);
        else {
          if (c is Particles && c.extradata is ColliderInfo) c.extradata.e = e;
          e.addComponent(c);
        }
      });
    }
    var e = _world.createEntity();
    addComponents(cs, e);
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

  var setAnimations = (l) => new ComponentModifier<Animatable>(Animatable, (e, a){
    a.cleanUp();
    a.addAll(l);
  });

  Entity newCube() => _newEntity([
    new proto2d.Drawable(defaultDraw),
    physicFact.newCube(),
    renderFact.newCube(_assetManager['0.cube_material']),
    new Attraction(),
    new Animatable(),
    new EntityStateComponent(State_CREATING, _cubeStates())
  ]);

  _cubeStates(){
    return new Map<int, EntityState>()
      ..[State_CREATING] = (new EntityState()
        ..modifiers.add(setAnimations([
          Factory_Animations.newScaleIn()
            ..onEnd = ((e,t, t0) => EntityStateComponent.change(e, State_WAITING))
        ]))
      )
      ..[State_WAITING] = (new EntityState()
        ..modifiers.add(setAnimations([
          Factory_Animations.newRotateXYEndless(),
          Factory_Animations.newDelay(5 * 1000)
            ..onEnd = (e,t, t0) => EntityStateComponent.change(e, State_EXITING)
        ]))
      )
     ..[State_EXITING] = (new EntityState()
       ..modifiers.add(setAnimations([
         Factory_Animations.newScaleOut()
         ..onEnd = (e,t,t0) { e.deleteFromWorld() ; }
       ]))
     )
     ..[State_GRABBING] = (new EntityState()
       ..modifiers.add(new ComponentModifier<Particles>(Particles, (e, a){
         a.extradata = null; // no more collisions
         a.collide[0] = 0;
       }))
       ..modifiers.add(setAnimations([
         Factory_Animations.newCubeAttraction()
         ..onEnd = (e,t,t0) { e.deleteFromWorld() ; }
       ]))
     )
     ;
  }

  Entity newCubeGenerator(CubeGen x) => _newEntity([
    new CubeGenerator(x.subZones),
    new Animatable()
  ]);

  Entity newStaticWalls(StaticWall x, AssetPack assetpack) => _newEntity([
    new proto2d.Drawable(defaultDraw),
    //new Transform.w2d(0.0, 0.0, 0.0),
    physicFact.newPolygones(x.shapes, EntityTypes_WALL),
    renderFact.newPolygonesExtrudesZ(x.shapes, 5.0, assetpack["wall_material"], x.color, includeFloor: true)
  ]);

  Entity newFloor() => _newEntity([
    renderFact.newFloor()
  ]);

  Entity newGateIns(Iterable<GateIn> x, AssetPack assetpack) {
    return  _newEntity([
      new Transform.w3d(new Vector3(0.0, 0.0, 0.2)),
      //TODO use an animated texture (like wave, http://glsl.heroku.com/e#6603.0)
//      renderFact.newEllipses3d(x.map((x) => x.ellipse), _assetManager['0.gate_in_material'],_assetManager['0.gate_in_map']),
      new Animatable(),
      new DroneGenerator(x, [0])
    ]);
  }

  Entity newGateOuts(Iterable<GateOut> x, AssetPack assetpack) => _newEntity([
    new proto2d.Drawable(defaultDraw),
    physicFact.newCircles2d(x.map((x) => x.ellipse), 0.3, EntityTypes_GATEOUT),
//    renderFact.newEllipses3d(x.map((x) => x.ellipse), _assetManager['0.gate_out_material'],_assetManager['0.gate_out_map'])
  ]);

  Entity newMobileWall(MobileWall x, AssetPack assetpack) => _newEntity([
    new proto2d.Drawable(defaultDraw),
    physicFact.newPolygones(x.shapes, EntityTypes_WALL),
    renderFact.newPolygonesExtrudesZ(x.shapes, 4.0, assetpack["mwall_material"], x.color, isMobile: true),
//    renderFact.newMobileWall(x.shapes, 4.0, x.color),
    new Animatable()
      ..add(new Animation()
        ..onTick = (e, t, t0) {
          var anim = x.animation;
          var ratio =  0;
          if (anim.pingpong) {
            ratio = (t % (2 * anim.duration));
            if (ratio > anim.duration) {
              ratio = 2 * anim.duration - ratio;
            }
          } else {
            ratio = (t % anim.duration);
          }
          ratio = ratio / anim.duration;
          var ps = e.getComponent(Particles.CT);
          var p0 = x.shapes.first.points.first;
          var pc = ps.position3d[0];
          var d = new Vector3(
            (p0.x - pc.x) + anim.deplacement.x * ratio,
            (p0.y - pc.y) + anim.deplacement.y * ratio,
            0.0//(pc.y - p0.z) + anim.deplacement.z * ratio
          );
          for (var i = 0; i < ps.length; i++) {
            ps.position3d[i].add(d);
          }
//          ps.copyPosition3dIntoPrevious();
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
          e.getComponent(Chronometer.CT).millis = millis + (t - t0).toInt();
          return (millis >= 0) || (e.getComponent(Chronometer.CT).millis <= 0);
        }
        ..onEnd = timeout
      )
  ]);

  Entity newCamera(music, sceneAabb) => _newEntity([
    renderFact.newCamera(sceneAabb),
    new AudioDef()..add(music)..isAudioListener = true
  ]);

 List<Entity> newFullArea(AssetPack assetpack, timeout) {
    var areadef = assetpack['area'];

    var es = new List<Entity>();
    es.add(newCamera("${assetpack.name}.music", areadef.aabb3));
//    es.add(newAmbientLight(areadef.ambient));
//    area["lights_spots"].forEach((i) {
//      es.add(newLight(new Vector3(i[0]*cellr, i[1]*cellr, i[2]*cellr), new Vector3(i[3]*cellr, i[4]*cellr, i[5]*cellr)));
//    });
    es.add(newArea(assetpack.name));
    es.add(newChronometer(areadef.chronometer, timeout));
    es.add(newGateIns(areadef.gateIns, assetpack));
    es.add(newGateOuts(areadef.gateOuts, assetpack));
    es.add(newFloor());
    es.addAll(areadef.staticWalls.map((x) => newStaticWalls(x, assetpack)));
    es.addAll(areadef.mobileWalls.map((x) => newMobileWall(x, assetpack)));
    es.addAll(areadef.cubeGenerators.map((x) => newCubeGenerator(x)));
//    print("DEBUG: areadef.mobileWalls : ${areadef.mobileWalls.length}");
//    print("DEBUG: nb entities for area : ${es.length}");
    return es;
  }

  Entity newDrone(String player) {
    var l0 = physicFact.newDrone();
    return _newEntity([
        new proto2d.Drawable(defaultDraw),
        new DroneNumbers(),
        renderFact.newDrone(_assetManager['0.default_material'], _assetManager['0.dissolve_map']),
        new Animatable(),
        new EntityStateComponent(State_CREATING, _droneStates())
      ]..addAll(l0)
      , group : GROUP_DRONE
      , player : player
    );
  }

  _droneStates(){
    var control = new ComponentProvider(DroneControl, (e) => new DroneControl());
    return new Map<int, EntityState>()
      ..[State_CREATING] = (new EntityState()
        ..modifiers.add(setAnimations([
          Factory_Animations.newScaleIn()
          ..onEnd = (e,t, t0) => EntityStateComponent.change(e, State_DRIVING)
        ]))
      )
      ..[State_DRIVING] = (new EntityState()
        ..add(control)
      )
     ..[State_CRASHING] = (new EntityState()
       ..add(new ComponentProvider(Dissolvable, (e) => new Dissolvable()))
       ..modifiers.add(setAnimations([
         Factory_Animations.newDissolve()
         ..onEnd = (e,t,t0) { e.deleteFromWorld() ; }
       ]))
     )
     ..[State_EXITING] = (new EntityState()
       ..modifiers.add(setAnimations([
         Factory_Animations.newScaleOut()
         ..onEnd = (e,t,t0) { e.deleteFromWorld() ; }
       ]))
     )
      ;
  }

  /// convert a list of cells [bottom0, left0, width0, height0, bottom1, left1,...] + cellr into
  /// [centerx0, centery0, halfdx0, halfdy0, centerx1, centery1, ...] in the final unit (renderable + physics)
  /// special rules:
  /// * if width == 0 then halfdx = cellr/20
  /// * if height == 0 then halfdy = cellr/20
  /// * if width > 0 then haldx = width * cellr - 2 * cellr
  /// * if height > 0 then haldy = height * cellr - 2 * cellr
  static List<double> cells_rects(num cellr, List<num> cells, [margin = -1.0]) {
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



//Future<String> _loadTxt(src) {
//  return HttpRequest.request(src, responseType : 'text').then((httpRequest) => httpRequest.responseText);
//}
//
//Future<Document> _loadXml(src) {
//  return HttpRequest.request(src, responseType : 'document').then((httpRequest) => httpRequest.responseXml);
//}
//
//
//Future<ImageElement> _loadImage(src) {
//  var completer = new Completer<ImageElement>();
//  ImageElement image = new ImageElement();
//  image.onLoad.listen(
//    (event) {
//      completer.complete(image);
//    },
//    onError : (err) {
//      completer.completeError(err.error, err.stackTrace);
//    }
//  );
//  image.src = src;
//  return completer.future;
//}

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
