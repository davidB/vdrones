part of vdrones;


const EntityTypes_WALL =   0x0001;
const EntityTypes_DRONE =  0x0002;
const EntityTypes_BULLET = 0x0004;
const EntityTypes_SHIELD = 0x0008;
const EntityTypes_ITEM =   0x0010;

class System_Physics extends IntervalEntitySystem {
  const int VELOCITY_ITERATIONS = 10;
  const int POSITION_ITERATIONS = 10;
  
  const int CANVAS_WIDTH = 900;
  const int CANVAS_HEIGHT = 600;
  const num _VIEWPORT_SCALE = 2;

  ComponentMapper<Transform> _transformMapper;
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

  void processEntities(ImmutableBag<Entity> entities) {
    updateSpace(entities);
    updateEntities(entities);
    if (_drawDebug) {
      _drawDebugCanvas.context2d.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
      _space.drawDebugData();
    }
  }

  bool checkProcessing() => true;

  void updateSpace(ImmutableBag<Entity> entities){
    //var stepRate = interval; //_adaptative?  _acc / 1000 : (1 / _intervalRate);
    var dt = interval / 1000;

    entities.forEach((entity) {
      var b = _bodyMapper.get(entity).body;
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
      var b = _bodyMapper.get(entity).body;
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
    bd.body = body;
  }

  void removed(Entity entity) {
    var bd = _bodyMapper.get(entity);
    if (bd.body != null) {
      _space.destroyBody(bd.body);
      bd.body = null;
    }
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
      collisionsB.colliders.add(new Collider(entityB, contact.fixtureA.filter.groupIndex));
    }
  }
  void endContact(b2.Contact contact) {
  }
  void preSolve(b2.Contact contact, b2.Manifold oldManifold){
  }
  void postSolve(b2.Contact contact, b2.ContactImpulse impulse) {
  }
}
