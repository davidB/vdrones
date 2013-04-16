part of vdrones;

const Z_HIDDEN = -1000;

typedef Future<dynamic> Animate(Animator animator, dynamic obj3d);
typedef num Interpolate(double ratio, num change, num baseValue);

//final THREE = (js.context as dynamic).THREE;

class Animator {
  //final _anims = new SimpleLinkedList<AnimEntry>();
  final _anims = new LinkedBag<_AnimEntry>();

  double _lastTime = 0.0;
  var ll = -1;

  void start(OnUpdate onUpdate, {OnComplete onComplete : null, double delay : 0.0}) {
    var anim = new _AnimEntry();
    anim._onUpdate = onUpdate;
    if (onComplete != null) {
      anim._onComplete = onComplete;
    }
    anim.t0 = _lastTime + delay;
    _anims.add(anim);
  }

  void update(double time) {
    _lastTime = time;
    var d = 0;
    _anims.iterateAndRemove((anim){
      var cont = (anim.t0 <= _lastTime)? anim._onUpdate(time, anim.t0) : true;
      if (!cont) {
        anim._onComplete(time, anim.t0);
      }
      return cont;
    });
  }
}



Animator setupAnimations(Evt evt) {
  var animator = new Animator();
  //TODO refactor the setup of explode (should be created on init, but not at first demand)
  Animations.explode = new Explode(250);

  evt.Tick.add((t, delta500){
    animator.update(t);
  });

  return animator;
}

//
//class ShaderAttribute {
//  String type;
//  var value;
//  bool needsUpdate = false;
//  String boundTo;
//  dynamic operator [](index) => false;
//  void operator []=(index, value){}
//  bool createUniqueBuffers = false;
//  int size = 0;
//  Float32Array array = null;
//  three.Buffer buffer;
//}
