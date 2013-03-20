part of vdrones;

class UserData {
  String id;
  num boost = 0;

  UserData(this.id);
}

class MyContactListener extends ContactListener {
  final droneItem = new List();
  final droneWall = new List();

  void beginContact(Contact contact) {
    print("beginContact ${contact.fixtureA.filter.groupIndex} // ${contact.fixtureB.filter.groupIndex}");
    if (contact.fixtureA.filter.groupIndex == contact.fixtureB.filter.groupIndex) return;
    var d = null;
    var i = null;
    var w = null;
    switch(contact.fixtureA.filter.groupIndex) {
      case EntityTypes.DRONE :
        d = contact.fixtureA.body.userData.id;
        break;
      case EntityTypes.ITEM :
        i = contact.fixtureA.body.userData.id;
        break;
      case EntityTypes.WALL :
        w = contact.fixtureA.body.userData.id;
        break;
    }
    switch(contact.fixtureB.filter.groupIndex) {
      case EntityTypes.DRONE :
        d = contact.fixtureB.body.userData.id;
        break;
      case EntityTypes.ITEM :
        i = contact.fixtureB.body.userData.id;
        break;
      case EntityTypes.WALL :
        w = contact.fixtureB.body.userData.id;
        break;
    }
    if (d != null && i != null) {
      droneItem.add(d);
      droneItem.add(i);
    } else if (d != null && w != null) {
      droneWall.add(d);
      droneWall.add(w);
    }

  }
  void endContact(Contact contact) {
  }
  void preSolve(Contact contact, Manifold oldManifold){
  }
  void postSolve(Contact contact, ContactImpulse impulse) {
  }
}

