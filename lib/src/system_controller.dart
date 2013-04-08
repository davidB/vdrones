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
