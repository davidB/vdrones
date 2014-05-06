part of vdrones;

var _keysForward = [ KeyCode.UP, KeyCode.W, KeyCode.Z ];
var _keysBackward = [ KeyCode.DOWN, KeyCode.S];
var _keysTurnLeft = [ KeyCode.LEFT, KeyCode.A, KeyCode.Q ];
var _keysTurnRight = [KeyCode.RIGHT, KeyCode.D];
var _keysCameraMode = [KeyCode.M];
var _keysPrintDebugInfo = [KeyCode.P];

class System_CameraFollower extends EntityProcessingSystem {
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<CameraFollower> _followerMapper;
  PlayerManager _playerManager;
  GroupManager _groupManager;
  Particles _targetParticles = null;
  bool _targetUpdated = true;
  String playerToFollow;
  collisions.Space collSpace;
  final _int = new math2.IntersectionFinderXY();
  final Vector4 _scol = new Vector4.zero();
  var _toggleMode = false;

  System_CameraFollower() : super(Aspect.getAspectForAllOf([CameraFollower]));

  void initialize(){
    _followerMapper = new ComponentMapper<CameraFollower>(CameraFollower, world);
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _playerManager = world.getManager(PlayerManager) as PlayerManager;
    _groupManager = world.getManager(GroupManager) as GroupManager;
    _bindKeyboardControl();
  }

  bool checkProcessing() {
    //TODO optim : test if update of target should be move to added(e) + changed(e) + deleted(e) ??
    //TODO optim : set the id of the entity to follow ?
    _targetUpdated = false;
    _playerManager.getEntitiesOfPlayer(playerToFollow).forEach((entity){
      if (_groupManager.isInGroup(entity, GROUP_DRONE)) {
        var t = _particlesMapper.getSafe(entity);
        if (t != null) {
          _targetParticles = t;
          _targetUpdated = true;
        }
      }
    });
    return _targetUpdated;
  }

  void processEntities(Iterable<Entity> entities) => entities.forEach((entity) => processEntity(entity));

  void processEntity(Entity entity) {
    var follower = _followerMapper.get(entity);
    if (follower.info == null) return;
    if (_toggleMode) {
      _toggleMode = false;
      follower.mode = (follower.mode == CameraFollower.TOP) ? CameraFollower.TPS : CameraFollower.TOP;
    }
    var _targetPosition = _targetParticles.position3d[DRONE_PCENTER];
    var camera = follower.info;
    if (follower.mode == CameraFollower.TOP) {
      var next = new Vector3.copy(_targetPosition).add(follower.targetTranslation);
      var position = camera.position;
      position.x = approachMulti(next.x, position.x, 0.2);
      position.y = approachMulti(next.y, position.y, 0.2);
      position.z = approachMulti(next.z, position.z, 0.3);
      camera.upDirection.setFrom(math2.VY_AXIS);
      camera.focusPosition.setFrom(_targetPosition);
    } else {
      var _targetDirection = _targetParticles.position3d[DRONE_PFRONT] - _targetParticles.position3d[DRONE_PCENTER];
      _targetDirection.z = 0.0;
      _targetDirection.normalize();
      var next = new Vector3.copy(_targetDirection).scale(follower.targetTranslation.x).add(_targetPosition);
      var d = _findFirstIntersection(_targetPosition, next);
      if (d >= 0.0 && d <= 1.0) {
        // next = _targetPosition + d * displacement
        next.setFrom(_targetDirection).scale(follower.targetTranslation.x * d).add(_targetPosition);
        next.z = _targetPosition.z + follower.targetTranslation.z * d;
      } else {
        next.z = _targetPosition.z + follower.targetTranslation.z;
      }
      var damp = world.delta / 250.0; //100 ms to reach 1.0
      var position = camera.position;
      position.x = approachMulti(next.x, position.x, damp);
      position.y = approachMulti(next.y, position.y, damp);
      position.z = approachMulti(next.z, position.z, damp);
      position = camera.focusPosition;
      position.x = approachMulti(_targetPosition.x + 4 * _targetDirection.x, position.x, damp);
      position.y = approachMulti(_targetPosition.y + 4 * _targetDirection.y, position.y, damp);
      //TODO optimize could be done once when mode change
      position.z = 3.0;
      camera.upDirection.setFrom(math2.VZ_AXIS);
      camera.near = 0.001;
      camera.far = 200.0;//(follower.focusAabb.max - follower.focusAabb.min).length;
    }
    //follower.info.updateProjectionMatrix();
    //camera.adjustNearFar(follower.focusAabb, 0.001, 0.1);
    camera.updateViewMatrix();
  }

