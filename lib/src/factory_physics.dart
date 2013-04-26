part of vdrones;
class Factory_Physics {

  static PhysicBody newCube() {
    var b  = new b2.BodyDef();
    var s = new b2.CircleShape();
    s.radius = 1;
    var f = new b2.FixtureDef();
    f.shape = s;
    f.isSensor = true;
    f.filter.groupIndex = EntityTypes_ITEM;
    return new PhysicBody(b, [f]);
  }

 static PhysicBody newMobileWall(num dx, num dy) {
    var b = new b2.BodyDef();
    b.type= b2.BodyType.KINEMATIC;
    //TODO optim replace boxes (polyshape) by segment + thick (=> change the display) if w or h is 0
    var shape = new b2.PolygonShape();
    shape.setAsBox(dx/2, dy/2);
    var f = new b2.FixtureDef();
    f.shape = shape;
    f.filter.groupIndex = EntityTypes_WALL;
    return new PhysicBody(b, [f]);
  }

  static PhysicBody cells2boxes2d(num cellr, List<num> cells, groupIndex) {
    var b = new b2.BodyDef();
    b.type = b2.BodyType.STATIC;
    //r.body.nodeIdleTime = double.INFINITY;
    var fdefs = [];
    for(var i = 0; i < cells.length; i+=4) {
      //TODO optim replace boxes (polyshape) by segment + thick (=> change the display)
      var hx = math.max(1, cells[i+2] * cellr) / 2;
      var hy = math.max(1, cells[i+3] * cellr) /2;
      var x = cells[i+0] * cellr + hx;
      var y = cells[i+1] * cellr + hy;
      var shape = new b2.PolygonShape();
      shape.setAsBoxWithCenterAndAngle(hx, hy, new vec2(x, y), 0);
      var f = new b2.FixtureDef();
      f.shape = shape;
      f.filter.groupIndex = groupIndex;
      fdefs.add(f);
    }
    return new PhysicBody(b, fdefs);
  }

  static PhysicBody cells2circles2d(num cellr, List<num> cells, double radius, int groupIndex) {
    var b = new b2.BodyDef();
    b.type = b2.BodyType.STATIC;
    var fdefs = [];
    for(var i = 0; i < cells.length; i+=4) {
      for (var x = cells[i+0]; x < (cells[i+0] + cells[i+2]); x++) {
        for (var y = cells[i+1]; y < (cells[i+1] + cells[i+3]); y++) {
          var s = new b2.CircleShape();
          s.radius = radius * cellr/2;
          s.position.x = (x + 0.5 ) * cellr;
          s.position.y = (y + 0.5 ) * cellr;
          var f = new b2.FixtureDef();
          f.shape = s;
          f.isSensor = true;
          f.filter.groupIndex = groupIndex;
          fdefs.add(f);
        }
      }
    }
    return new PhysicBody(b, fdefs);
  }

  static PhysicBody newDrone() {
    var bdef = new b2.BodyDef();
    bdef.linearDamping = 2.5;
    bdef.type = b2.BodyType.DYNAMIC;
    var s = new b2.PolygonShape();
    s.setFrom([new vec2(3, 0), new vec2(-1, 2), new vec2(-1, -2)], 3);
    var f = new b2.FixtureDef();
    f.shape = s;
    //s.sensor = false;
    f.filter.groupIndex = EntityTypes_DRONE;
    return new PhysicBody(bdef, [f]);
  }

}


