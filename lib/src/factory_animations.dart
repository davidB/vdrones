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
  static Animation newRotateXYEndless() {
    return new Animation()
      ..onTick = (Entity e, num t, num t0){
        var r = e.getComponent(RenderableCache.CT);
        if (r == null || r.v == null || r.v.geometry.transforms == null) return false;
        var transform = r.v.geometry.transforms;
        r.v.geometry.normalMatrixNeedUpdate = true;
        //transform.setIdentity();
        var rot = (t-t0)/3000 * 2 * math.PI;
        transform.rotateX(rot);
        transform.rotateY(2 * rot);
        return true;
      }
      ;
  }

  static Animation newScaleOut([OnComplete onComplete = onNoop]) {
    return new Animation()
      ..onTick = (Entity e, double t, double t0){
        var r = e.getComponent(RenderableCache.CT);
        if (r == null || r.v == null || r.v.geometry.transforms == null) return false;
        var transform = r.v.geometry.transforms;
        r.v.geometry.normalMatrixNeedUpdate = true;
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

  static Animation newScaleIn() {
    return new Animation()
      ..onTick = (Entity e, double t, double t0){
        var r = e.getComponent(RenderableCache.CT);
        if (r == null || r.v == null || r.v.geometry.transforms == null) return false;
        var transform = r.v.geometry.transforms;
        r.v.geometry.normalMatrixNeedUpdate = true;
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
/*
  static Future<dynamic> up(Animator animator,  dynamic obj3d) {
    var r= new Completer();
    var u = (num t, num t0){
      var dt = math.min(1500, t - t0);
      js.scoped((){
        //obj3d.position.add(obj3d.up);
      });
      return dt < 1500;
    };
    var c = (num t, num t0){ r.complete(obj3d); };
    animator.start(u, onComplete : c);
    return r.future;
  }
*/

//  static var explode = null;

  static Animation newExplodeOut() {
    return new Animation()
//      ..onTick = (Entity e, double t, double t0){
//        var cont = (t - t0) < 2000;
//        if (cont) js.scoped((){
//          var runningTime = (t - t0)/1000;
//          runningTime = runningTime - (runningTime/6.0).floor() *6.0;
//          var r3d = (e.getComponent(renderableCacheCT) as RenderableCache);
//          assert(r3d != null);
//          if (r3d != null) r3d.obj.material.uniforms["time"].value = runningTime;
//        });
//        return cont;
//      }
    ;
  }
}



