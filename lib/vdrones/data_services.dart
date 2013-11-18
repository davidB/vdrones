part of vdrones;

//TODO connect remote access (GooglePlayService, ...) to the progress bar indicator
//TODO connect storage (GooglePlayService, ...) to the progress bar indicator
//TODO add more tests
class DataServices {
  gamesbrowser.Games gameservices;
  var bus;

  var _storage = new Storage("u0");
  var _syncing = new Future.value(true);

  RunResult processRunReport(String area, RunReport runReport) {
    var modified = false;
    var b = new RunResult();
    _processRunReport4AreaStat(b, area, runReport);
    modified = modified || _processRunReport4Achievements(b);
    modified = modified || _processRunReport4Score(b);
    if (modified) {
      // force save
      _storage.cache = _storage.cache;
    }
    _syncCaches();
    return b;
  }

  _processRunReport4AreaStat(RunResult b, String area, RunReport runReport) {
    b.area = area;
    b.exiting = runReport.exiting;
    b.cubes = runReport.cubeCount;

    var areaStat = _findAreaStat(area);
    if (areaStat.cubeBestRun == null) {
      b.previousMax = 0;
      b.gain = b.cubes;
      areaStat.cubeBestRun = runReport;
    } else {
      b.previousMax = areaStat.cubeBestRun.cubeCount;
      b.gain = math.max(0, b.cubes - b.previousMax);
      if (b.gain > 0) {
        areaStat.cubeBestRun = runReport;
      }
    }
    areaStat.crashCount += runReport.crashCount;
    areaStat.exitingCount += runReport.exiting ? 1 : 0;
    areaStat.lastStartTime = runReport.startTime;
    areaStat.runCount += 1;
    _saveAreaStat(areaStat);
  }

  _processRunReport4Achievements(RunResult b) {
    var modified = false;
    var computed = _findAchievements();
    var cached = _storage.cache.achievements;
    var diff = b.achievementsUnlocked;
    _diffOfAchievements(computed, cached, diff);
    if (diff.length > 0) {
      _storage.cache.achievements.clear();
      _storage.cache.achievements.addAll(computed);
      modified = true;
    }
    return modified;
  }

  _diffOfAchievements(List source, List target, List diff) {
    if (source.length > target.length) {
      for(var i=0, j=0; i < source.length; i++) {
        if (source[i] != target[j]) {
          diff.add(source[i]);
        } else {
          j++;
        }
      }
    }
  }

  _processRunReport4Score(RunResult b) {
    var modified = false;
    b.cubesTotal = _findTotalCubes();
    var cached = _storage.cache.scoreCubes;
    if (cached != b.cubesTotal) {
      _storage.cache.scoreCubes = b.cubesTotal;
      modified = true;
    }
    return modified;
  }

  _syncCaches() {
    print("try syncing....");
    if (gameservices == null || gameservices.auth.token == null) return _syncing;
    print("syncing....");
    _syncing = _syncing.then((_){
      return (_storage.cacheG.lastModification < new DateTime.now().subtract(new Duration(days: 15)).toUtc().millisecondsSinceEpoch)
        ? _remoteLoadCacheGoogle().then((_) => _updateCacheGoogle(_storage.cache))
        : _updateCacheGoogle(_storage.cache)
      ;
    });
    return _syncing;
  }

  _remoteLoadCacheGoogle() {
    print("_remoteLoadCacheGoogle()");
    return Future.wait([
      gameservices.achievements.list("me", state: "UNLOCKED", optParams: {"fields": "items/id"}),
      gameservices.scores.get("me", cfg.LEAD_CUBES, "ALL_TIME")
    ]).then((l){
      var cg = _storage.cacheG;
      cg.achievements.clear();
      cg.achievements.addAll(l[0].items.map((x) => x.id).toList()..sort());
      cg.scoreCubes = (l[1].items.length > 0) ? l[1].items.first.scoreValue : 0;
      _storage.cacheG = cg;
    });
  }