void setupPhysics(Evt evt, [drawDebug = false]) {

  const DEG_TO_RADIAN = 0.0174532925199432957;
  const int VELOCITY_ITERATIONS = 10;
  const int POSITION_ITERATIONS = 10;

  const int CANVAS_WIDTH = 900;
  const int CANVAS_HEIGHT = 600;
  const num _VIEWPORT_SCALE = 2;

  //_radToDeg = 57.295779513082320876
  const _adaptative = false;
  const _intervalRate = 60;

  var _id2body = new Map<String, Body>();
  final vzero = new vec2.zero();

  World _space = null;
  var _ctx;
  num _lastTimestamp = 0;
  var _running = false;
  var _contactListener = new MyContactListener();


  World initSpace() {
    var space = new World(vzero, true, new DefaultWorldPool());
    //space.damping = 0.3;

//    begin(List arr){
//      return (arb, space) {
//        var shapes = arb.getShapes();
//        arr.add(shapes);
//        return false;
//      };
//    }

    //space.addCollisionHandler(EntityTypes.DRONE, EntityTypes.ITEM, begin(_contactDroneItem), null, null, null);
    //space.addCollisionHandler(EntityTypes.DRONE, EntityTypes.WALL, begin(_contactDroneWall), null, null, null);
    space.contactListener = _contactListener;

// Setup the canvas.
    if (drawDebug) {
      var canvas = new Element.tag('canvas');
      canvas.width = CANVAS_WIDTH;
      canvas.height = CANVAS_HEIGHT;
      window.document.query("#layers").children.add(canvas);
      _ctx = canvas.getContext("2d");

      // Create the viewport transform with the center at extents.
      final extents = new vec2(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);
      var viewport = new CanvasViewportTransform(extents, extents);
      viewport.scale = _VIEWPORT_SCALE;

      // Create our canvas drawing tool to give to the world.
      var debugDraw = new CanvasDraw(viewport, _ctx);

      // Have the world draw itself for debugging purposes.
      space.debugDraw = debugDraw;
    }


    return space;
  }

  dynamic forBody(String id, dynamic f(Body x1, UserData x2)){
    var back = null;
    var b = _id2body[id];
    if (b != null) {
      var ud = b.userData;
      back = f(b, ud);
//    } else {
//      console.warn("body not found : ", id);
    }
    return back;
  }

  void despawn(String id, options) {
    forBody(id, (b, u){
      _space.destroyBody(b);
      _id2body.remove(id);
    });
  }

  void update(num t){
    var stepRate = _adaptative?  (t - _lastTimestamp) / 1000 : (1 / _intervalRate);

    _space.clearForces();
    _id2body.values.forEach((b) {
      if (b != null && b.userData != null) {
        var ud = b.userData;
        var dt = (1 / stepRate);
        if (ud.boost != 0) {
          var force = ud.boost * dt;
          var acc = new vec2(math.cos(b.angle) * force, math.sin(b.angle)* force);
          b.applyForce(acc, vzero);
        }
      }
    });

    _space.step(stepRate, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
    _lastTimestamp = t;
    if (drawDebug) {
      _ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
      _space.drawDebugData();
    }
  }

  num pushStates(){
    for(var i = _contactListener.droneItem.length - 1; i > 0; i -= 2) {
      evt.ContactBeginDroneItem.dispatch([_contactListener.droneItem[i - 1], _contactListener.droneItem[i]]);
    }
    _contactListener.droneItem.clear();
    for(var i = _contactListener.droneWall.length - 1; i > 0; i -= 2) {
      evt.ContactBeginDroneWall.dispatch([_contactListener.droneWall[i - 1], _contactListener.droneWall[i]]);
    }
    _contactListener.droneWall.clear();

    var ct = 0;
    _id2body.values.forEach((b) {
      if (b != null && b.userData != null) {
        var ud = b.userData;
        evt.ObjMoveTo.dispatch([ud.id, new Position(b.position.x, b.position.y, b.angle)]);
        ct++;
      }
    });
    return ct;
  }

  void setBoost(String droneId, num state) {
    forBody(droneId, (b, ud){
      //#_space.activateBody(b) # or b.active() ?
      b.active = true;
      ud.boost = state;
    });
  }


//  void setAngle(String objId, num a) {
//    forBody(objId, (b, ud){
//      b.angularVelocity = 0;
//      b.setTransform(b.position, a); //TODO rotate until raise the target angle instead of switch
//    });
//  }

  void setRotation(String objId, num angVel) {
    forBody(objId, (b, ud){
      // should take care of dampling (=> * 3)
      b.active = true;
      b.angularVelocity = 180 * angVel * DEG_TO_RADIAN * 3; //90 deg per second
    });
  }

//    impulseObj = (objId, a, force) ->
//      forBody(objId, (b, ud) ->
//        impulse = cp.v(Math.cos(a) * force, Math.sin(a) * force)
//        b.applyImpulse(impulse, cp.vzero)
//      )

//  void drawBody(Body body) {
//    var obj3d = new three.Object3D();
//    obj3d.position.z = 0.1; //#for Z != 0 une an ortho camera
//    for (var f = body.fixtureList; f != null; f = f.next) {
//      var shape2d = f.shape;
//      var geometry = null;
//      if (shape2d is PolygonShape) {
//        var path = new three.Path();
//        var verts = shape2d.vertices;
//        path.moveTo( verts[0].x, verts[0].x);
//        for(var i1 = 1; i1 < verts.length; i1 += 1 ) {
//          var i2 = i1 % verts.length;
//          path.lineTo( verts[i2].x, verts[i2].y);
//        }
//        geometry = path.createPointsGeometry();
//      } else if (shape2d is CircleShape) {
//        geometry = new three.CircleGeometry(shape2d.radius);
//      }
//    //      rectShape.multilineTo( rectLength/2, -rectLength/2 )
//    //rectShape.lineTo( -rectLength/2,      -rectLength/2 )
//      if (geometry != null) {
//        //var mesh = three.SceneUtils.createMultiMaterialObject( geometry, [ new three.MeshLambertMaterial( color: 0xff0000, opacity: 0.2, transparent: true ), new three.MeshBasicMaterial( color: 0x000000, wireframe: true,  opacity: 0.3 ) ] );
//        var m0 = new three.MeshLambertMaterial( color: 0xff0000, opacity: 0.2, transparent: true );
//        var m1 = new three.MeshBasicMaterial( color: 0x000000, wireframe: true,  opacity: 0.3 );
//        var mesh = new three.Mesh( geometry, m0);
//        obj3d.add(mesh);
//      }
//    }
//    //_pending.push(evt.SpawnObj(body.data.id+ '/debug/chipmun/boundingbox', (() -> Position(body.p.x, body.p.y, body.p.a)), obj3d))
//    evt.ObjSpawn.dispatch(["${body.userData.id}>debug-physics", Position.zero, new EntityProvider4Static(null, obj3d, null, 0)]);
//  }

  void spawnObj(String id, Position pos, EntityProvider gpof) {
    //return if !gpof.obj2dF?
    var obj2d = gpof.obj2dF();
    if (obj2d == null) {
      return;
    }
    obj2d.bdef.userData = new UserData(id); //{ var id = id; var boost = false; };
    var body = _space.createBody(obj2d.bdef);
    _id2body[id] = body;
    body.setTransform(new vec2(pos.x, pos.y), pos.a);
    obj2d.fdefs.forEach((fd) {
      body.createFixture(fd);
    });
    body.type = BodyType.DYNAMIC;
    //drawBody(body);
  }

  void spawnArea(String id, Position pos, EntityProvider gpof) {
    //return if !gpof.obj2dF?
    var obj2d = gpof.obj2dF();
    if (obj2d == null) {
      return;
    }
    obj2d.bdef.userData = new UserData(id); //{ var id = id; var boost = false; };
    var body = _space.createBody(obj2d.bdef);
    _id2body[id] = body;
    body.setTransform(new vec2(pos.x, pos.y), pos.a);
    obj2d.fdefs.forEach((fd) {
      body.createFixture(fd);
    });
    body.type = BodyType.STATIC;
    //drawBody(body);
  }

//  void spawnArea(String id, Position pos, EntityProvider gpof){
//    var obj2d = gpof.obj2dF();
//    obj2d.body.setPos(cp.v(pos.x, pos.y));
//    obj2d.body.setAngle(pos.a);
//    _space.staticBody = obj2d.body;
//    var body = _space.staticBody;
//    body.data = new UserData(id); //#{ var id = id; var boost = false; };
//    obj2d.shapes.forEach((shape) {
//      _space.addStaticShape(shape);
//    });
//    _id2body[id] = body;
//    drawBody(body);
//  }

  String newId(String base){
    return "${base}${new DateTime.now().millisecondsSinceEpoch}";
  }

  evt.GameStart.add((){
    _space = initSpace();
    _running = true;
  });
  evt.GameStop.add((_) {
    _running = false;
  });
  evt.AreaSpawn.add(spawnArea);
  evt.BoostShipStart.add((objId){
    setBoost(objId, 5.0);
  });
  evt.BoostShipStop.add((objId){
    setBoost(objId, 0);
  });
  evt.RotateShipStart.add(setRotation);
  evt.RotateShipStop.add((objId){
    setRotation(objId, 0);
  });
  evt.ObjSpawn.add(spawnObj);
  evt.ObjDespawn.add(despawn);
  evt.Tick.add((t, delta500){
    if (_running) {
        update(t);
        pushStates();
        //evt.Render.dispatch(null); // if hasChanges > 0
    }
  });
}