  double approachAdd(double target, double current, double step) {
    var mstep = target - current;
    return current + math.min(step, mstep);
  }

  double approachMulti(double target, double current, double step) {
    var mstep = target - current;
    return current + step * mstep;
  }

  double _findFirstIntersection(Vector3 v0, Vector3 v1){
    var b = -1.0;
    collSpace.scanNear(v0, v1, (s) {
      if (s.ps == _targetParticles) return;
      if (_int.segment_segment(v0, v1, s.ps.position3d[s.i1], s.ps.position3d[s.i2], _scol)) {
        var b0 = _scol.w;
        if (b0 >= 0.0 && b0 <= 1.0 && (b == -1.0 || b0 < b)) {
          b = b0;
        }
      }
    });
    return b;
  }

  void _bindKeyboardControl(){
    document.onKeyUp.listen((KeyboardEvent e) {
      if (_keysCameraMode.contains(e.keyCode)) _toggleMode = true;
    });
    var btn = querySelector("#toggleCameraMode");
    if (btn != null) {
      btn.onClick.listen((e){
        _toggleMode = true;
      });
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
      else if (_keysBackward.contains(e.keyCode)) _state.forward = -0.3;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 1.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = -1.0;
    });
    _subUp = document.onKeyUp.listen((KeyboardEvent e) {
      if (_keysForward.contains(e.keyCode)) _state.forward = 0.0;
      else if (_keysBackward.contains(e.keyCode)) _state.forward = 0.0;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 0.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = 0.0;
    });
  }
}

class System_DroneHandler extends EntityProcessingSystem {
  //ComponentMapper<PhysicMotion> _motionMapper;
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<DroneControl> _droneControlMapper;
  ComponentMapper<Forces> _forcesMapper;
  ComponentMapper<Collisions> _collisionsMapper;
  ComponentMapper<EntityStateComponent> _statesMapper;
  ComponentMapper<Generated> _genMapper;
  ComponentMapper<DroneNumbers> _droneNumbersMapper;
  VDrones _game;
  var _printDebug = false;

  System_DroneHandler(this._game) : super(Aspect.getAspectForAllOf([DroneControl, DroneNumbers, Particles/*PhysicMotion, PhysicCollisions*/, EntityStateComponent]));

  void initialize(){
    _droneControlMapper = new ComponentMapper<DroneControl>(DroneControl, world);
    _forcesMapper = new ComponentMapper<Forces>(Forces, world);
    _droneNumbersMapper = new ComponentMapper<DroneNumbers>(DroneNumbers, world);
    _collisionsMapper = new ComponentMapper<Collisions>(Collisions, world);
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _statesMapper = new ComponentMapper<EntityStateComponent>(EntityStateComponent, world);
    _bindKeyboardControl();
  }

