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
      if (_keysForward.contains(e.keyCode)) _state.forward = 5500.0;
      else if (_keysTurnLeft.contains(e.keyCode)) _state.turn = 110.0;
      else if (_keysTurnRight.contains(e.keyCode)) _state.turn = -110.0;
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

  System_DroneHandler() : super(Aspect.getAspectForAllOf([DroneControl, PhysicMotion]));

  void initialize(){
    _droneControlMapper = new ComponentMapper<DroneControl>(DroneControl, world);
    _motionMapper = new ComponentMapper<PhysicMotion>(PhysicMotion, world);
  }

  void processEntity(Entity entity) {
    var ctrl = _droneControlMapper.get(entity);
    var m = _motionMapper.get(entity);
    m.acceleration = ctrl.forward;
    m.angularVelocity = radians(ctrl.turn);
  }
}

class System_DroneGenerator extends EntityProcessingSystem {
  ComponentMapper<DroneGenerator> _droneGeneratorMapper;
  _EntitiesFactory _efactory;
  String _player;

  System_DroneGenerator(this._efactory, this._player) : super(Aspect.getAspectForAllOf([DroneGenerator, Transform]));

  void initialize(){
    _droneGeneratorMapper = new ComponentMapper<DroneGenerator>(DroneGenerator, world);
  }

  void processEntity(Entity entity) {
    var gen = _droneGeneratorMapper.get(entity);
    for(var i = gen.nb; i > 0; i--) {
      var pointsIdx = (gen.nextPointsIdx == -1) ? new math.Random().nextInt(gen.points.length) : gen.nextPointsIdx % gen.points.length;
      var p = gen.points[pointsIdx];
      _efactory.newDrone(_player, p.x, p.y, p.z).then((e) => world.addEntity(e));
    }
    gen.nb = 0;
  }
}


