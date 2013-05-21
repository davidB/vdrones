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

  static PhysicBody newBoxes2d(List<num> rects, groupIndex) {
    var b = new b2.BodyDef();
    b.type = b2.BodyType.STATIC;
    //r.body.nodeIdleTime = double.INFINITY;
    var fdefs = [];
    for(var i = 0; i < rects.length; i+=4) {
      //TODO optim replace boxes (polyshape) by segment + thick (=> change the display)
      var shape = new b2.PolygonShape();
      shape.setAsBoxWithCenterAndAngle(rects[i+2], rects[i+3], new vec2(rects[i+0], rects[i+1]), 0);
      var f = new b2.FixtureDef();
      f.shape = shape;
      f.filter.groupIndex = groupIndex;
      fdefs.add(f);
    }
    return new PhysicBody(b, fdefs);
  }

  static PhysicBody newCircles2d(List<num> rects, double radiusRatio, int groupIndex) {
    var b = new b2.BodyDef();
    b.type = b2.BodyType.STATIC;
    var fdefs = [];
    for(var i = 0; i < rects.length; i+=4) {
      var s = new b2.CircleShape();
      s.radius = radiusRatio * math.min(rects[i+2], rects[i+3]);
      s.position.x = rects[0];
      s.position.y = rects[1];
      var f = new b2.FixtureDef();
      f.shape = s;
      f.isSensor = true;
      f.filter.groupIndex = groupIndex;
      fdefs.add(f);
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


