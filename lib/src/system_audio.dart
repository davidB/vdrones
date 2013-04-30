part of vdrones;

/**
 * Component use to store a bag of name of [AudioClip] to play.
 * When the [System_Audio] start to play, name is removed from the bag.
 * [System_Audio] start to play ASAP.
 */
class AudioDef extends ComponentPoolable {
  final l = new LinkedBag<String>();

  AudioDef._();
  static _ctor() => new AudioDef._();
  factory AudioDef() {
    var c = new Poolable.of(AudioDef, _ctor);
    c.cleanUp();
    return c;
  }

  void cleanUp() {
    l.clear();
  }

  /// this is a sugar method for [l].add([a])
  /// sugar because you can write
  ///
  ///    new AudioDef()
  ///      ..add("boost")
  ///      ..add("alarm")
  ///
  AudioDef add(String a) {
    l.add(a);
    return this;
  }
}

class _AudioCache extends Component {
  final AudioSource source;

  _AudioCache(this.source);
}


class System_Audio extends EntityProcessingSystem {
  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<AudioDef> _objDefMapper;
  ComponentMapper<_AudioCache> _objCacheMapper;
  GroupManager _groupManager;

  var _listener;
  var _positional = false;
  final AudioManager _audioManager;
  final AssetManager _assetManager;

  System_Audio(this._audioManager, this._assetManager, {this._positional : false}):super(Aspect.getAspectForAllOf([AudioDef]));

  void initialize(){
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _objDefMapper = new ComponentMapper<AudioDef>(AudioDef, world);
    _objCacheMapper = new ComponentMapper<_AudioCache>(_AudioCache, world);
    _groupManager = world.getManager(GroupManager) as GroupManager;
  }

  void processEntity(entity) {
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) {
      var obj = cache.source;
      _applyTransform(obj, entity);
      var def = _objDefMapper.get(entity);
      def.l.iterateAndUpdate((x) {
        var clip = null;//_audioManager.findClip(x);
        if (clip == null) clip = _assetManager[x];
        if (clip == null) {
          print("can't play sound '${x}' : notfound in audioManager nor assetManager");
        } else {
          print("play ${x} : ${_assetManager.getAssetAtPath(x).url} : ${clip}");
          if (obj != _listener) {
            obj.playOnce(clip);
          } else {
            _audioManager.music.stop();
            _audioManager.music.clip = clip;
            _audioManager.music.play(loop : false);
          }
        }
        return null;
      });
    }
  }

  void inserted(Entity entity){
    var objDef = _objDefMapper.get(entity);
    var obj = _audioManager.makeSource(entity.id.toString());
    entity.addComponent(new _AudioCache(obj));
    entity.changedInWorld();
    _applyTransform(obj, entity);
    if (_groupManager.isInGroup(entity, GROUP_AUDIOLISTENER)) {
      print("set audiolistener");
      _listener = obj;
    }
    print("inserted into audio ${entity}");
  }

  void removed(Entity entity){
    var cache = _objCacheMapper.getSafe(entity);
    if (cache != null) {
      cache.source.stop();
      if (cache.source == _listener) _listener = null;
    }
    entity.removeComponent(_AudioCache);
    print("removed audio ${entity}");
  }

  void _applyTransform(obj, Entity entity) {
    if (! _positional) return;
    var tf = _transformMapper.getSafe(entity);
    if (obj != null && tf != null) {
      obj.positional = true;
      obj.setPosition(tf.position3d.x, tf.position3d.y, tf.position3d.z);
      if (obj == _listener) {
        _audioManager.setPosition(tf.position3d.x, tf.position3d.y, tf.position3d.z);
      }
    }
  }

}
