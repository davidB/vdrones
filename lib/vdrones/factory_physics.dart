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
    var ps = new Particles(nbPoints, radius0: 0.0, inertia0: 0, withCollides: true, collide0: collide, isSim0: false);
    //var fs = new Forces();
    var ss = new Segments();

    var p0 = 0;
    shapes.forEach((shape){
      var points = shape.points.toList(growable: false);
      for(var j = 0; j < points.length; ++j) {
        ps.position3d[p0+j].setFrom(points[j]);
      }
      for(var j = 0; j < points.length; ++j) {
        // extern shape
        ss.add(new Segment(ps, p0+j, p0 + ((j+1) % points.length), collide));
        //fs.add(new Force_Spring(s, 10.0, 0.0));
        // TODO inner axes ? (need tessellation)
      }
      p0 += points.length;
    });
    ps.copyPosition3dIntoPrevious();
    ps.extradata = new ColliderInfo()..group = groupIndex;
    return [ps,ss];
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
    var ps = new Particles(4, radius0: 0.0, withAccs:true, withCollides: true, collide0: collide, inertia0: 0.9, withColors: true, color0: 0xff0000ff, isSim0: true);
    ps.position3d[DRONE_PCENTER].setValues(0.0, 0.0, 2.0);
    ps.position3d[DRONE_PFRONT].setValues(3.0, 0.0, 0.8);
    ps.position3d[DRONE_PBACKR].setValues(-1.0, -1.0, 1.0);
    ps.position3d[DRONE_PBACKL].setValues(-1.0, 1.0, 1.0);
    ps.copyPosition3dIntoPrevious();
    ps.extradata = new ColliderInfo()..group = EntityTypes_DRONE;
    var ss = new Segments();
    var fs = new Forces();
    //propulsion accessible by fs.actions[DRONE_Pxxx].
    for(var i=0; i < 4; i++) {
      fs.actions.add(new Force_Constante(ps, i, new Vector3.zero()));
    }
    var stiffness = 100.0;
    var damping = 0.2;
    // inner axes
    for(var i=1; i < 4; i++) {
      var s = new Segment(ps, 0, i, 0);
      fs.add(new Force_Spring(s, stiffness, damping));
    }
    // extern shape
    for(var i=0; i < 3; i++) {
      var s = ss.add(new Segment(ps, 1+ i, 1 + ((i+1) % 3), collide));
      fs.add(new Force_Spring(s, stiffness, damping)..stiffnessRatioLonger = 20.0);
    }
    // shape over floor
    for(var i=0; i < 4; i++) {
      fs.add(new Force_SpringZ(ps, i, 50.0, 0.0));
    }
    return [ps, ss, fs, new Collisions()];
  }

}

class Force_SpringZ extends Force{
  final Particles ps;
  final int i;
  final reaction = false;
  double stiffness;
  double damping;
  double _restZ;

  Force_SpringZ(this.ps, this.i, this.stiffness, this.damping, [restZ = -1]) {
    _restZ = (restZ < 0) ? ps.position3d[i].z : restZ;
  }

//  factory Force_Spring.fromParticles(ps, i1, i2, stiffness, damping, [collide = 0]) {
//    return new Force_Spring(new Segment(ps, i1, i2, collide), stiffness, damping);
//  }

  apply() {
    var a = ps.position3d[i];
    var l = a.z;
    var diff = ( _restZ - l);
    if (diff == 0) return;
    // spring force
    //_fa.setFrom(segment.ps.acc[segment.i1]).add(segment.ps.acc[segment.i2]).scale(0.5);
    //print(_fa.dot(_dir).abs());
    var fs = stiffness * diff;
    // spring damping force
    var fd = ps.position3d[i].z - ps.position3dPrevious[i].z;
    fd = damping * fd;
    ps.acc[i].z += fs + fd;
  }
}
