part of vdrones;

class Stats{
  static const STATS_KEY = "stats";
  static const FORMAT_V = r'format';
  static const CUBES_TOTAL_V = r'cubes/total/v';
  static const AREA_CUBES_MAX_V = r'/cubes/max/v';
  static const AREA_CUBES_LAST_GAIN = r'/cubes/last/gain';
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
    var cubesMax = this[areaId + AREA_CUBES_MAX_V];
    var gain = math.max(0, v - cubesMax);
    _statistics[areaId + AREA_CUBES_MAX_V] = cubesMax + gain;
    _statistics[areaId + AREA_CUBES_LAST_GAIN] = gain;
    _statistics[areaId + AREA_CUBES_LAST_V] = v;
    //Total  = sum(AREA_CUBES_MAX_V) - sum(purchase)
    _statistics[CUBES_TOTAL_V] = this[CUBES_TOTAL_V] + gain;
  }

  Future updateCubesLast(String areaId, int v) {
    return store
      .then((db) => _updateCubesLastMem(areaId, v))
      .then((_) => _saveStatistics())
      ;
  }

  Future _saveStatistics() {
    return store.then((db){
      db.save(JSON.encode(_statistics), STATS_KEY);
      return _statistics;
    });
  }

  Future<Store> _loadStatistics(String userId, bool clean) {
    var dbStore = userId;

    var db = new Store(dbName, dbStore);
    var dbf = db.open();
    if (clean) {
      dbf = dbf.then((_) => db.nuke());
    }
    return dbf.then((_) => db.getByKey(STATS_KEY).then((x) {
      if (x != null) {
        var data = JSON.decode(x) as Map;
        if (data[FORMAT_V] == 2) {
          _statistics.addAll(data);
        } else {
          //reset data
          _statistics[FORMAT_V] == 2;
        }
      }
      return db;
    }));
  }

}
