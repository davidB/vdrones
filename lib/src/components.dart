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
  List<vec3> points;

  DroneGenerator(this.points, this.scores);
}

class DroneNumbers extends Component {
  int energy = 500;
  int energyMax = 1000;
  double acc = 5500.0;
  double angularv = 210.0;
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
class PlayerFollower extends Component {
  vec3 targetTranslation;

  PlayerFollower(this.targetTranslation);
}

