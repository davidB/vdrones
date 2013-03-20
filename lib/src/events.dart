part of vdrones;

class Signal {
  final _fcts = new List<Function>();

  void add(Function fct) {
    _fcts.add(fct);
  }

  void dispatch(List args) {
    for(var f in _fcts) {
      Function.apply(f, args);
    }
  }
}

class State<E> {
  final _fcts = new List<Function>();
  E _v;

  void add(Function fct) {
    _fcts.add(fct);
  }

  get v => _v;
  set v(E v) {
    if (v == _v) return;
    _v = v;
    for(var f in _fcts) {
      f(v);
    }
  }

  State(E v) : _v = v;
}

class States {
  final userId = new State<String>("");
  final progressMax = new State<num>(0);
  final progressCurrent = new State<num>(0);

  // about local drone
  final score = new State<num>(0);
  final energy = new State<num>(0);
  final energyMax = new State<num>(0);
  final boosting = new State<bool>(false);

  //var energyRatio = ko.computed((()-> @energy() / @energyMax()), this)

  var countdown = new State<num>(60);
  //var shieldActive = false;
  //var fireActive = false;

}

class Evt {
  final GameStates = new States();

  final Error = new Signal();
  final GameInit = new Signal();
  final GameInitialized = new Signal();
  final GameStart= new Signal(); //
  final GameStop= new Signal(); //#{
  final DevMode = new Signal(); //
  final Tick= new Signal(); //#(t, delta500) ->
  final Render= new Signal(); //
  //final ValUpdate= new Signal(); //#(key, value) -> {
  //final ValInc= new Signal(); //#(key, inc) -> {
  final EvtReq= new Signal(); //#(signal, arguments) -> {
  final PeriodicEvtDel= new Signal(); //#(id) -> {
  final PeriodicEvtAdd= new Signal(); //#(id, interval, signal, arguments) -> {
  final CountdownStart= new Signal(); //#(key, timeout, signal, arguments) -> {
  final CountdownStop= new Signal(); //#(key) -> {
  final SetLocalDroneId= new Signal(); //#(objId) -> {
  final HudSpawn= new Signal(); //#(objId, domElem) -> {
  final HudDespawn= new Signal(); //#(objId) -> {
  final AreaSpawn= new Signal(); //#(objId, pos, gpof) -> {
  final ShootingStart= new Signal(); //#(emitterId) -> {
  final ShootingStop= new Signal(); //#(emitterId) -> {
  final FireBullet= new Signal(); //#(emitterId) -> {
  final ObjSpawn= new Signal(); //#(objId, pos, gpof, options) -> {
  final ObjDespawn= new Signal(); //#(objId, options) -> {
  final ObjMoveTo= new Signal(); //#(objId, pos, acc) -> {
  final SetupDatGui= new Signal(); //#(setup) -> {
  final BoostShipStop= new Signal(); //#(objId) -> {
  final BoostShipStart= new Signal(); //#(objId) -> {
  final RotateShipStart= new Signal(); //#(objId, angleSpeed) -> {
  final RotateShipStop= new Signal(); //#(objId) -> {
  final ContactBeginDroneItem= new Signal(); //#(objId0, objId1) -> {
  final ContactBeginDroneWall= new Signal(); //#(objId0, objId1) -> {
}


class Position {
  static Position zero = new Position(0,0,0);

  num x, y, a;

  Position(this.x, this.y, this.a);
}