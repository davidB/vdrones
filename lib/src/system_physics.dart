part of vdrones;

// -- Components --------------------------------------------------------------

class PhysicBody implements Component {
  b2.BodyDef bdef;
  List<b2.FixtureDef> fdefs;

  PhysicBody._();
  static _ctor() => new PhysicBody._();
  factory PhysicBody(b2.BodyDef b, List<b2.FixtureDef> f) {
    var c = new Component(PhysicBody, _ctor);
    c.bdef = b;
    c.fdefs = f;
    return c;
  }
}

// cache of the body (only used by System_Physics)
class PhysicBodyCache implements Component {
  b2.Body body;

  PhysicBodyCache._();
  static _ctor() => new PhysicBodyCache._();
  factory PhysicBodyCache(b2.Body b) {
    var c = new Component(PhysicBodyCache, _ctor);
    c.body = b;
    return c;
  }
}

class PhysicMotion implements Component {
  /// unit per second
  num acceleration;
  /// radians per second
  num angularVelocity;

  PhysicMotion._();
  static _ctor() => new PhysicMotion._();
  factory PhysicMotion(acc, av) {
    var c = new Component(PhysicMotion, _ctor);
    c.acceleration = acc;
    c.angularVelocity = av;
    return c;
  }
}

class Collider {
  Entity e;
  // the collision groupId
  int group; //HACK quick to know the entity kind
  Collider(this.e, this.group);
}

class PhysicCollisions implements Component {
  final colliders = new List<Collider>();

  PhysicCollisions._();
  static _ctor() => new PhysicCollisions._();
  factory PhysicCollisions() {
    var c = new Component(PhysicCollisions, _ctor);
    c.colliders.clear();
    return c;
  }
}

// -- Systems -----------------------------------------------------------------

class System_Physics extends IntervalEntitySystem {
  static const int VELOCITY_ITERATIONS = 10;
  static const int POSITION_ITERATIONS = 10;

  static const int CANVAS_WIDTH = 900;
  static const int CANVAS_HEIGHT = 600;
  static const num _VIEWPORT_SCALE = 2;

  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<PhysicBodyCache> _bodyCacheMapper;
  ComponentMapper<PhysicBody> _bodyMapper;
  ComponentMapper<PhysicMotion> _motionMapper;

  b2.World _space;
  var _drawDebug = false;
  var _drawDebugCanvas;
  static final vzero = new vec2.zero();

  System_Physics(bool drawDebug) : super(1000.0/30, Aspect.getAspectForAllOf([Transform, PhysicBody])) {
    _drawDebug = !drawDebug; //toggle while be done during initialize()
  }

  void initialize() {
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _bodyMapper = new ComponentMapper<PhysicBody>(PhysicBody, world);
    _bodyCacheMapper = new ComponentMapper<PhysicBodyCache>(PhysicBodyCache, world);
    _motionMapper = new ComponentMapper<PhysicMotion>(PhysicMotion, world);
    _space = _initSpace();
    drawDebug = !_drawDebug; //toggle need an initialized _space
  }

  b2.World _initSpace() {
    var space = new b2.World(vzero, true, new b2.DefaultWorldPool());
    space.autoClearForces = true;
    space.contactListener = new _EntityContactListener(new ComponentMapper<PhysicCollisions>(PhysicCollisions, world));
    return space;
  }

  // true => Have the world draw itself for debugging purposes.
  set drawDebug(bool v) {
    if (_drawDebug == v) return;

    // Setup the canvas.
    if (v) {
      // Create our canvas drawing tool to give to the world.
      _drawDebugCanvas = new CanvasElement(width : CANVAS_WIDTH, height : CANVAS_HEIGHT);
      _drawDebugCanvas.style.zIndex = "1000";
      window.document.query("#layers").children.add(_drawDebugCanvas);
      // Create the viewport transform with the center at extents.
      final extents = new vec2(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);
      var viewport = new b2.CanvasViewportTransform(extents, extents);
      viewport.scale = _VIEWPORT_SCALE;
      _space.debugDraw = new b2.CanvasDraw(viewport, _drawDebugCanvas.context2d);
    } else {
      _space.debugDraw = null;
      if (_drawDebugCanvas != null) {
        _drawDebugCanvas.remove();
        _drawDebugCanvas = null;
      }
    }

    _drawDebug = v;
    print("Draw Debug physics : ${_drawDebug}");
  }

