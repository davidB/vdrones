part of vdrones;

class System_PlayerFollower extends EntityProcessingSystem {
  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<PlayerFollower> _followerMapper;
  PlayerManager _playerManager;
  GroupManager _groupManager;
  vec3 _targetPosition = new vec3.zero();
  bool _targetUpdated = true;
  String playerToFollow;

  System_PlayerFollower() : super(Aspect.getAspectForAllOf([Transform, PlayerFollower]));

  void initialize(){
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _followerMapper = new ComponentMapper<PlayerFollower>(PlayerFollower, world);
    _playerManager = world.getManager(PlayerManager) as PlayerManager;
    _groupManager = world.getManager(GroupManager) as GroupManager;
  }

  bool checkProcessing() {
    //TODO optim : test if update of target should be move to added(e) + changed(e) + deleted(e) ??
    //TODO optim : set the id of the entity to follow ?
    _targetUpdated = false;
    _playerManager.getEntitiesOfPlayer(playerToFollow).forEach((entity){
      if (_groupManager.isInGroup(entity, GROUP_DRONE)) {
        var t = _transformMapper.getSafe(entity);
        if (t != null) {
          _targetPosition = t.position3d;
          _targetUpdated = true;
        }
      }
    });
    return _targetUpdated;
  }

  void processEntity(Entity entity) {
    var follower = _followerMapper.get(entity);
    var t = _transformMapper.get(entity);
    t.position3d.copyFrom(_targetPosition).add(follower.targetTranslation);
    t.lookAt(_targetPosition);
  }
}

class System_DroneController extends EntityProcessingSystem {
  ComponentMapper<DroneControl> _droneControlMapper;
  DroneControl _state;
  var _subUp, _subDown;

  System_DroneController() : super(Aspect.getAspectForAllOf([DroneControl]));

  void initialize(){
    _droneControlMapper = new ComponentMapper<DroneControl>(DroneControl, world);
    _state = new DroneControl();
    _bindKeyboardControl();
  }

  void processEntity(Entity entity) {
    var dest = _droneControlMapper.get(entity);
    dest.forward = _state.forward;
    dest.turn = _state.turn;
  }

  void _bindKeyboardControl(){
    _subDown = document.onKeyDown.listen((KeyboardEvent e) {
      if (_keysForward.contains(e.keyCode)) _state.forward = 1.0;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 1.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = -1.0;
    });
    _subUp = document.onKeyUp.listen((KeyboardEvent e) {
      if (_keysForward.contains(e.keyCode)) _state.forward = 0.0;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 0.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = 0.0;
    });
  }

  var _keysForward = [ KeyCode.UP, KeyCode.DOWN, KeyCode.W, KeyCode.Z ];
  var _keysTurnLeft = [ KeyCode.LEFT, KeyCode.A, KeyCode.Q ];
  var _keysTurnRight = [KeyCode.RIGHT, KeyCode.D];
  //var _keysShoot = [KeyCode.SPACE];

}

class System_DroneHandler extends EntityProcessingSystem {
  ComponentMapper<PhysicMotion> _motionMapper;
  ComponentMapper<DroneControl> _droneControlMapper;
  ComponentMapper<PhysicCollisions> _collisionsMapper;
  ComponentMapper<EntityStateComponent> _statesMapper;
  ComponentMapper<Generated> _genMapper;
  ComponentMapper<DroneGenerator> _droneGenMapper;
  ComponentMapper<Transform> _transformMapper;
  Factory_Entities _efactory;

  System_DroneHandler(this._efactory) : super(Aspect.getAspectForAllOf([DroneControl, PhysicMotion, PhysicCollisions, EntityStateComponent]));

  void initialize(){
    _droneControlMapper = new ComponentMapper<DroneControl>(DroneControl, world);
    _motionMapper = new ComponentMapper<PhysicMotion>(PhysicMotion, world);
    _collisionsMapper = new ComponentMapper<PhysicCollisions>(PhysicCollisions, world);
    _statesMapper = new ComponentMapper<EntityStateComponent>(EntityStateComponent, world);
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
  }

  void processEntity(Entity entity) {
    var esc = _statesMapper.getSafe(entity);
    var collisions = _collisionsMapper.get(entity);
    collisions.colliders.forEach((collider){
      switch(collider.group) {
        case  EntityTypes_WALL : _crash(entity); break;
        case EntityTypes_ITEM : _grabCube(entity, collider.e); break;
      }
    });
    if (esc.state == State_DRIVING) {
      var ctrl = _droneControlMapper.get(entity);
      var m = _motionMapper.get(entity);
      m.acceleration = ctrl.forward * 5500.0;
      m.angularVelocity = radians(ctrl.turn * 110.0);
    }
  }

