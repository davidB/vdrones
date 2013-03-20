part of vdrones;

class Stats{
  static const MONEY_CURRENT_V = r'money/current/v';
  static const MONEY_CUMUL_V = r'money/cumul/v';
  static const MONEY_LAST_V = r'money/last/v';
  static const AREA_CUBES_MAX_V = r'/cubes/max/v';
  static const AREA_CUBES_TOTAL_V = r'/cubes/total/v';
  static const AREA_CUBES_LAST_V = r'/cubes/last/v';

  final Evt evt;
  final String dbName;
  String _areaId;
  final Map<String, num> _statistics = new Map<String, num>();
  Future<Store> store;

  Stats(this.evt, this.dbName, {bool clean : false}) {
    evt.GameInit.add((areaPath){
      _areaId = areaPath;
      store = _loadStatistics(_areaId, clean);
    });
    evt.GameStop.add(_stop);
  }

  num operator[](String k) => _statistics[k];

  void updateCubesLast(String areaId, int v) {
    num update(String k, Function f) {
      var x = this[k];
      _statistics[k] = f((x == null) ? 0 : x);
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

  void _stop(bool exit) {
    if (!exit) return;
    updateCubesLast(_areaId, evt.GameStates.score.v);
    _saveStatistics();
  }

  Future _saveStatistics() {
    return store.then((db){
      print("START SAVE");
      db.batch(_statistics);
    });
  }

  Future<Store> _loadStatistics(String areaId, bool clean) {
    print("START LOAD");
    var dbStore = evt.GameStates.userId.v;

    var db = new IndexedDbStore(dbName, dbStore);
//      IndexedDbStore.supported ? new IndexedDbStore(dbName, dbStore):
//      WebSqlStore.supported ?  new WebSqlStore(dbName, dbStore) :
//      new LocalStorageStore()
//      ;
    var dbf = db.open();
    if (clean) {
      dbf = dbf.then((_) => db.nuke());
    }
    Future loadEntry(key) {
      return dbf.then((_) => db.getByKey(key).then((x) {
        _statistics[key] = (x == null) ? 0 : x;
        return x;
      }));
    }
    return Future.wait([
      MONEY_CURRENT_V,
      MONEY_CUMUL_V,
      MONEY_LAST_V,
      areaId + AREA_CUBES_MAX_V,
      areaId + AREA_CUBES_TOTAL_V,
      areaId + AREA_CUBES_LAST_V
      ].map(loadEntry)
    ).then((x) => db);
  }

}
