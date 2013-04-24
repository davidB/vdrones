part of vdrones;

class Stats{
  static const STATS_KEY = "stats";
  static const MONEY_CURRENT_V = r'money/current/v';
  static const MONEY_CUMUL_V = r'money/cumul/v';
  static const MONEY_LAST_V = r'money/last/v';
  static const AREA_CUBES_MAX_V = r'/cubes/max/v';
  static const AREA_CUBES_TOTAL_V = r'/cubes/total/v';
  static const AREA_CUBES_LAST_V = r'/cubes/last/v';

  final String dbName = "vdrones0";
  final HashMap<String, num> _statistics = new HashMap<String, num>();
  Future<Store> store;

  Stats(String userId, {bool clean : false}) {
    store = _loadStatistics(userId, clean);
  }

  num operator[](String k) {
    var v = _statistics[k];
    return (v == null) ? 0 : v;
  }

  void _updateCubesLastMem(String areaId, int v) {
    num update(String k, Function f) {
      _statistics[k] = f(this[k]);
    }

    var cubesMax = this[areaId + AREA_CUBES_MAX_V];
    var gain = math.max(0, math.min(v, cubesMax)) * 0.25 + math.max(0, v - cubesMax) * 1;
    update(MONEY_CURRENT_V, (x) => x + gain);
    update(MONEY_CUMUL_V, (x) => x + gain);
    update(MONEY_LAST_V, (x) => gain);
    update(areaId + AREA_CUBES_MAX_V, (x) => (x < v) ? v : x);
    update(areaId + AREA_CUBES_TOTAL_V, (x) => x + v);
    update(areaId + AREA_CUBES_LAST_V, (x) => v);
  }

  Future updateCubesLast(String areaId, int v) {
    return store
      .then((db) => _updateCubesLastMem(areaId, v))
      .then((_) => _saveStatistics())
      ;
  }

  Future _saveStatistics() {
    return store.then((db){
      db.save(JSON.stringify(_statistics), STATS_KEY);
      return _statistics;
    });
  }

  Future<Store> _loadStatistics(String userId, bool clean) {
    var dbStore = userId;

    Store db = IndexedDbStore.supported ? new IndexedDbStore(dbName, dbStore):
      WebSqlStore.supported ?  new WebSqlStore(dbName, dbStore) :
      new LocalStorageStore()
      ;
    var dbf = db.open();
    if (clean) {
      dbf = dbf.then((_) => db.nuke());
    }
    return dbf.then((_) => db.getByKey(STATS_KEY).then((x) {
      if (x != null) _statistics.addAll(JSON.parse(x) as Map);
      return db;
    }));
  }

}