  _updateCacheGoogle(PCache local) {
    print("_updateCacheGoogle");
    var cg = _storage.cacheG;
    var futures = new List();
    //if (local.scoreCubes > cg.scoreCubes) {
      print("try to save score ${local.scoreCubes} ");
      futures.add(
        gameservices.scores.submit(cfg.LEAD_CUBES, local.scoreCubes.toInt()).then((r){
          print("try to save score ${local.scoreCubes} on local : ${r}");
          cg.scoreCubes = local.scoreCubes;
        }).then((_) {
          _storage.cacheG = cg;
        })
      );
    //}
    var diff = new List();
    _diffOfAchievements(local.achievements, cg.achievements, diff);
    if (diff.length > 0) {
      print("try to save achievements ${diff}");
      futures.add(
        Future.wait(diff.map((x){
          return gameservices.achievements.unlock(x).then((_) => cg.achievements.add(x));
        }).toList()).then((_){
          _storage.cacheG = cg;
        })
      );
    }
    return Future.wait(futures).catchError(_handleError);
  }

  _handleError(e) {
    bus.fire(eventErr, new Err()
    ..category = "data_services"
    ..exc = e
    );
  }

  AreaStat _findAreaStat(area) {
    var out = _storage.areaBook.areaStats.firstWhere((x) => x.id == area, orElse: ()=> null);
    if (out == null) {
      out = new AreaStat();
      out.id = area;
    }
    return out;
  }

  _saveAreaStat(areaStat) {
    var out = _storage.areaBook.areaStats.firstWhere((x) => x.id == areaStat.id, orElse: ()=> null);
    if (out == null) {
      _storage.areaBook.areaStats.add(areaStat);
    }
    // force save
    _storage.areaBook = _storage.areaBook;
  }

  _findTotalCubesGrabbed(List<AreaStat> areaStats) {
    return _storage.areaBook.areaStats.fold(0,(acc, x) => acc + x.cubeBestRun.cubeCount);
  }

  _findTotalCubesSpend() {
    //TODO remove inventory
    return 0;
  }

  _findTotalCubes() {
    var areaStats = _storage.areaBook.areaStats;
    return _findTotalCubesGrabbed(areaStats) - _findTotalCubesSpend();
  }

  _findTotalCrash(List<AreaStat> areaStats) {
    return areaStats.fold(0,(acc, x) => acc + x.crashCount);
  }

  _findAreaExplore(List<AreaStat> areaStats) {
    return areaStats.fold(0,(acc, x) => acc + ((x.cubeBestRun.cubeCount > 0)? 1 : 0));
  }

  _findTotalTimeOut(List<AreaStat> areaStats) {
    return areaStats.fold(0,(acc, x) => acc + ((x.runCount != x.exitingCount)? 1 : 0));
  }

  _findAchievements() {
    var out = new List<String>();
    var areaStats = _storage.areaBook.areaStats;

    var tcg = _findTotalCubesGrabbed(areaStats);
    if (tcg >= 10) out.add(cfg.ACH_HUNTER_I);
    if (tcg >= 30) out.add(cfg.ACH_HUNTER_II);
    if (tcg >= 50) out.add(cfg.ACH_HUNTER_III);

    var tc = _findTotalCrash(areaStats);
    if (tc >= 10) out.add(cfg.ACH_BANG_I);
    if (tc >= 30) out.add(cfg.ACH_BANG_II);
    if (tc >= 50) out.add(cfg.ACH_BANG_III);

    var ae = _findAreaExplore(areaStats);
    if (ae >= 10) out.add(cfg.ACH_EXPLORATOR_I);
    if (ae >= 30) out.add(cfg.ACH_EXPLORATOR_II);
    if (ae >= 50) out.add(cfg.ACH_EXPLORATOR_III);

    if (_findTotalTimeOut(areaStats) >= 1) out.add(cfg.ACH_FIRST_TIME_OUT);
    //TODO ACH_JUST_IN_TIME

    return out..sort();
  }

}

class RunResult {
  String area = 'undef';
  int cubes = 0;
  int gain = 0;
  int previousMax = 0;
  int cubesTotal = 0;
  bool exiting = true;
  List achievementsUnlocked = new List<String>();
}