  void processEntity(Entity entity) {
    var esc = _statesMapper.getSafe(entity);
    var collisions = _collisionsMapper.get(entity);
    var numbers = _droneNumbersMapper.get(entity);
    var stop = false;
    var tcoll = 1.0;
    collisions.colliders.iterateAndUpdate((collider){
      switch(collider.group) {
        case EntityTypes_WALL :
          print("DEBUG: frame #${_game._gameLoop.frame} ${_game._gameLoop.frameTime} : hit wall");
          if (numbers.hitLastTime < 1) {
            numbers.hit += 34;
            numbers.hitLastTime = 75;
            if (numbers.hit >= 100) {
              _crash(entity);
            }
          }
          tcoll = collider.tcoll;
          stop = true;
          break;
        case EntityTypes_MWALL : _crash(entity); break;
        case EntityTypes_ITEM : _grabCube(entity, collider.e); break;
        case EntityTypes_GATEOUT : _exiting(entity); break;
      }
      return null;
    });
    if (esc.currentState == State_DRIVING) {
      numbers.hitLastTime = math.max(0, --numbers.hitLastTime);
      var ctrl = _droneControlMapper.get(entity);
      var fs = _forcesMapper.get(entity);
      var ps = _particlesMapper.get(entity);
      if (_printDebug) {
        _printDebug = false;
        print("DEBUG: frame #${_game._gameLoop.frame} ${_game._gameLoop.frameTime}");
        print("DEBUG: vdrone position3dPrevious ${ps.position3dPrevious}");
        print("DEBUG: vdrone position3d ${ps.position3d}");
      }
      if (fs == null) return; //HACK
      if (stop) {
        //TODO find a better impluse formula
        for (var i = 0; i < ps.length; ++i) {
          //v.setFrom(ps.position3dPrevious[i]).sub(ps.position3d[i]).scale(3.0);
          //ps.position3dPrevious[i].setFrom(ps.position3d[i]);
          if (ps.collide[i] == -1) {
            //tcoll = 0.0;
            //print("collision : ${_game._gameLoop.frame} ${_game._gameLoop.frameTime} : ${i} ${tcoll} ${ps.position3d[i]}");
            //ps.position3d[i].sub(ps.position3dPrevious[i]).scale(tcoll).add(ps.position3dPrevious[i]);
            ps.position3d[i].setFrom(ps.position3dPrevious[i]);
            //TODO add acceleration
          }
        }
        fs.actions[DRONE_PFRONT].force.setZero();
        fs.actions[DRONE_PCENTER].force.setZero();
        fs.actions[DRONE_PBACKL].force.setZero();
        fs.actions[DRONE_PBACKR].force.setZero();
      } else if (ctrl != null) {
        _updateEnergy(numbers, ctrl);
        var ux = (ps.position3d[DRONE_PFRONT].x - ps.position3d[DRONE_PCENTER].x);
        var uy = (ps.position3d[DRONE_PFRONT].y - ps.position3d[DRONE_PCENTER].y);
        var l = math.sqrt(ux * ux + uy * uy);

        ux = ux / l;
        uy = uy / l;
        // force is perpendicular to BACK LR
        // forward with the back particles
        var forward = ctrl.forward * numbers.accf;
        var fx = ux * forward;
        var fy = uy * forward;
        var turn = ctrl.turn * numbers.accl * 2.0;// * numbers.angularv;
        var tx = - uy * turn;
        var ty = ux * turn;

        fs.actions[DRONE_PFRONT].force.setValues(fx+tx, fy+ty, 0.0);
        fs.actions[DRONE_PCENTER].force.setValues(fx+tx*0.75 , fy+ty * 0.75, 0.0);
        fs.actions[DRONE_PBACKL].force.setValues(fx , fy , 0.0);
        fs.actions[DRONE_PBACKR].force.setValues(fx , fy , 0.0);
      } else {
        fs.actions[DRONE_PFRONT].force.setZero();
        fs.actions[DRONE_PCENTER].force.setZero();
        fs.actions[DRONE_PBACKL].force.setZero();
        fs.actions[DRONE_PBACKR].force.setZero();
      }
    }
  }

//  _attract1D(v, target, f) {
//    var c = target-v;
//    c = math.max(c * c, 1.0);
//    if (v > target) return -f / c;
//    if (v < target) return f / c;
//    return 0.0;
//  }
  void _crash(Entity entity) {
    print("DEBUG: crash entity");
    EntityStateComponent.change(entity, State_CRASHING);
  }