  void _crash(Entity entity) {
    var transform = _transformMapper.get(entity);
    if (transform != null) world.addEntity( _efactory.newExplosion(transform));
    entity.deleteFromWorld();
    // esc.state = State_CRASHING;
  }

  void _grabCube(Entity drone, Entity cube) {
     //var emax = evt.GameStates.energyMax.v;
     //evt.GameStates.energy.v = math.max(evt.GameStates.energy.v + emax /2, emax);
     //evt.GameStates.score.v = evt.GameStates.score.v + 1;
//     _entities.find('message').then((x){
//       evt.ObjPop.dispatch(["msg/"+objId, dronePos, x]);
//     });
    print("hit cube");
    cube.deleteFromWorld();
  }
}

class System_DroneGenerator extends EntityProcessingSystem {
  ComponentMapper<DroneGenerator> _droneGeneratorMapper;
  ComponentMapper<Generated> _genMapper;
  ComponentMapper<Animatable> _animatableMapper;
  Factory_Entities _efactory;
  String _player;

  System_DroneGenerator(this._efactory, this._player) : super(Aspect.getAspectForAllOf([DroneGenerator, Animatable]));

  void initialize(){
    _droneGeneratorMapper = new ComponentMapper<DroneGenerator>(DroneGenerator, world);
    _genMapper = new ComponentMapper<Generated>(Generated, world);
    _animatableMapper = new ComponentMapper<Animatable>(Animatable, world);
  }

  void processEntity(Entity entity) {
    var gen = _droneGeneratorMapper.get(entity);
    for(var i = gen.nb; i > 0; i--) {
      var pointsIdx = (gen.nextPointsIdx == -1) ? new math.Random().nextInt(gen.points.length) : gen.nextPointsIdx % gen.points.length;
      var p = gen.points[pointsIdx];
      _efactory.newDrone(_player, p.x, p.y, p.z).then((e){
        e.addComponent(new Generated(entity));
        world.addEntity(e);
      });
    }
    gen.nb = 0;
  }

  void deleted(Entity e) {
    super.deleted(e);
    var g0 = _genMapper.get(e);
    if (g0 != null) {
      var generator = g0.generator;
      var a = _animatableMapper.get(generator).l.add(Factory_Animations.newDelay(900)
        ..onEnd = (e0,t,t0) {
          var g = _droneGeneratorMapper.get(e0);
          if (g != null ) g.nb += 1;
        }
      );
    }
  }
}

//-- Cubes --------------------------------------------------------------------
class System_CubeGenerator extends EntityProcessingSystem {
  static final _random = new math.Random();
  static num random(min, max) => _random.nextDouble() * (max - min) + min;

  ComponentMapper<CubeGenerator> _cubeGeneratorMapper;
  ComponentMapper<Generated> _genMapper;
  ComponentMapper<Animatable> _animatableMapper;
  Factory_Entities _efactory;

  System_CubeGenerator(this._efactory) : super(Aspect.getAspectForAllOf([CubeGenerator, Animatable]));

  void initialize(){
    _cubeGeneratorMapper = new ComponentMapper<CubeGenerator>(CubeGenerator, world);
    _genMapper = new ComponentMapper<Generated>(Generated, world);
    _animatableMapper = new ComponentMapper<Animatable>(Animatable, world);
  }

  void processEntity(Entity entity) {
    var gen = _cubeGeneratorMapper.get(entity);
    for(var i = gen.nb; i > 0; i--) {
      var p = _nextPosition(gen);
      var e = _efactory.newCube(p.x, p.y);
      e.addComponent(new Generated(entity));
      world.addEntity(e);
    }
    gen.nb = 0;
  }

  void deleted(Entity e) {
    super.deleted(e);
    var g0 = _genMapper.get(e);
    if (g0 != null) {
      var generator = g0.generator;
      var a = _animatableMapper.get(generator).l.add(Factory_Animations.newDelay(200)
        ..onEnd = (e0,t,t0) {
          var g = _cubeGeneratorMapper.get(e0);
          if (g != null ) g.nb += 1;
        }
      );
    }
  }

  vec2 _nextPosition(CubeGenerator gen) {
    var offset = gen.subZoneOffset;
    gen.subZoneOffset = (gen.subZoneOffset + 4) % gen.cells.length;
    //1.0 around for wall
    //0.5 half size of generated cube;
    var xmin = gen.cells[offset + 0] * gen.cellr + 1 + 0.5;
    var xmax = xmin + gen.cells[offset + 2] * gen.cellr - 2 - 0.5;
    var ymin = gen.cells[offset + 1] * gen.cellr + 1 + 0.5;
    var ymax = ymin + gen.cells[offset + 3] * gen.cellr - 2 - 0.5;

    var x = random(xmin, xmax);
    var y = random(ymin, ymax);
    return new vec2(x, y);
  }
  
}

