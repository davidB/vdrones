part of vdrones;

// Kind
class Area extends Component {
  final String name;

  Area(this.name);
}

class Chronometer extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Chronometer);
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
  List<Polygone> subZones;
  int subZoneOffset = 0;
  int nb = 1;

  CubeGenerator(subZones0) : subZones = subZones0.toList(growable:false);
}

class Attraction extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Attraction);
  Vector3 attractor;
}
class Dissolvable extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Dissolvable);
  double ratio;
}

class DroneGenerator extends Component {
  /// score of drone to generate
  List<int> scores;
  int nextPointsIdx = 0;
  List<GateIn> gateIns;

  DroneGenerator(gateIns, this.scores) : this.gateIns = gateIns.toList(growable: false);
}

class DroneNumbers extends Component {
  int energy = 500;
  int energyMax = 1000;
  ///forward acceleration [100,500]
  double accf = 150.0;
  ///lateral (turn) acceleration
  double accl = 50.0;
  int score = 0;
  int hit = 0;
  int hitLastTime = 0;

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

class CameraFollower extends Component {
  static final CT = ComponentTypeManager.getTypeFor(CameraFollower);
  static const TOP = 0;
  static const TPS = 1;
  static const FPS = 2;
  glf.CameraInfo info;
  Aabb3 focusAabb;
  final Vector3 targetTranslation = new Vector3.zero();
  int _mode;
  get mode => _mode;
  set mode(int v) {
    switch(v) {
      case TOP :
        _mode = 0;
        targetTranslation.setValues(0.0, 0.0, 80.0);
        break;
      case TPS :
        _mode = 1;
        targetTranslation.setValues(-10.0, 0.0, 2.0);
        break;
      case FPS :
        _mode = 2;
        targetTranslation.setValues(-0.01, 0.0, 0.0);
        break;
    }
  }

}
