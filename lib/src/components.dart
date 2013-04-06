part of vdrones;

// Kind
class Area implements Component {
  String name;

  Area._();
  static _ctor() => new Area._();
  factory Area(String name) {
    var c = new Component(Area, _ctor);
    c.name = name;
    return c;
  }
}

class Drone implements Component {
  String name;

  Drone._();
  static _ctor() => new Drone._();
  factory Drone(String name) {
    var c = new Component(Drone, _ctor);
    c.name = name;
    return c;
  }
}
class CubeGenerator implements Component {
  num cellr;
  List<num> cells;

  CubeGenerator._();
  static _ctor() => new CubeGenerator._();
  factory CubeGenerator(num cellr, List<num> cells) {
    var c = new Component(CubeGenerator, _ctor);
    c.cellr = cellr;
    c.cells = cells;
    return c;
  }
}
/*
class StaticWalls implements Component {
  StaticWalls._();
  factory StaticWalls() {
    var c = new Component(StaticWalls, StaticWalls._);
    return c;
  }
}

class Cube implements Component {
  String name;

  Cube._();
  factory Cube() {
    var c = new Component(Area, Area._);
    return c;
  }
}
*/


// Technics

class Position implements Component {
  num x, y, a;

  Position._();
  static _ctor() => new Position._();
  factory Position(num x, num y, num a) {
      var c = new Component(Position, _ctor);
      c.x = x;
      c.y = y;
      return c;
  }
  //static Position _constructor() => new Position._();
}

class PhysicBody implements Component {
  b2.BodyDef bdef;
  List<b2.FixtureDef> fdefs;

  PhysicBody._();
  static _ctor() => new PhysicBody._();
  factory PhysicBody(b2.BodyDef b, List<b2.FixtureDef> f) {
      var c = new Component(PhysicBody, _ctor);
      c.bdef = b;
      c.fdefs = f;
      return c;
  }
}

class Renderable3D implements Component {
  var obj;

  Renderable3D._();
  static _ctor() => new Renderable3D._();
  factory Renderable3D(v) {
      var c = new Component(Renderable3D, _ctor);
      c.obj = v;
      return c;
  }
}
