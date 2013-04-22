part of vdrones;

// Kind
class Area extends Component {
  final String name;

  Area(this.name);
}

class Chronometer extends Component {
  int millis;

  Chronometer(int start) : this.millis = start;
}

class DroneControl extends Component {
  double forward = 0.0;
  double turn = 0.0;

  DroneControl();
}
class Generated extends Component {
  final Entity generator;

  Generated(this.generator);
}

class CubeGenerator extends Component {
  num cellr;
  List<num> cells;
  int subZoneOffset = 0;
  int nb = 1;

  CubeGenerator(this.cellr, this.cells);
}

class DroneGenerator extends Component {
  /// score of drone to generate
  List<int> scores;
  int nextPointsIdx = 0;
  List<vec3> points;

  DroneGenerator(this.points, this.scores);
}

class DroneNumbers extends Component {
  int energy = 500;
  int energyMax = 1000;
  double acc = 5500.0;
  double angularv = 210.0;
  int score = 0;

  DroneNumbers();
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
class PlayerFollower extends Component {
  vec3 targetTranslation;

  PlayerFollower(this.targetTranslation);
}


// Technics

class Transform extends ComponentPoolable {
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
    var c = new Poolable.of(Transform, _ctor) as Transform;
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


