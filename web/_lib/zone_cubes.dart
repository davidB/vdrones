part of vdrones;

class Zone4Cubes {
  static final _random = new math.Random();
  static num random(min, max) => _random.nextDouble() * (max - min) + min;
  static num _n0 = 0;

  final List<num> _cells;
  final num _cellr;
  final TimeOut = new Signal();
  final Evt evt;
  final Entities _entities;
  num _n1 = 0;
  final String _zonePrefix;
  int _subZoneOffset = 0;


  Zone4Cubes(EntityProvider4Static zones, this.evt, this._entities) : _zonePrefix = "cube/z${_n0++}_",  _cells = zones.cells,  _cellr = zones.cellr {
    evt.ObjSpawn.dispatch(["targetg1_spawn/${_zonePrefix}", Position.zero, zones]);
    evt.ContactBeginDroneItem.add(onHit);
    TimeOut.add(onTimeout);
    spawnNewCube(1);
  }

  String newCubeId() {
    var t = new StringBuffer();
    t.write(_zonePrefix);
    t.write(_n1++);
    return t.toString(); //(new Date().getTime())
  }

  Position nextPosition() {
    var offset = _subZoneOffset;
    _subZoneOffset = (_subZoneOffset + 4) % _cells.length;
    //1.0 around for wall
    //0.5 half size of generated cube;
    var xmin = _cells[offset + 0] * _cellr + 1 + 0.5;
    var xmax = xmin + _cells[offset + 2] * _cellr - 2 - 0.5;
    var ymin = _cells[offset + 1] * _cellr + 1 + 0.5;
    var ymax = ymin + _cells[offset + 3] * _cellr - 2 - 0.5;

    var x = random(xmin, xmax);
    var y = random(ymin, ymax);
    return new Position(x, y, 0);
  }

  void onHit(String droneId, String objId){
     if (! objId.startsWith(_zonePrefix)) return;
     evt.CountdownStop.dispatch(["${objId}/countdown"]);
     var emax = evt.GameStates.energyMax.v;
     evt.GameStates.energy.v = math.max(evt.GameStates.energy.v + emax /2, emax);
     evt.GameStates.score.v = evt.GameStates.score.v + 1;
     evt.ObjDespawn.dispatch([objId, {"preAnimName" : "none"}]);
     spawnNewCube(1);
  }

  void onTimeout(objId) {
    evt.ObjDespawn.dispatch([objId, {}]);
    spawnNewCube(1);
  }

  void spawnNewCube(num toffset) {
    var nextPos = nextPosition();
    var objId = newCubeId();
    _entities.find('targetg101').then((x){
      evt.CountdownStart.dispatch(["${objId}/spawn", toffset, evt.ObjSpawn, [objId, nextPos, x]]);
      evt.CountdownStart.dispatch(["${objId}/countdown", 7 + toffset, TimeOut, [objId]]);
    });
  }
}