  void _exiting(Entity drone) {
    var numbers = _droneNumbersMapper.get(drone);
    _game._stop(true, numbers.score);
  }

  void _updateEnergy(numbers, ctrl) {
    if (numbers.energy <= (numbers.energyMax * 0.05).toInt()) {
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
      unit = 3;
    }
    numbers.energy = math.max(0, math.min(numbers.energy + unit, numbers.energyMax));
  }
  void _grabCube(Entity drone, Entity cube) {
    EntityStateComponent.change(cube, State_GRABBING);
    var att = cube.getComponent(Attraction.CT) as Attraction;
    if (att != null) {
      var ps = _particlesMapper.get(drone);
      att.attractor = ps.position3d[DRONE_PCENTER];
    }

    var numbers = _droneNumbersMapper.get(drone);
    if (numbers != null) {
      var emax = numbers.energyMax;
      numbers.energy = math.max(numbers.energy + emax / 2, emax).toInt();
      numbers.score = numbers.score + 1;
    }
  }

  void _bindKeyboardControl(){
    document.onKeyUp.listen((KeyboardEvent e) {
      if (_keysPrintDebugInfo.contains(e.keyCode)) _printDebug = true;
    });
  }

}

//class System_DroneGenerator extends EntityProcessingSystem {
//  ComponentMapper<DroneGenerator> _droneGeneratorMapper;
//  ComponentMapper<Generated> _genMapper;
//  ComponentMapper<Animatable> _animatableMapper;
//  ComponentMapper<DroneNumbers> _droneNumbersMapper;
//  Factory_Entities _efactory;
//  String _player;
//
//  System_DroneGenerator(this._efactory, this._player) : super(Aspect.getAspectForAllOf([DroneGenerator, Animatable]));
//
//  void initialize(){
//    _droneGeneratorMapper = new ComponentMapper<DroneGenerator>(DroneGenerator, world);
//    _genMapper = new ComponentMapper<Generated>(Generated, world);
//    _animatableMapper = new ComponentMapper<Animatable>(Animatable, world);
//    _droneNumbersMapper = new ComponentMapper<DroneNumbers>(DroneNumbers, world);
//  }
//
//  void processEntity(Entity entity) {
//    var gen = _droneGeneratorMapper.get(entity);
//    gen.scores.removeWhere((score) {
//      var pointsIdx = (gen.nextPointsIdx == -1) ? new math.Random().nextInt(gen.gateIns.length) : gen.nextPointsIdx % gen.gateIns.length;
//      var p = gen.gateIns[pointsIdx].ellipse.position;
//      var e = _efactory.newDrone(_player);
//      _move(e, p.x, p.y, p.z + 0.5);
//      e.addComponent(new Generated(entity));
//      var numbers = _droneNumbersMapper.get(e);
//      numbers.score = score;
//      numbers.hit = 0;
//      world.addEntity(e);
//      return true;
//    });
//  }
//
//  _move(Entity e, double x, double y, double z) {
//    var tf = new Matrix4.identity();
//    tf.translate(x, y, z);
//    var ps = e.getComponent(Particles.CT) as Particles;
//    ps.position3d.forEach((p) => tf.transform3(p));
//    ps.copyPosition3dIntoPrevious();
//  }
//
//  void deleted(Entity e) {
//    super.deleted(e);
//    var g0 = _genMapper.getSafe(e);
//    if (g0 != null) {
//      var egenerator = g0.generator;
//      var generator = _droneGeneratorMapper.getSafe(egenerator);
//      if (generator != null) {
//        var score = _droneNumbersMapper.get(e).score;
//        var a = _animatableMapper.get(egenerator).l.add(Factory_Animations.newDelay(900)
//          ..onEnd = (e0,t,t0) {
//            generator.scores.add(score);
//            return true;
//          }
//        );
//      }
//    }
//  }
//}


