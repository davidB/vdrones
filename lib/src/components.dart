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

class DroneControl implements Component {
  double forward = 0.0;
  double turn = 0.0;

  DroneControl._();
  static _ctor() => new DroneControl._();
  factory DroneControl() {
    var c = new Component(DroneControl, _ctor);
    return c;
  }
}
class Generated implements Component {
  Entity generator;

  Generated._();
  static _ctor() => new Generated._();
  factory Generated(Entity generator) {
    var c = new Component(Generated, _ctor);
    c.generator = generator;
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

class DroneGenerator implements Component {
  // number of drone to generate
  num nb;
  int nextPointsIdx = 0;
  List<vec3> points;

  DroneGenerator._();
  static _ctor() => new DroneGenerator._();
  factory DroneGenerator(List<vec3> points, num nb) {
    var c = new Component(DroneGenerator, _ctor);
    c.nb = nb;
    c.nextPointsIdx = 0;
    c.points = points;
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
class PlayerFollower implements Component {
  vec3 targetTranslation;

  PlayerFollower._();
  static _ctor() => new PlayerFollower._();
  factory PlayerFollower(vec3 targetTranslation) {
    var c = new Component(PlayerFollower, _ctor);
    c.targetTranslation = targetTranslation;
    return c;
  }
}


// Technics

class Transform implements Component {
  vec3 position3d;
  vec3 rotation3d;
  vec3 scale3d;

  // 2d view
  vec2 _position2d = new vec2.zero();
  double get angle => rotation3d.z;
  set angle(double v) => rotation3d.z = v;
  vec2 get position {
    _position2d.x = position3d.x;
    _position2d.y = position3d.y;
    return _position2d;
  }
  set position(vec2 v) {
    position3d.x = v.x;
    position3d.y = v.y;
  }

  Transform._();
  static _ctor() => new Transform._();
  factory Transform.w2d(num x, num y, num a) {
    return new Transform.w3d(new vec3(x, y, 0), new vec3(0,0,a));
  }
  factory Transform.w3d(vec3 position, [vec3 rotation, vec3 scale]) {
    var c = new Component(Transform, _ctor);
    c.position3d = position;
    c.rotation3d = (rotation == null) ? new vec3(0,0,0) : rotation;
    c.scale3d = (scale == null) ? new vec3(1,1,1) : scale;
    return c;
  }
  /// this method mofidy the Transform (usefull for creation)
  /// return this
  Transform lookAt(vec3 target, [vec3 up]) {
    up = (up == null) ? new vec3(0.0, 1.0, 0.0) : up;
    var m = makeViewMatrix(position3d, target, up).getRotation();
    // code from (euler order XYZ)
    // https://github.com/mrdoob/three.js/blob/master/src/math/Vector3.js
    rotation3d.y = math.asin( clamp( m.col0.z, -1.0 ,1.0 ) );
    if ( m.col0.z.abs() < 0.99999 ) {
      rotation3d.x = math.atan2( - m.col1.z, m.col2.z );
      rotation3d.z = math.atan2( - m.col0.y, m.col0.x );
    } else {
      rotation3d.x = math.atan2( m.col2.y, m.col1.y );
      rotation3d.z = 0.0;
    }
    return this;
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

