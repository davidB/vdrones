part of vdrones;

final vecZ = new Vector3(0.0, 0.0, 1.0);
final vecY = new Vector3(0.0, 1.0, 0.0);

class System_CameraFollower extends EntityProcessingSystem {
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<CameraFollower> _followerMapper;
  PlayerManager _playerManager;
  GroupManager _groupManager;
  Particles _targetParticles = null;
  bool _targetUpdated = true;
  String playerToFollow;

  System_CameraFollower() : super(Aspect.getAspectForAllOf([CameraFollower]));

  void initialize(){
    _followerMapper = new ComponentMapper<CameraFollower>(CameraFollower, world);
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _playerManager = world.getManager(PlayerManager) as PlayerManager;
    _groupManager = world.getManager(GroupManager) as GroupManager;
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

  void processEntity(Entity entity) {
    var follower = _followerMapper.get(entity);
    if (follower.info == null) return;
    var _targetPosition = _targetParticles.position3d[DRONE_PCENTER];
    var camera = follower.info;
    if (follower.rotate) {
      var ux = (_targetParticles.position3d[DRONE_PFRONT].x - _targetParticles.position3d[DRONE_PCENTER].x);
      var uy = (_targetParticles.position3d[DRONE_PFRONT].y - _targetParticles.position3d[DRONE_PCENTER].y);
      var l = math.sqrt(ux * ux + uy * uy);//2.0;
      ux = ux / l;
      uy = uy / l;
      var tmp0 = new Vector3(ux, uy, 1.0);
      var tmp1 = new Vector3(0.0, 0.0, 0.0);
      tmp0.crossInto(vecZ, tmp1);

//      t.angle = _targetTransform.angle;
      //print("----------");
      //var m4 = new Matrix4.zero().translate(_targetPosition);

      var m4 = new Matrix4(
        ux, uy, 0.0, 0.0,
        tmp1.x, tmp1.y, tmp1.z, 0.0,
        0.0, 0.0, 1.0, 0.0,
        _targetPosition.x, _targetPosition.y, _targetPosition.z, 1.0
      );
//      m4.rotateZ(_targetTransform.angle);
      //TODO use follower by a distance + vector unit (direction should become (head - center) particle)
      var target = m4.transformed3(follower.targetTranslation);
//      var target = new Vector3.copy(_targetPosition).add(follower.targetTranslation);

      //var target = new Vector3(_targetPosition);
      //target.add()
      var damp = world.delta / (1000.0 * 0.25);
      camera.position.x = approachMulti(target.x, follower.info.position.x, damp);
      camera.position.y = approachMulti(target.y, follower.info.position.y, damp);
      camera.position.z = approachMulti(target.z, follower.info.position.z, damp);
      //.getTranslation());//, follower.targetTranslation.y, follower.targetTranslation.z).getTranslation());
      //print(t.position3d);
      //var r3 = new Vector3.copy(t.rotation3d);
      camera.upDirection.setFrom(vecZ);
      camera.focusPosition.setValues(_targetPosition.x + 4 * ux, _targetPosition.y + 4 * uy, 3.0);
      //t.rotation3d.x = approachMulti(t.rotation3d.x, r3.x, 0.03);
      //t.rotation3d.y = approachMulti(t.rotation3d.y, r3.y, 0.03);
      //t.rotation3d.z = approachMulti(t.rotation3d.z, r3.z, 0.03);
      //t.angle = approachMulti(_targetTransform.angle, t.angle, 0.3);
      camera.near = 0.001;
      camera.far = 200.0;//(follower.focusAabb.max - follower.focusAabb.min).length;
    } else {
      print("wrong");
      var target = new Vector3.copy(_targetPosition).add(follower.targetTranslation);
      var position = camera.position;
      position.x = approachMulti(target.x, position.x, 0.2);
      position.y = approachMulti(target.y, position.y, 0.2);
      position.z = approachMulti(target.z, position.z, 0.3);
      camera.upDirection.setFrom(vecY);
      camera.focusPosition.setFrom(_targetPosition);
    }
    //print("${follower.info.position} .. ${follower.info.focusPosition} .. ${follower.info.upDirection}");
    //follower.info.updateProjectionMatrix();
    //camera.adjustNearFar(follower.focusAabb, 0.001, 0.1);
    camera.updateViewMatrix();
    //camera.near = camera.near *0.5;
    //print("${follower.focusAabb.min} .. ${follower.focusAabb.max}, ${camera.near}, ${camera.far}");

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
  //ComponentMapper<PhysicMotion> _motionMapper;
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<DroneControl> _droneControlMapper;
  ComponentMapper<Collisions> _collisionsMapper;
  ComponentMapper<EntityStateComponent> _statesMapper;
  ComponentMapper<Generated> _genMapper;
  ComponentMapper<DroneGenerator> _droneGenMapper;
  ComponentMapper<DroneNumbers> _droneNumbersMapper;
  Factory_Entities _efactory;
  VDrones _game;

  System_DroneHandler(this._efactory, this._game) : super(Aspect.getAspectForAllOf([DroneControl, DroneNumbers, Particles/*PhysicMotion, PhysicCollisions*/, EntityStateComponent]));

  void initialize(){
    _droneControlMapper = new ComponentMapper<DroneControl>(DroneControl, world);
    _droneNumbersMapper = new ComponentMapper<DroneNumbers>(DroneNumbers, world);
    //_motionMapper = new ComponentMapper<PhysicMotion>(PhysicMotion, world);
    _collisionsMapper = new ComponentMapper<Collisions>(Collisions, world);
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _statesMapper = new ComponentMapper<EntityStateComponent>(EntityStateComponent, world);
  }

  void processEntity(Entity entity) {
    var esc = _statesMapper.getSafe(entity);
    var collisions = _collisionsMapper.get(entity);
    var numbers = _droneNumbersMapper.get(entity);
    var stop = false;
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
          stop = true;
          break;
        case EntityTypes_ITEM : _grabCube(entity, collider.e); break;
        case EntityTypes_GATEOUT : _exiting(entity); break;
      }
      return null;
    });
    if (esc.state == State_DRIVING) {
      var ctrl = _droneControlMapper.get(entity);
      //var m = _motionMapper.get(entity);
      //m.acceleration = ctrl.forward * numbers.acc;
      //m.angularVelocity = radians(ctrl.turn * numbers.angularv);
      //ctrl.forward * numbers.acc;
      var ps = _particlesMapper.get(entity);
      if (stop) {
        //ctrl.forward = 0.0;
        //ctrl.turn = 0.0;
        var v = new Vector3.zero();
        for (var i = 0; i < ps.length; ++i) {
          v.setFrom(ps.position3dPrevious[i]);
          ps.position3dPrevious[i].setFrom(ps.position3d[i]);
          ps.position3d[i].setFrom(v);
        }
      } else {
        _updateEnergy(numbers, ctrl);
        numbers.hitLastTime = math.max(0, --numbers.hitLastTime);
        //ps.accForces[DRONE_PFRONT].setValues(3.0, 0.0, 3.0);
        // component of normal of PBACKs  (2.0 is the BACK LR)
  //      var ux = (ps.position3d[DRONE_PBACKR].y - ps.position3d[DRONE_PBACKL].y);
  //      var uy = -(ps.position3d[DRONE_PBACKR].x - ps.position3d[DRONE_PBACKL].x);
  //      var l = math.sqrt(ux * ux + uy * uy);//2.0;
        var ux = (ps.position3d[DRONE_PFRONT].x - ps.position3d[DRONE_PCENTER].x);
        var uy = (ps.position3d[DRONE_PFRONT].y - ps.position3d[DRONE_PCENTER].y);
        var l = math.sqrt(ux * ux + uy * uy);//2.0;

        ux = ux / l;
        uy = uy / l;
        // force is perpendicular to BACK LR
        // forward with the back particles
        var forward = ctrl.forward * numbers.accf;
        var fx = ux * forward;
        var fy = uy * forward;
        var turn = ctrl.turn * numbers.accl;//* numbers.angularv;
        var tx = - uy * turn;
        var ty = ux * turn;
        var accz = 10.0;
        ps.acc[DRONE_PFRONT].setValues(fx + tx, fy + ty, (0.8 - ps.position3d[DRONE_PFRONT].z) * accz);
        ps.acc[DRONE_PCENTER].setValues(fx, fy, (2.0 - ps.position3d[DRONE_PCENTER].z) * accz);
        ps.acc[DRONE_PBACKL].setValues(fx - tx, fy - ty, (1.0 - ps.position3d[DRONE_PBACKL].z) * accz);
        ps.acc[DRONE_PBACKR].setValues(fx - tx, fy - ty, (1.0 - ps.position3d[DRONE_PBACKR].z) * accz);
  //      var transform = _transformMapper.get(entity);
  //      if (transform != null) {
  //        transform.position3d.setFrom(ps.position3d[DRONE_PCENTER]);
  //      }
      }
    }
  }

  void _crash(Entity entity) {
//    var transform = _transformMapper.get(entity);
//    if (transform != null) world.addEntity( _efactory.newExplosion(transform));
    entity.deleteFromWorld();
//    // esc.state = State_CRASHING;
  }

  void _goPrevious(Entity entity) {
    entity.deleteFromWorld();
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
      var e = _efactory.newDrone(_player);
      _move(e, p.x, p.y, 0.5);
      e.addComponent(new Generated(entity));
      var numbers = _droneNumbersMapper.get(e);
      numbers.score = score;
      numbers.hit = 0;
      world.addEntity(e);
      return true;
    });
  }

  _move(Entity e, double x, double y, double z) {
    var tf = new Matrix4.identity();
    tf.translate(x, y, z);
    var ps = e.getComponent(Particles.CT);
    ps.position3d.forEach((p) => tf.transform3(p));
    ps.copyPosition3dIntoPrevious();
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
      var e = _efactory.newCube();
      _move(e, p.x, p.y, 1.0);
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

  _move(Entity e, double x, double y, double z) {
    var tf = new Matrix4.identity();
    tf.translate(x, y, z);
    var ps = e.getComponent(Particles.CT);
    ps.position3d.forEach((p) => tf.transform3(p));
    ps.copyPosition3dIntoPrevious();
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

