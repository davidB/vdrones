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
  static final chronometerCT = ComponentTypeManager.getTypeFor(Chronometer);
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
    new proto2d.DrawComponentType(Particles.CT, proto2d.particles(5.0, fillStyle : foregroundcolors[0], strokeStyle : foregroundcolors[1])),
    new proto2d.DrawComponentType(Constraints.CT, proto2d.constraints(distanceStyleCollide : "#e20000"))
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

  Entity newCubeGenerator(List<num> rects) => _newEntity([
    new CubeGenerator(rects),
    new Animatable()
  ]);

  Entity newStaticWalls(List<num> rects, num width, num height, AssetPack assetpack) => _newEntity([
    new proto2d.Drawable(defaultDraw),
    new Transform.w2d(0.0, 0.0, 0.0),
    physicFact.newBoxes2d(rects, EntityTypes_WALL),
    renderFact.newBoxes3d(rects, 2.0, width, height, assetpack["wall_material"])
  ]);

  Entity newGateIn(List<num> rects, List<num> rzs, AssetPack assetpack) {
    var points = new List<Vector3>();
    for (var i = 0; i < rects.length; i += 4) {
      points.add(new Vector3(
        rects[i],
        rects[i+1],
        radians(rzs[i~/4])
      ));
    }
    return  _newEntity([
      new Transform.w3d(new Vector3(0.0, 0.0, 0.2)),
      //TODO use an animated texture (like wave, http://glsl.heroku.com/e#6603.0)
      renderFact.newSurface3d(rects, 0.5, _assetManager['0.gate_in_material'],_assetManager['0.gate_in_map']),
      new Animatable(),
      new DroneGenerator(points, [0])
    ]);
  }

  Entity newGateOut(List<num> rects, AssetPack assetpack) => _newEntity([
    new proto2d.Drawable(defaultDraw),
    physicFact.newCircles2d(rects, 0.3, EntityTypes_GATEOUT),
    renderFact.newSurface3d(rects, 0.1, _assetManager['0.gate_out_material'],_assetManager['0.gate_out_map'])
  ]);

  Entity newMobileWall(double x0, double y0, double dx, double dy, double dz, num tx, num ty, num duration,  bool inout, AssetPack assetpack) => _newEntity([
    //new Transform.w2d(x0, y0, 0.0),
        new proto2d.Drawable(defaultDraw),
    physicFact.newMobileWall(x0, y0, dx, dy, EntityTypes_MWALL),
    renderFact.newMobileWall(dx, dy, dz, assetpack["mwall_material"]),
    new Animatable()
      ..add(new Animation()
        ..onTick = (e, t, t0) {
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
//          var trans = e.getComponent(Transform.CT);
//          trans.position3d.x = x0 + tx * ratio;
//          trans.position3d.y = y0 + ty * ratio;
          var x = x0 + tx * ratio;
          var y = y0 + ty * ratio;
          //print("$t => $x $y");
          var ps = e.getComponent(Particles.CT);
//          ps.copyPosition3dIntoPrevious();
          ps.position3d[0].setValues(x, y, 0.0);
          ps.position3d[1].setValues(x-dx, y-dy, 0.0);
          ps.position3d[2].setValues(x+dx, y-dy, 0.0);
          ps.position3d[3].setValues(x+dx, y+dy, 0.0);
          ps.position3d[4].setValues(x-dx, y+dy, 0.0);
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

  Entity newCamera(music, sceneAabb) => _newEntity([
    renderFact.newCamera(sceneAabb),
    new AudioDef()..add(music)..isAudioListener = true
  ]);

  Entity newLight(Vector3 pos, Vector3 lookAt) => _newEntity([
    new Transform.w3d(pos).lookAt(lookAt),
    renderFact.newLight()
  ]);

  Entity newAmbientLight(color) => _newEntity([
    new Transform.w3d(new Vector3(0.0, 0.0, 10.0)),
    renderFact.newAmbientLight(color)
  ]);

  List<Entity> newFullArea(AssetPack assetpack, timeout) {
    var area = assetpack['area'];
    var cellr = area['cellr'].toDouble();
    var width = area['width'];
    var height = area['height'];

    makeBorderAsCells(num w, num h) {
      var cells = new List<num>();
      cells..add(-1)..add(-1)..add(w+2)..add(  1);
      cells..add(-1)..add(-1)..add(  1)..add(h+2);
      cells..add( w)..add(-1)..add(  1)..add(h+2);
      cells..add(-1)..add( h)..add(w+2)..add(  1);
      return cells;
    }
    var walls0 = new List<int>();
    if (area["walls"]["cells"] != null) {
      print("read cells");
      walls0.addAll(area["walls"]["cells"]);
    }
    if (area["walls"]["maze"] != null) {
      walls0.addAll(makeMaze(area["walls"]["maze"][1], area["walls"]["maze"][2], area["walls"]["maze"][3], 0, 0, width, height));
    }
    var walls = new List<double>();
    walls.addAll(cells_rects(cellr, makeBorderAsCells(width, height), 0));
    walls.addAll(cells_rects(cellr, walls0));

    var es = new List<Entity>();
    es.add(newCamera("${assetpack.name}.music", new Aabb3.minmax(new Vector3(-0.1, -0.1, -0.1), new Vector3(width * cellr + 0.1, height * cellr + 0.1, 2.0 * cellr +0.1))));
    var v = area["light_ambient"];
    v = (v == null) ? 0x444444 : v;
    es.add(newAmbientLight(v));
    area["lights_spots"].forEach((i) {
      es.add(newLight(new Vector3(i[0]*cellr, i[1]*cellr, i[2]*cellr), new Vector3(i[3]*cellr, i[4]*cellr, i[5]*cellr)));
    });
    es.add(newArea(assetpack.name));
    es.add(newChronometer(-60 * 1000, timeout));
    es.add(newStaticWalls(walls, width * cellr, height * cellr, assetpack));
    es.add(newGateIn(cells_rects(cellr, area["zones"]["gate_in"]["cells"], 2.0), area["zones"]["gate_in"]["angles"], assetpack));
    es.add(newGateOut(cells_rects(cellr, area["zones"]["gate_out"]["cells"], 1.0), assetpack));
    es.add(newCubeGenerator(cells_rects(cellr, area["zones"]["cubes_gen"]["cells"])));
    if (area["zones"]["mobile_walls"] != null) {
      area["zones"]["mobile_walls"].forEach((t) {
        es.add(newMobileWall(
          (t[0] + t[2] * 0.5) * cellr,
          (t[1] + t[3] * 0.5) * cellr,
          math.max(1.0, t[2] * 0.5 * cellr),
          math.max(1.0, t[3] * 0.5 * cellr),
          math.max(2.0, 1.0  * 0.3  * cellr),
          t[4] * cellr,
          t[5] * cellr,
          t[6] * 1000,
          t[7] == 1,
          assetpack
        ));
      });
    }
    print("nb entities for area : ${es.length}");
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