  void processEntities(ReadOnlyBag<Entity> entities) {
    updateSpace(entities);
    updateEntities(entities);
    if (_drawDebug) {
      _drawDebugCanvas.context2d.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
      _space.drawDebugData();
    }
  }

  void updateSpace(ReadOnlyBag<Entity> entities){
    //var stepRate = interval; //_adaptative?  _acc / 1000 : (1 / _intervalRate);
    var dt = delta / 1000;

    entities.forEach((entity) {
      var bc = _bodyCacheMapper.getSafe(entity);
      assert(bc != null);
      var b = bc.body;
      if (b.type == b2.BodyType.STATIC) return;
      var m = _motionMapper.getSafe(entity);
      if (m != null) {
        //b.active = true;
        //b.awake = true;
        if (m.acceleration != 0) {
          var force = m.acceleration * dt;
          var acc = new vec2(math.cos(b.angle) * force, math.sin(b.angle)* force);
          b.applyForce(acc, vzero);
        }
        if (b.angularVelocity != m.angularVelocity) {
          b.angularVelocity = m.angularVelocity; //radians per second
        }
      } else {
        // transform is managed by an other system but physic 'space should be updated
        var p = _transformMapper.get(entity);
        b.setTransform(p.position, p.angle);
      }
    });

    _space.step(dt, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
  }

  void updateEntities(entities){
    entities.forEach((entity) {
      var bc = _bodyCacheMapper.getSafe(entity);
      if (bc == null) return;
      var b = bc.body;
      if (b.type == b2.BodyType.STATIC) return;
      var p = _transformMapper.get(entity);
      p.position = b.position;
      p.angle = b.angle;
    });
  }

  void inserted(Entity entity) {
    var bd = _bodyMapper.get(entity);
    var p = _transformMapper.get(entity);
    bd.bdef.userData = entity; //{ var id = id; var boost = false; };
    var body = _space.createBody(bd.bdef);
    body.setTransform(p.position, p.angle);
    bd.fdefs.forEach((fd) {
      body.createFixture(fd);
    });
    entity.addComponent(new PhysicBodyCache(body));
    entity.changedInWorld();
  }

  //TODO find a quicker way to remove body from space than browse every body
  void removed(Entity entity) {
    var bc = _bodyCacheMapper.getSafe(entity);
    if (bc == null) return;
    var b = bc.body;
    if (b != null) {
      _space.destroyBody(b);
      bc.body = null;
    }
    entity.removeComponent(PhysicBodyCache);
  }
}

class _EntityContactListener extends b2.ContactListener {
  ComponentMapper<PhysicCollisions> _collisionsMapper;

  _EntityContactListener(this._collisionsMapper);

  void beginContact(b2.Contact contact) {
    //print("beginContact ${contact.fixtureA.filter.groupIndex} // ${contact.fixtureB.filter.groupIndex}");
    //HACK should not occur
    if (contact.fixtureA.filter.groupIndex == contact.fixtureB.filter.groupIndex) return;
    var entityA = contact.fixtureA.body.userData as Entity;
    var entityB = contact.fixtureB.body.userData as Entity;
    var collisionsA = _collisionsMapper.getSafe(entityA);
    if (collisionsA != null) {
      collisionsA.colliders.add(new Collider(entityB, contact.fixtureB.filter.groupIndex));
    }
    var collisionsB = _collisionsMapper.getSafe(entityB);
    if (collisionsB != null) {
      collisionsB.colliders.add(new Collider(entityA, contact.fixtureA.filter.groupIndex));
    }
  }
  void endContact(b2.Contact contact) {
    if (contact.fixtureA.filter.groupIndex == contact.fixtureB.filter.groupIndex) return;
    var entityA = contact.fixtureA.body.userData as Entity;
    var entityB = contact.fixtureB.body.userData as Entity;
    var collisionsA = _collisionsMapper.getSafe(entityA);
    if (collisionsA != null) {
      collisionsA.colliders.removeWhere((x) => x.e == entityB);
    }
    var collisionsB = _collisionsMapper.getSafe(entityB);
    if (collisionsB != null) {
      collisionsB.colliders.removeWhere((x) => x.e == entityA);
    }
  }
  void preSolve(b2.Contact contact, b2.Manifold oldManifold){
  }
  void postSolve(b2.Contact contact, b2.ContactImpulse impulse) {
  }
}
