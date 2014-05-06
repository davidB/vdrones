part of vdrones;

class Factory_Animations {
  //TODO sfx for grab cube : 0,,0.01,,0.4453,0.3501,,0.4513,,,,,,0.4261,,0.6284,,,1,,,,,0.5
  //TODO sfx for explosion : 3,,0.2847,0.7976,0.88,0.0197,,0.1616,,,,,,,,0.5151,,,1,,,,,0.72

  static Animation newDelay(num millis) {
    return new Animation()
      ..onTick = (Entity e, double t, double t0){
        return (t - t0) <= millis;
      }
    ;
  }

  static final Qx = new Quaternion.axisAngle(new Vector3(1.0, 0.0, 0.0), math.PI);
  static final Qy = new Quaternion.axisAngle(new Vector3(0.0, 1.0, 0.0), math.PI);

  static _mult(Quaternion o1, Quaternion o2, Quaternion out, double s1, double s2) {
    double _w = o1.storage[3] * s1;
    double _z = o1.storage[2];
    double _y = o1.storage[1];
    double _x = o1.storage[0];
    double ow = o2.storage[3] * s2;
    double oz = o2.storage[2];
    double oy = o2.storage[1];
    double ox = o2.storage[0];
    out.x = _w * ox + _x * ow + _y * oz - _z * oy;
    out.y = _w * oy + _y * ow + _z * ox - _x * oz;
    out.z = _w * oz + _z * ow + _x * oy - _y * ox;
    out.w = _w * ow - _x * ox - _y * oy - _z * oz;
  }

  static Animation newRotateXYEndless() {
    return new Animation()
      ..onTick = (Entity e, num t, num t0){
        var r = e.getComponent(Orientation.CT) as Orientation;
        if (r == null) return false;
        var rot = math.sin(((t  % 4000) / 2000) * math.PI);
        _mult(Qx, Qy, r.q, rot, rot);
        //print("orientation : " + r.q.toString());
        return true;
      }
      ;
  }

  static Animation newDissolve() {
    return new Animation()
      ..onTick = (Entity e, num t, num t0){
        var dis = e.getComponent(Dissolvable.CT) as Dissolvable;
        if (dis == null) return false;
        var dt = math.min(800, t - t0);
        dis.ratio = ease.inCubic(dt/800, 1.0, 0.0);
        return dt < 800;
      }
      ;
  }

  static Animation newScaleOut([OnComplete onComplete = onNoop]) {
    return new Animation()
      ..onTick = (Entity e, double t, double t0){
        var r = e.getComponent(RenderableCache.CT) as RenderableCache;
        if (r == null || r.v == null || r.v.ext['transform'] == null) return false;
        var transform = r.v.ext['transform'];
        var dt = math.min(300, t - t0);
        var ratio = dt/300;
        //transform.setIdentity();
        transform.scale(
          ease.inQuad(ratio, -1, 1),
          ease.inQuad(ratio, -1, 1),
          ease.inQuad(ratio, -1, 1)
        );
        return dt < 300;
      }
      ..onEnd = onComplete
      ;
  }

  static Animation newCubeAttraction([OnComplete onComplete = onNoop]) {
    return new Animation()
      ..onTick = (Entity e, double t, double t0){
        var r = e.getComponent(RenderableCache.CT) as RenderableCache;
        if (r == null || r.v == null || r.v.ext['transform'] == null) return false;
        var transform = r.v.ext['transform'];
        var dt = math.min(300, t - t0);
        var ratio = dt/300;
        //transform.setIdentity();
        transform.scale(
          ease.inQuad(ratio, -1, 1),
          ease.inQuad(ratio, -1, 1),
          ease.inQuad(ratio, -1, 1)
        );
        var att = e.getComponent(Attraction.CT) as Attraction;
        if (att != null && att.attractor != null) {
          var attv = att.attractor;
          var v3 = transform.getTranslation();
          transform.setTranslationRaw(
              ease.inQuad(ratio, attv.x - v3.x, v3.x),
              ease.inQuad(ratio, attv.y - v3.y, v3.y ),
              ease.inQuad(ratio, attv.z - v3.z, v3.z)
          );
        }

        return dt < 300;
      }
      ..onEnd = onComplete
      ;
  }

  static Animation newScaleIn() {
    return new Animation()
      ..onTick = (Entity e, double t, double t0){
        var r = e.getComponent(RenderableCache.CT) as RenderableCache;
        if (r == null || r.v == null || r.v.ext['transform'] == null) return false;
        var transform = r.v.ext['transform'];
        var dt = math.min(300, t - t0);
        var ratio = dt/300;
        //transform.setIdentity();
        transform.scale(
          ease.inQuad(ratio, 1, 0),
          ease.inQuad(ratio, 1, 0),
          ease.inQuad(ratio, 1, 0)
        );
        return dt < 300;
      }
      ;
  }
}



