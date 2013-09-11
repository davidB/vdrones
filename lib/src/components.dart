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
  List<num> rects;
  int subZoneOffset = 0;
  int nb = 1;

  CubeGenerator(this.rects);
}

class DroneGenerator extends Component {
  /// score of drone to generate
  List<int> scores;
  int nextPointsIdx = 0;
  List<Vector3> points;

  DroneGenerator(this.points, this.scores);
}

class DroneNumbers extends Component {
  int energy = 500;
  int energyMax = 1000;
  ///forward acceleration
  double accf = 100.0;
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
  glf.CameraInfo info;
  Aabb3 focusAabb;
  final Vector3 targetTranslation = new Vector3.zero();
  bool rotate = false;

  setup(int reqMode) {
    var follower = this;
    switch(reqMode) {
      case 1 :
        follower.rotate = false;
        follower.targetTranslation.setValues(0.0, 0.0, 80.0);
        break;
      case 2 :
        follower.rotate = true;
        follower.targetTranslation.setValues(-10.0, 0.0, 2.0);
        break;
      case 3 :
        follower.rotate = true;
        follower.targetTranslation.setValues(-0.01, 0.0, 0.0);
        break;
    }
  }

}
