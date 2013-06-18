part of vdrones;

final vecZ = new Vector3(0.0, 0.0, 1.0);
final vecY = new Vector3(0.0, 1.0, 0.0);

class System_PlayerFollower extends EntityProcessingSystem {
  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<PlayerFollower> _followerMapper;
  PlayerManager _playerManager;
  GroupManager _groupManager;
  Transform _targetTransform = null;
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
          _targetTransform = t;
          _targetUpdated = true;
        }
      }
    });
    return _targetUpdated;
  }

  void processEntity(Entity entity) {
    var follower = _followerMapper.get(entity);
    var t = _transformMapper.get(entity);
    var _targetPosition = _targetTransform.position3d;
    if (follower.rotate) {
      t.angle = _targetTransform.angle;
      //print("----------");
      //var m4 = new Matrix4.zero().translate(_targetPosition);
      var m4 = new Matrix4.translationValues(_targetPosition.x, _targetPosition.y, _targetPosition.z);
      m4.rotateZ(_targetTransform.angle);
      var target = m4.transformed3(follower.targetTranslation);

      //var target = new Vector3(_targetPosition);
      //target.add()
      var damp = world.delta / (1000.0 * 0.25);
      t.position3d.x = approachMulti(target.x, t.position3d.x, damp);
      t.position3d.y = approachMulti(target.y, t.position3d.y, damp);
      t.position3d.z = approachMulti(target.z, t.position3d.z, damp);
      //.getTranslation());//, follower.targetTranslation.y, follower.targetTranslation.z).getTranslation());
      //print(t.position3d);
      //var r3 = new Vector3.copy(t.rotation3d);
      t.lookAt(_targetPosition, vecZ);
      //t.rotation3d.x = approachMulti(t.rotation3d.x, r3.x, 0.03);
      //t.rotation3d.y = approachMulti(t.rotation3d.y, r3.y, 0.03);
      //t.rotation3d.z = approachMulti(t.rotation3d.z, r3.z, 0.03);
      //t.angle = approachMulti(_targetTransform.angle, t.angle, 0.3);
    } else {
      var target = new Vector3.copy(_targetPosition).add(follower.targetTranslation);
      t.position3d.x = approachMulti(target.x, t.position3d.x, 0.2);
      t.position3d.y = approachMulti(target.y, t.position3d.y, 0.2);
      t.position3d.z = approachMulti(target.z, t.position3d.z, 0.3);
      t.lookAt(_targetPosition, vecY);
    }

  }
  double approachAdd(double target, double current, double step) {
    var mstep = target - current;
    return current + math.min(step, mstep);
  }

  double approachMulti(target, current, step) {
    var mstep = target - current;
    return current + step * mstep;
  }
}

class System_CameraController extends EntityProcessingSystem {
  ComponentMapper<PlayerFollower> _followerMapper;
  GroupManager _groupManager;

  System_CameraController() : super(Aspect.getAspectForAllOf([Transform, PlayerFollower]));

