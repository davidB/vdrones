library vdrones_gameplay;

import 'events.dart';
import 'entities.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:core';
import 'zone_cubes.dart';

void setupGameplay(Evt evt){
  var _droneId = "!";
  var _areaId = "!";
  var _states = {}; //evt.newStates();
  var _uid = (new DateTime.now()).millisecondsSinceEpoch;
  var _entities = new Entities();


  void onUpdateState(k, v) {
    if (_states["${_droneId}/boosting"] == true) {
      if (k == "${_droneId}/energy" && v == 0) {
        //TODO onReqEvent(evt.BoostShipStop, [_droneId]);
      }
    }
  }

  void incState(k, v) {
    // _states.inc(k, v, onUpdateState);
  }

  void updateState(k, v) {
    // _states.update(k, v, onUpdateState);
  }

  void updateEnergy(delta) {
    var k = "${_droneId}/energy";
    var v = _states[k];
    var unit = 0;
    if (_states["${_droneId}/boosting"] == true) {
      unit -= 5;
    }

    //if (_states[_droneId + '/shooting']) unit -= 7;
    if (_states["${_droneId}/shielding"] == true) {
      unit -= 10;
    }
    if (unit == 0) {
      unit += 3;
    }
    v = math.min(_states["${k}Max"], math.max(0, v + unit));
    updateState(k, v);
  }

  void spawnDrone(id) {
    Future.wait([
      _entities.find('drone01'),
      _entities.find(_areaId)
    ]).then((l) {
      var drone = l[0], area = l[1];
      var zone = area["gate_in"];
      var z = zone.cells;
      var cellr = zone.cellr;
      var x = z[0] * cellr + z[2] * cellr / 2;
      var y = z[1] * cellr + z[3] * cellr / 2;
      evt.ObjSpawn.dispatch([id, new Position(x, y, 0.5), drone]);
    });
  }

  void spawnZones4Cubes(EntityProvider4Static zones) {
    evt.ObjSpawn.dispatch(["targetg1_spawn/${_uid}", Position.zero, zones]);
    new Zone4Cubes(zones.cells, zones.cellr, evt, _entities);
  }

  void start(){
    print("START");
    _droneId = "drone/${_uid + 1}";
    evt.SetLocalDroneId.dispatch([_droneId]);
    _entities.find('gui').then((x){ evt.HudSpawn.dispatch(['hud', x]); });
    _entities.find(_areaId).then((x){
      evt.AreaSpawn.dispatch(["area/${_uid}", Position.zero, x["walls"]]);
      evt.ObjSpawn.dispatch(["gate_in/${_uid}", Position.zero, x["gate_in"]]);
      spawnZones4Cubes(x["targetg1_spawn"]);
    });
    spawnDrone(_droneId);
//      updateState("running", false);
//      updateState(_droneId + "/score", 0)
//      updateState(_droneId + "/energy", 500)
//      updateState(_droneId + "/energyMax", 1000)
//      updateState(_droneId + "/boosting", false)
//      updateState(_droneId + "/shooting", false)
//      updateState(_droneId + "/shielding", false)
//      updateState("running", true)
    //evt.CountdownStart.dispatch(["countdown", 45, evt.GameStop, []]);
    evt.Render.dispatch(null);
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
    if (_states["running"] == true && delta500 >= 1) {
      updateEnergy(delta500);
    }
  });

  evt.ContactBeginDroneWall.add((String droneId, String wallId){
    var deferred = new Completer();
    evt.ObjDespawn.dispatch([droneId, {"preAnimName" : "crash", "deferred" : deferred }]);
    deferred.future.then((obj){ spawnDrone(droneId); });
  });
  evt.GameStop.add((){
    updateState("running", false);
  });
}
