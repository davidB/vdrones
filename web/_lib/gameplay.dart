part of vdrones;

void setupGameplay(Evt evt){
  var _droneId = "!";
  var _areaId = "!";
  var _uid = (new DateTime.now()).millisecondsSinceEpoch;
  var _entities = new Entities();


  void updateEnergy(delta) {
    var unit = 0;
    if (evt.GameStates.boosting.v) {
      unit -= 2;
    }
//    if (evt.GameStates.shooting.v) {
//      unit -= 7;
//    }
//    if (evt.GameStates.shielding.v) {
//      unit -= 10;
//    }
    if (unit == 0) {
      unit += 3;
    }
    var v = math.max(0, math.min(evt.GameStates.energy.v + unit, evt.GameStates.energyMax.v));
    evt.GameStates.energy.v = v;
    if (v == 0) {
      if (evt.GameStates.boosting.v) {
        evt.BoostShipStop.dispatch([_droneId]);
      }
    }
  }

  void spawnDrone(id) {
    Future.wait([
      _entities.find('drone01'),
      _entities.find(_areaId)
    ]).then((l) {
      evt.GameStates.energyMax.v = 1000;
      evt.GameStates.energy.v = 500;
      evt.GameStates.boosting.v = false;

      var drone = l[0], area = l[1];
      var zone = area["gate_in"];
      var z = zone.cells;
      var cellr = zone.cellr;
      var x = z[0] * cellr + z[2] * cellr / 2;
      var y = z[1] * cellr + z[3] * cellr / 2;
      evt.ObjSpawn.dispatch([id, new Position(x, y, 0.5), drone]);
    });
  }

  void start(){
    print("START");
    evt.GameStates.energy.v = 0;
    evt.GameStates.energyMax.v = 0;
    evt.GameStates.boosting.v = false;
    evt.GameStates.score.v = 0;

    _droneId = "drone/${_uid + 1}";
    evt.SetLocalDroneId.dispatch([_droneId]);
    _entities.find('gui').then((x){ evt.HudSpawn.dispatch(['hud', x]); });
    _entities.find(_areaId).then((x){
      evt.AreaSpawn.dispatch(["area/${_uid}", Position.zero, x["walls"]]);
      evt.ObjSpawn.dispatch(["gate_in/${_uid}", Position.zero, x["gate_in"]]);
      new Zone4GateOut("gate_out/${_uid}", evt, x["gate_out"]);
      new Zone4Cubes(x["targetg1_spawn"], evt, _entities);
    });

    spawnDrone(_droneId);
    evt.CountdownStart.dispatch(["countdown", 59, evt.GameStop, [false], evt.GameStates.countdown]);
  }

  void onReqEvent(Signal signal, List args) {
    signal.dispatch(args);
//
//        #ignore
//        when evt.ValInc
//          incState(args[0], args[1])  if args[0].indexOf(_droneId) is 0
//        when evt.BoostShipStart
//          signal.dispatch.apply(this, args)
//          updateState(_droneId + "/boosting", true)  if args[0] is _droneId
//        when evt.BoostShipStop
//          signal.dispatch.apply(this, args)
//          updateState(_droneId + "/boosting", false)  if args[0] is _droneId
//        when evt.ShootingStart
//          signal.dispatch.apply(this, args)
//          evt.PeriodicEvtAdd.dispatch(_droneId + "-fire", 300, evt.EvtReq, [evt.FireBullet, [_droneId]])  if args[0] is _droneId
//        when evt.ShootingStop
//          signal.dispatch.apply(this, args)
//          evt.PeriodicEvtDel.dispatch(_droneId + "-fire")  if args[0] is _droneId
//        when evt.FireBullet
//          if args[0] isnt _droneId
//            signal.dispatch.apply(this, args)
//          else
//            if _states[_droneId + "/energy"] > 7
//              incState(_droneId + "/energy", -7)
//              signal.dispatch.apply(this, args)
//        else
//          signal.dispatch.apply(this, args)
  }

  evt.GameInit.add((areaPath){
    _areaId = areaPath;
    print("GameInit received");
    Future.wait([
      _entities.preload(evt, 'area', areaPath),
      _entities.preload(evt, 'model', 'drone01'),
      _entities.preload(evt, 'model', 'targetg101'),
      _entities.preload(evt, 'hud', 'gui')
    ]).then(
      (x){
        evt.GameInitialized.dispatch(null);
        print("GameInitialized send");
      },
      onError : (err){ evt.Error.dispatch(["failed to load assets", err]); }
    );
  });
  print("Register START");
  evt.GameStart.add(start);
  evt.EvtReq.add(onReqEvent);
  evt.Tick.add((t, delta500) {
    updateEnergy(delta500);
  });
  evt.BoostShipStart.add((droneId){
    evt.GameStates.boosting.v = true;
  });
  evt.BoostShipStop.add((droneId){
    evt.GameStates.boosting.v = false;
  });
  evt.ContactBeginDroneWall.add((String droneId, String wallId){
    var deferred = new Completer();
    evt.ObjDespawn.dispatch([droneId, {"preAnimName" : "crash", "deferred" : deferred }]);
    deferred.future.then((x){ spawnDrone(droneId); });
  });
}