  void initialize(){
    _followerMapper = new ComponentMapper<PlayerFollower>(PlayerFollower, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
  }

  void processEntity(Entity entity) {
    if (_groupManager.isInGroup(entity, GROUP_CAMERA)) {
      var follower = _followerMapper.get(entity);
      switch(follower.reqMode) {
        case 1 :
          follower.rotate = false;
          follower.targetTranslation.setValues(0.0, -25.0, 30.0);
          break;
        case 2 :
          follower.rotate = true;
          follower.targetTranslation.setValues(-10.0, 0.0, 2.0);
          break;
        case 3 :
          follower.rotate = true;
          follower.targetTranslation.setValues(-0.01, 0.0, 0.0);
          break;
      }
      follower.reqMode = 0;
    }
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
  ComponentMapper<DroneNumbers> _droneNumbersMapper;
  ComponentMapper<Transform> _transformMapper;
  Factory_Entities _efactory;
  VDrones _game;

  System_DroneHandler(this._efactory, this._game) : super(Aspect.getAspectForAllOf([DroneControl, DroneNumbers, PhysicMotion, PhysicCollisions, EntityStateComponent]));

  void initialize(){
    _droneControlMapper = new ComponentMapper<DroneControl>(DroneControl, world);
    _droneNumbersMapper = new ComponentMapper<DroneNumbers>(DroneNumbers, world);
    _motionMapper = new ComponentMapper<PhysicMotion>(PhysicMotion, world);
    _collisionsMapper = new ComponentMapper<PhysicCollisions>(PhysicCollisions, world);
    _statesMapper = new ComponentMapper<EntityStateComponent>(EntityStateComponent, world);
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
  }

  void processEntity(Entity entity) {
    var esc = _statesMapper.getSafe(entity);
    var collisions = _collisionsMapper.get(entity);
    var numbers = _droneNumbersMapper.get(entity);
    collisions.colliders.iterateAndUpdate((collider){
      switch(collider.group) {
        case EntityTypes_WALL :
          if (numbers.hitLastTime < 1) {
            numbers.hit += 34;
            numbers.hitLastTime = 75;
            if (numbers.hit >= 100) {
              _crash(entity);
            }
          }
          break;
        case EntityTypes_ITEM : _grabCube(entity, collider.e); break;
        case EntityTypes_GATEOUT : _exiting(entity); break;
      }
      return collider;
    });
    if (esc.state == State_DRIVING) {
      var ctrl = _droneControlMapper.get(entity);
      numbers.hitLastTime = math.max(0, --numbers.hitLastTime);
      _updateEnergy(numbers, ctrl);
      var m = _motionMapper.get(entity);
      m.acceleration = ctrl.forward * numbers.acc;
      m.angularVelocity = radians(ctrl.turn * numbers.angularv);
    }
  }

  void _crash(Entity entity) {
    var transform = _transformMapper.get(entity);
    if (transform != null) world.addEntity( _efactory.newExplosion(transform));
    entity.deleteFromWorld();
    // esc.state = State_CRASHING;
  }

  void _exiting(Entity drone) {
    var numbers = _droneNumbersMapper.get(drone);
    _game._stop(true, numbers.score);
  }

  void _updateEnergy(numbers, ctrl) {
    if (numbers.energy <= (numbers.energyMax * 0.05)) {
      print("no enough energy");
      ctrl.forward = 0.0;
      ctrl.turn = 0.0;
    }
    var unit = 0;
    if (ctrl.forward != 0.0) {
      unit -= 2;
    }
//    if (evt.GameStates.shooting.v) {
//      unit -= 7;
//    }
//    if (evt.GameStates.shielding.v) {
//      unit -= 10;
//    }
    if (unit == 0) {
      unit += 3;
    }
    numbers.energy = math.max(0, math.min(numbers.energy + unit, numbers.energyMax));
  }
  void _grabCube(Entity drone, Entity cube) {
//     _entities.find('message').then((x){
//       evt.ObjPop.dispatch(["msg/"+objId, dronePos, x]);
//     });
    cube.deleteFromWorld();
    var numbers = _droneNumbersMapper.get(drone);
    var emax = numbers.energyMax;
    numbers.energy = math.max(numbers.energy + emax / 2, emax).toInt();
    numbers.score = numbers.score + 1;
  }
}

class System_DroneGenerator extends EntityProcessingSystem {
  ComponentMapper<DroneGenerator> _droneGeneratorMapper;
  ComponentMapper<Generated> _genMapper;
  ComponentMapper<Animatable> _animatableMapper;
  ComponentMapper<DroneNumbers> _droneNumbersMapper;
  Factory_Entities _efactory;
  String _player;

  System_DroneGenerator(this._efactory, this._player) : super(Aspect.getAspectForAllOf([DroneGenerator, Animatable]));

  void initialize(){
    _droneGeneratorMapper = new ComponentMapper<DroneGenerator>(DroneGenerator, world);
    _genMapper = new ComponentMapper<Generated>(Generated, world);
    _animatableMapper = new ComponentMapper<Animatable>(Animatable, world);
    _droneNumbersMapper = new ComponentMapper<DroneNumbers>(DroneNumbers, world);
  }

  void processEntity(Entity entity) {
    var gen = _droneGeneratorMapper.get(entity);
    gen.scores.removeWhere((score) {
      var pointsIdx = (gen.nextPointsIdx == -1) ? new math.Random().nextInt(gen.points.length) : gen.nextPointsIdx % gen.points.length;
      var p = gen.points[pointsIdx];
      var e = _efactory.newDrone(_player, p.x, p.y, p.z);
      e.addComponent(new Generated(entity));
      var numbers = _droneNumbersMapper.get(e);
      numbers.score = score;
      numbers.hit = 0;
      world.addEntity(e);
      return true;
    });
  }

  void deleted(Entity e) {
    super.deleted(e);
    var g0 = _genMapper.getSafe(e);
    if (g0 != null) {
      var egenerator = g0.generator;
      var generator = _droneGeneratorMapper.getSafe(egenerator);
      if (generator != null) {
        var score = _droneNumbersMapper.get(e).score;
        var a = _animatableMapper.get(egenerator).l.add(Factory_Animations.newDelay(900)
          ..onEnd = (e0,t,t0) {
            generator.scores.add(score);
            return true;
          }
        );
      }
    }
  }
}

//-- Cubes --------------------------------------------------------------------
class System_CubeGenerator extends EntityProcessingSystem {
  static final _random = new math.Random();

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
    var g0 = _genMapper.getSafe(e);
    if (g0 != null) {
      var egenerator = g0.generator;
      var g = _cubeGeneratorMapper.getSafe(egenerator);
      if (g != null) {
        var a = _animatableMapper.get(egenerator).l.add(Factory_Animations.newDelay(200)
          ..onEnd = (e0,t,t0) {
            g.nb += 1;
          }
        );
      }
    }
  }

  Vector2 _nextPosition(CubeGenerator gen) {
    var offset = gen.subZoneOffset;
    gen.subZoneOffset = (gen.subZoneOffset + 4) % gen.rects.length;
    //1.0 around for wall
    //0.5 half size of generated cube;
    var dx = gen.rects[offset + 2] - 1.5;
    var dy = gen.rects[offset + 3] - 1.5;
    var x = gen.rects[offset + 0] + dx * (_random.nextDouble() * 2 - 1);
    var y = gen.rects[offset + 1] + dy * (_random.nextDouble() * 2 - 1);
    return new Vector2(x, y);
  }

}

