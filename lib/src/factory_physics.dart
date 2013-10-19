part of vdrones;

const DRONE_PCENTER = 0;
const DRONE_PFRONT = 1;
const DRONE_PBACKR = 2;
const DRONE_PBACKL = 3;
const DRONE_PFRONTL = DRONE_PFRONT;
const DRONE_PFRONTR = DRONE_PFRONT;

class Factory_Physics {
//
//  Iterable<Component> makeLineSegments(List<Vector3> vertices, double stiffness, bool closed) {
//    var ps = genP(vertices.length);
//    for(int i = 0; i < ps.length; ++i) {
//      ps.position3d[i].setFrom(vertices[i]);
//    }
//    ps.copyPosition3dIntoPrevious();
//    var cs = new Constraints();
//    for (var i = 1; i < ps.position3d.length; ++i) {
//      cs.l.add(new Constraint_Distance.fromParticles(ps, i, i-1, stiffness));
//    }
//    if (closed) {
//      cs.l.add(new Constraint_Distance.fromParticles(ps, 0, ps.position3d.length - 1, stiffness));
//    }
//    return [ps, cs];
//  }
//
  Iterable<Component> newCube() {
    var p = new Particles(1, radius0: 0.5, withCollides: true, collide0: 1);
    p.extradata = new ColliderInfo()..group = EntityTypes_ITEM;
    return [p];
  }

//  Iterable<Component> newMobileWall(double x, double y, double dx, double dy, groupIndex) {
//    var collide = 1;
//    var ps = new Particles(5, radius0: 0.0, inertia0: 0, withCollides: true, collide0: collide);
//    ps.position3d[0].setValues(x, y, 0.0);
//    ps.position3d[1].setValues(x-dx, y-dy, 0.0);
//    ps.position3d[2].setValues(x+dx, y-dy, 0.0);
//    ps.position3d[3].setValues(x+dx, y+dy, 0.0);
//    ps.position3d[4].setValues(x-dx, y+dy, 0.0);
//    ps.copyPosition3dIntoPrevious();
//    ps.extradata = new ColliderInfo()..group = groupIndex;
//    var cs = new Constraints();
//    // inner axes
//    for(var i=1; i < 5; i++) {
//      cs.l.add(new Constraint_Distance(new Segment(ps, 0, 1, 0), 1.0));
//    }
//    // extern shape
//    for(var i=0; i < 4; i++) {
//      cs.l.add(new Constraint_Distance(new Segment(ps, 1+i, 1+ ((i+1) % 4), collide), 1.0));
//    }
//    return [ps, cs];
//  }

  Iterable<Component> newPolygones(Iterable<Polygone> shapes, groupIndex) {
    var collide = 1;
    var nbPoints = shapes.fold(0,(acc, x) => acc + x.points.length);
    var ps = new Particles(nbPoints, radius0: 0.0, inertia0: 0, withCollides: true, collide0: collide);
    var cs = new Constraints();

    var p0 = 0;
    shapes.forEach((shape){
      for(var j = 0; j < shape.points.length; ++j) {
        ps.position3d[p0+j].setFrom(shape.points[j]);
      }
      for(var j = 0; j < shape.points.length; ++j) {
        // extern shape
        cs.l.add(new Constraint_Distance(new Segment(ps, p0+j, p0 + ((j+1) % shape.points.length), collide), 1.0));
        // TODO inner axes ? (need tessellation)
      }
      p0 += shape.points.length;
    });
    ps.copyPosition3dIntoPrevious();
    ps.extradata = new ColliderInfo()..group = groupIndex;
    return [ps, cs];
  }

//  Iterable<Component> newBoxes2d(List<double> rects, groupIndex) {
//    var collide = 1;
//    var ps = new Particles(rects.length, radius0: 0.0, withCollides: true, collide0: collide);
//    for(var i = 0; i < rects.length; i+=4) {
//      var ox = rects[i+0];
//      var oy = rects[i+1];
//      var dx = rects[i+2];
//      var dy = rects[i+3];
//      ps.position3d[i+0].setValues(ox+dx, oy+dy, 0.0);
//      ps.position3d[i+1].setValues(ox+dx, oy-dy, 0.0);
//      ps.position3d[i+2].setValues(ox-dx, oy-dy, 0.0);
//      ps.position3d[i+3].setValues(ox-dx, oy+dy, 0.0);
//    }
//    ps.copyPosition3dIntoPrevious();
//    ps.extradata = new ColliderInfo()..group = groupIndex;
//    var cs = new Constraints();
//    for(var j = 0; j < rects.length; j+=4) {
//      // inner axes
//      for(var i=0; i < 2; i++) {
//        cs.l.add(new Constraint_Distance(new Segment(ps, j+i, j + ((i+2) % 4), 0), 1.0));
//      }
//      // extern shape
//      for(var i=0; i < 4; i++) {
//        cs.l.add(new Constraint_Distance(new Segment(ps, j+i, j + ((i+1) % 4), collide), 1.0));
//      }
//    }
//    return [ps, cs];
//  }

  Iterable<Component> newCircles2d(Iterable<Ellipse> ellipses, double radiusRatio, int groupIndex) {
    var ps = new Particles(ellipses.length, withRadius: true, radius0: 1.0, withCollides: true, collide0: 1);
    ellipses.fold(0, (i, e){
      ps.radius[i] = radiusRatio * math.min(e.rx, e.ry);
      ps.position3d[i].setFrom(e.position);
      return i + 1;
    });
    ps.copyPosition3dIntoPrevious();
    ps.extradata = new ColliderInfo()..group = groupIndex;
    return [ps];
  }

  Iterable<Component> newDrone() {
    var collide = 1;
    var ps = new Particles(4, radius0: 0.0, withAccs:true, withCollides: true, collide0: collide, inertia0: 0.9, withColors: true, color0: 0xff0000ff);
    ps.position3d[DRONE_PCENTER].setValues(0.0, 0.0, 2.0);
    ps.position3d[DRONE_PFRONT].setValues(3.0, 0.0, 0.8);
    ps.position3d[DRONE_PBACKR].setValues(-1.0, -1.0, 1.0);
    ps.position3d[DRONE_PBACKL].setValues(-1.0, 1.0, 1.0);
    ps.copyPosition3dIntoPrevious();
    ps.extradata = new ColliderInfo()..group = EntityTypes_DRONE;
    var cs = new Constraints();
    // inner axes
    for(var i=1; i < 4; i++) {
      cs.l.add(new Constraint_Distance(new Segment(ps, 0, i, 0), 1.0));
    }
    // extern shape
    for(var i=0; i < 3; i++) {
      cs.l.add(new Constraint_Distance(new Segment(ps, 1+ i, 1 + ((i+1) % 3), collide), 1.0));
    }
    return [ps, cs, new Collisions()];
  }

}


