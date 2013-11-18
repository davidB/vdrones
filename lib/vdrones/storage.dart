part of vdrones;

class Storage {
  static const _audioSettingsK = "audioSettings_v1";
  static const _areaBookK = "areaBook_v1";
  static const _inventoryK = "inventory_v1";
  static const _cacheLocalK = "cachel_v1";
  static const _cacheGoogleK = "cacheg_v1";

  final String _dbName = "vdrones0";
  Future<Store> _store;

  Storage(String userId, {bool clean : false}) {
    var db = new Store(_dbName, userId);
    var dbf = db.open();
    if (clean) {
      dbf = dbf.then((_) => db.nuke());
    }
    _store = dbf.then((_) => db);
  }

  Future loadAll() {
    return Future.wait([
      _load(_audioSettingsK, _audioSettings),
      _load(_areaBookK, _areaBook),
      _load(_inventoryK, _inventory),
      _load(_cacheLocalK, _cache),
      _load(_cacheGoogleK, _cacheG)
    ]);
  }

  Future _save(k, v) {
    return _store.then((db){
      var buf = v.writeToBuffer();
      return db.save(CryptoUtils.bytesToBase64(buf), k);
    });
  }

  Future _load(k, v) {
    return _store.then((db) => db.getByKey(k).then((x) {
      if (x != null) {
        var buf = CryptoUtils.base64StringToBytes(x);
        v.mergeFromBuffer(buf);
      }
      return v;
    }));
  }

  var _audioSettings = new AudioSettings();
  AudioSettings get audioSettings => _audioSettings;
  set audioSettings(AudioSettings v) {
    _audioSettings = v;
    _save(_audioSettingsK, _audioSettings);
  }

  var _areaBook = new AreaBook();
  AreaBook get areaBook => _areaBook;
  set areaBook(AreaBook v) {
    _areaBook = v;
    _save(_areaBookK, _areaBook);
  }

  var _inventory = new Inventory();
  Inventory get inventory => _inventory;
  set inventory(Inventory v) {
    _inventory = v;
    _save(_inventoryK, _inventory);
  }

  var _cache = new PCache();
  PCache get cache => _cache;
  set cache(PCache v) {
    _cache = v;
    _cache.lastModification = new Int64(new DateTime.now().toUtc().millisecondsSinceEpoch);
    _save(_cacheLocalK, _cache);
  }

  var _cacheG = new PCache();
  PCache get cacheG => _cacheG;
  set cacheG(PCache v) {
    _cacheG = v;
    _cacheG.lastModification = new Int64(new DateTime.now().toUtc().millisecondsSinceEpoch);
    _save(_cacheGoogleK, _cacheG);
  }

}
