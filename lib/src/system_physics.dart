part of vdrones;
//
//// -- Components --------------------------------------------------------------
//
//class PhysicBody extends Component {
//  b2.BodyDef bdef;
//  List<b2.FixtureDef> fdefs;
//
//  PhysicBody(this.bdef, this.fdefs);
//}
//
//// cache of the body (only used by System_Physics)
//class PhysicBodyCache extends Component {
//  b2.Body body;
//
//  PhysicBodyCache(this.body);
//}
//
//class PhysicMotion extends Component {
//  /// unit per second
//  num acceleration;
//  /// radians per second
//  num angularVelocity;
//
//  PhysicMotion(this.acceleration, this.angularVelocity);
//}
//
class ColliderInfo {
  Entity e;
  // the collision groupId
  int group; //HACK quick to know the entity kind
}

class Collisions extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Collisions);
  final colliders = new LinkedBag<ColliderInfo>();
}
//
//// -- Systems -----------------------------------------------------------------
//
//class System_Physics extends IntervalEntitySystem {
//  static const int VELOCITY_ITERATIONS = 10;
//  static const int POSITION_ITERATIONS = 10;
//
//  static const int CANVAS_WIDTH = 900;
//  static const int CANVAS_HEIGHT = 600;
//  static const num _VIEWPORT_SCALE = 2;
//
//  ComponentMapper<Transform> _transformMapper;
//  ComponentMapper<PhysicBodyCache> _bodyCacheMapper;
//  ComponentMapper<PhysicBody> _bodyMapper;
//  ComponentMapper<PhysicMotion> _motionMapper;
//
//  b2.World _space;
//  b2.Vector v2tmp = new b2.Vector(0.0, 0.0);
//  var _drawDebug = false;
//  var _drawDebugCanvas;
//  static final vzero = new b2.Vector(0.0, 0.0);
//
//  System_Physics(bool drawDebug) : super(1000.0/30, Aspect.getAspectForAllOf([Transform, PhysicBody])) {
//    _drawDebug = !drawDebug; //toggle while be done during initialize()
//  }
//
//  void initialize() {
//    _transformMapper = new ComponentMapper<Transform>(Transform, world);
//    _bodyMapper = new ComponentMapper<PhysicBody>(PhysicBody, world);
//    _bodyCacheMapper = new ComponentMapper<PhysicBodyCache>(PhysicBodyCache, world);
//    _motionMapper = new ComponentMapper<PhysicMotion>(PhysicMotion, world);
//    _space = _initSpace();
//    drawDebug = !_drawDebug; //toggle need an initialized _space
//  }
//
//  b2.World _initSpace() {
//    var space = new b2.World(vzero, true, new b2.DefaultWorldPool());
//    space.autoClearForces = true;
//    space.contactListener = new _EntityContactListener(new ComponentMapper<PhysicCollisions>(PhysicCollisions, world));
//    return space;
//  }
//
//  // true => Have the world draw itself for debugging purposes.
//  set drawDebug(bool v) {
//    if (_drawDebug == v) return;
//
//    // Setup the canvas.
//    if (v) {
//      // Create our canvas drawing tool to give to the world.
//      _drawDebugCanvas = new CanvasElement(width : CANVAS_WIDTH, height : CANVAS_HEIGHT);
//      _drawDebugCanvas.style.zIndex = "1000";
//      window.document.query("#layers").children.add(_drawDebugCanvas);
//      // Create the viewport transform with the center at extents.
//      final extents = new b2.Vector(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);
//      var viewport = new b2.CanvasViewportTransform(extents, extents);
//      viewport.scale = _VIEWPORT_SCALE;
//      _space.debugDraw = new b2.CanvasDraw(viewport, _drawDebugCanvas.context2d);
//    } else {
//      _space.debugDraw = null;
//      if (_drawDebugCanvas != null) {
//        _drawDebugCanvas.remove();
//        _drawDebugCanvas = null;
//      }
//    }
//
//    _drawDebug = v;
//    print("Draw Debug physics : ${_drawDebug}");
//  }
//
//  void processEntities(ReadOnlyBag<Entity> entities) {
//    updateSpace(entities);
//    updateEntities(entities);
//    if (_drawDebug) {
//      _drawDebugCanvas.context2d.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
//      _space.drawDebugData();
//    }
//  }
//
//  void updateSpace(ReadOnlyBag<Entity> entities){
//    //var stepRate = interval; //_adaptative?  _acc / 1000 : (1 / _intervalRate);
//    var dt = delta / 1000;
//
//    entities.forEach((entity) {
//      var bc = _bodyCacheMapper.getSafe(entity);
//      assert(bc != null);
//      var b = bc.body;
//      if (b.type == b2.BodyType.STATIC) return;
//      var m = _motionMapper.getSafe(entity);
//      if (m != null) {
//        //b.active = true;
//        //b.awake = true;
//        if (m.acceleration != 0) {
//          var force = m.acceleration * dt;
//          var acc = new b2.Vector(math.cos(b.angle) * force, math.sin(b.angle)* force);
//          b.applyForce(acc, vzero);
//        }
//        if (b.angularVelocity != m.angularVelocity) {
//          b.angularVelocity = m.angularVelocity; //radians per second
//        }
//      } else {
//        // transform is managed by an other system but physic 'space should be updated
//        _setTransform(entity, b);
//      }
//    });
//
//    _space.step(dt, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
//  }
//
//  void updateEntities(entities){
//    entities.forEach((entity) {
//      var bc = _bodyCacheMapper.getSafe(entity);
//      if (bc == null) return;
//      var b = bc.body;
//      if (b.type == b2.BodyType.STATIC) return;
//      var p = _transformMapper.get(entity);
//      p.position3d.x = b.position.x;
//      p.position3d.y = b.position.y;
//      p.angle = b.angle;
//    });
//  }
//
//  void inserted(Entity entity) {
//    var bd = _bodyMapper.get(entity);
//    bd.bdef.userData = entity; //{ var id = id; var boost = false; };
//    var body = _space.createBody(bd.bdef);
//    _setTransform(entity, body);
//    bd.fdefs.forEach((fd) {
//      body.createFixture(fd);
//    });
//    entity.addComponent(new PhysicBodyCache(body));
//    entity.changedInWorld();
//  }
//
//  void _setTransform(entity, body) {
//    var p = _transformMapper.get(entity);
//    v2tmp.x = p.position3d.x;
//    v2tmp.y = p.position3d.y;
//    body.setTransform(v2tmp, p.angle);
//  }
//
//  //TODO find a quicker way to remove body from space than browse every body
//  void removed(Entity entity) {
//    var bc = _bodyCacheMapper.getSafe(entity);
//    if (bc == null) return;
//    var b = bc.body;
//    if (b != null) {
//      _space.destroyBody(b);
//      bc.body = null;
//    }
//    entity.removeComponent(PhysicBodyCache);
//  }
//}
//
class _EntityContactListener extends collisions.Resolver {
  ComponentMapper<Collisions> _collisionsMapper;

  _EntityContactListener(this._collisionsMapper);

  void notifyCollisionParticleSegment(Particles psA, int iA, Segment s, double tcoll){
    notifyCollision(psA.extradata, s.ps.extradata);
  }

  void notifyCollisionParticleParticle(Particles psA, int iA, Particles psB, int iB, double tcoll){
    notifyCollision(psA.extradata, psB.extradata);
  }

  void notifyCollision(ColliderInfo cA, ColliderInfo cB) {
    if (cA == null || cB == null) return;
    //if (contact.fixtureA.filter.groupIndex == contact.fixtureB.filter.groupIndex) return;
    _addCollisionOnce(cA, cB);
    _addCollisionOnce(cB, cA);
  }

  void _addCollisionOnce(ColliderInfo cA, ColliderInfo cB) {
    var collisionsA = _collisionsMapper.getSafe(cA.e);
    if (collisionsA != null) {
      var already = false;
      collisionsA.colliders.iterateAndUpdate((x){
        if (x.e == cB.e) already = true;
        return x;
      });
      if (!already){
        collisionsA.colliders.add(cB);
      }
    }
  }
}
