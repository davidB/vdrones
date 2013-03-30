part of vdrones;

const Z_HIDDEN = -1000;

typedef Future<js.Proxy> Animate(Animator animator, js.Proxy obj3d);
typedef num Interpolate(double ratio, num change, num baseValue);
typedef bool OnUpdate(double t, double t0);
typedef bool OnComplete(double t, double t0);

bool onNoop(num t, num t0){ return false;}

//final THREE = js.context.THREE;

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

class _AnimEntry {
  double t0 = -1.0;
  OnUpdate _onUpdate = onNoop;
  OnComplete _onComplete = onNoop;
}

class Animations {
  //TODO sfx for grab cube : 0,,0.01,,0.4453,0.3501,,0.4513,,,,,,0.4261,,0.6284,,,1,,,,,0.5
  //TODO sfx for explosion : 3,,0.2847,0.7976,0.88,0.0197,,0.1616,,,,,,,,0.5151,,,1,,,,,0.72

  static Future noop(Animator animator, obj3d) => new Future.immediate(obj3d);

  static Future<js.Proxy> rotateXYEndless(Animator animator, js.Proxy obj3d) {
    var r = new Completer();
    var u = (num t, num t0){
      js.scoped((){
      obj3d.rotation.x += 0.01;
      obj3d.rotation.y += 0.02;
      //return obj3d.parent != null;
      });
      return true;
    };
    animator.start(u);
    return r.future;
  }


  static Future<js.Proxy> scaleOut(Animator animator,  js.Proxy obj3d) {
    var r= new Completer();
    var u = (num t, num t0){
      var dt = math.min(300, t - t0);
      var ratio = dt/300;
      js.scoped((){
      obj3d.scale.set(
        Easing.easeInQuad(ratio, -1, 1),
        Easing.easeInQuad(ratio, -1, 1),
        Easing.easeInQuad(ratio, -1, 1)
      );
      });
      return dt < 300;
    };
    var c = (num t, num t0){ r.complete(obj3d); };
    animator.start(u, onComplete : c);
    return r.future;
  }

  static Future<js.Proxy> up(Animator animator,  js.Proxy obj3d) {
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

  static Future<js.Proxy> scaleIn(Animator animator, js.Proxy obj3d) {
    var r= new Completer();
    var u = (num t, num t0){
      var dt = math.min(300, t - t0);
      var ratio = dt/300;
      js.scoped((){
      obj3d.scale.set(
        Easing.easeInQuad(ratio, 1, 0),
        Easing.easeInQuad(ratio, 1, 0),
        Easing.easeInQuad(ratio, 1, 0)
      );
      });
      return dt < 300;
    };
    var c = (num t, num t0){ r.complete(obj3d); };
    animator.start(u, onComplete : c);
    return r.future;
  }

  static var explode = null;

  static Future<js.Proxy> explodeOut(Animator animator, js.Proxy obj3d) {
    var r= new Completer();
    var u = (num t, num t0){
      js.scoped((){
        var runningTime = (t - t0)/1000;
        runningTime = runningTime - (runningTime/6.0).floor() *6.0;
        explode.uniforms["time"].value = runningTime;
      });
      return (t - t0) < 2000;
    };
    var c = (num t, num t0){
      js.scoped((){
        r.complete(obj3d);
        var p = explode.particles.parent;
        if (p != null) p.remove(explode.particles);
      });
    };
    js.scoped((){
      //explode.uniforms["center"].value = obj3d.position.clone();
      explode.particles.position = obj3d.position.clone();
      explode.particles.position.z = 10;
      obj3d.parent.add(explode.particles);
      obj3d.position.z = Z_HIDDEN;
      animator.start(u, onComplete : c);
    });
    return r.future;
  }
}

// based on http://webglplayground.net/?gallery=BeIrChLZoJ
class Explode {
  var particles;

  final random = new math.Random();

  var glsl_vs1 = """
    //uniform vec3 center;
    uniform float time;
    attribute vec3 aPosition;
    attribute vec3 aVelocity;
    attribute vec3 aDirection;
    attribute float aAcceleration;
    attribute float aLifeTime;
    varying vec4 vColor;
    
    void main()
    {
      float t = time;
      vec3 direction = normalize(aDirection);
      vec3 velocity = 30.0*normalize(aVelocity);
      //below two different variations of explosions
      //vec3 velocity = 30.0*(aLifeTime/4.1*length(aVelocity))*normalize(aVelocity);
      //vec3 velocity = 30.0*(abs(3.0*sin(t/20.0))*aLifeTime/4.1*length(aVelocity))*normalize(aVelocity);
      float acceleration = 20.0*aAcceleration;
      //vec3 p = center + aPosition + velocity*t + direction*(acceleration*t*t*0.5);
      vec3 p = aPosition + velocity*t + direction*(acceleration*t*t*0.5);
      gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
      float lifeLeft = 1.0-smoothstep(0.0, aLifeTime, t);
      float ta = t/aAcceleration;
      gl_PointSize = min(12.0, t/aAcceleration);
      vColor = vec4(1.0, pow(1.0-aAcceleration, 6.0), pow((1.0-aAcceleration), 14.0)-0.3, lifeLeft/(2.0*gl_PointSize));
    }
  """;
  var glsl_fs1 = """
    #ifdef GL_ES
    precision highp float;
    #endif
    
    uniform float time;
    varying vec4 vColor;
    void main()
    {
      gl_FragColor = vColor;
    }
  """;
  //http://mathworld.wolfram.com/SpherePointPicking.html
  List<num> randomPointOnSphere() {
    var x1 = (random.nextDouble()-0.5)*2.0;
    var x2 = (random.nextDouble()-0.5)*2.0;
    var ds = x1*x1+x2*x2;
    while (ds>=1) {
      x1 = (random.nextDouble()-0.5)*2.0;
      x2 = (random.nextDouble()-0.5)*2.0;
      ds = x1*x1+x2*x2;
    }
    var ds2 = math.sqrt(1.0-x1*x1-x2*x2);
    var point = [
      2.0*x1*ds2,
      2.0*x2*ds2,
      1.0-2.0*ds
    ];
    return point;
  }

  var uniforms;

  static dynamic a(String s, int l) {
    return js.map({
      'type' : s,
      'value' : new List(l)
    });
  }

  num nParticles;

  Explode(this.nParticles) {
    js.scoped((){
    var THREE = js.context.THREE;
    uniforms = js.retain(js.map({
      "time": { "type" :"f", "value" : 0}
//      "center": { "type" : "v3", "value" : new js.Proxy(THREE.Vector3, 0, 0, 1.0)}
    }));

    var attributes = js.map({
      "aPosition": a("v3", nParticles),
      "aVelocity": a("v3", nParticles),
      "aDirection": a("v3", nParticles),
      "aAcceleration": a("f", nParticles),
      "aLifeTime": a("f", nParticles)
    });
    var material = new js.Proxy(THREE.ShaderMaterial, js.map({
      "uniforms": uniforms,
      "attributes": attributes,
      "vertexShader": glsl_vs1,
      "fragmentShader": glsl_fs1,
      "blending": THREE.AdditiveBlending,
      "transparent": false
      //"depthTest": false
    }));

    var geometry = new js.Proxy(THREE.Geometry);
    var verts = new List(nParticles);
    for (var i=0; i<nParticles; i++) {
      verts[i] = new js.Proxy(THREE.Vector3, 0,0,0);
    }
    geometry.vertices = js.array(verts);
    _reset(attributes);
    particles = js.retain(new js.Proxy(THREE.ParticleSystem, geometry, material));
    });
  }

  void _reset(attributes) {
    final THREE = js.context.THREE;
    for (var i=0; i<nParticles; i++) {
      // position
      var point = randomPointOnSphere();
      attributes["aPosition"].value[i] = new js.Proxy(THREE.Vector3,
                                                        point[0],
                                                        point[1],
                                                        point[2]);

      // velocity
      point = randomPointOnSphere();
      attributes["aVelocity"].value[i] = new js.Proxy(THREE.Vector3,
                                                        point[0],
                                                        point[1],
                                                        point[2]);

      // direction
      point = randomPointOnSphere();
      attributes["aDirection"].value[i] = new js.Proxy(THREE.Vector3,
                                                         point[0],
                                                         point[1],
                                                         point[2]);

      // acceleration
      attributes["aAcceleration"].value[i] = random.nextDouble();
      attributes["aLifeTime"].value[i] = (6.0*(random.nextDouble()*0.3+0.3));
    }
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

class Easing {
  /**
   * Performs a linear.
   */
  static num linear(double ratio, num change, num baseValue) {
    return change * ratio + baseValue;
  }

  // QUADRATIC

  /**
   * Performs a quadratic easy-in.
   */
  static num easeInQuad(double ratio, num change, num baseValue) {
    return change * ratio * ratio + baseValue;
  }

  /**
   * Performs a quadratic easy-out.
   */
  static num easeOutQuad(double ratio, num change, num baseValue) {
    return -change * ratio * (ratio - 2) + baseValue;
  }

  /**
   * Performs a quadratic easy-in-out.
   */
  static num easeInOutQuad(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time + baseValue;

    time--;

    return -change / 2 * (time * (time - 2) - 1) + baseValue;
  }

  // CUBIC

  /**
   * Performs a cubic easy-in.
   */
  static num easeInCubic(double ratio, num change, num baseValue) {
      return change * ratio * ratio * ratio + baseValue;
  }

  /**
   * Performs a cubic easy-out.
   */
  static num easeOutCubic(double ratio, num change, num baseValue) {
    ratio--;
    return change * (ratio * ratio * ratio + 1) + baseValue;
  }

  /**
   * Performs a cubic easy-in-out.
   */
  static num easeInOutCubic(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time * time + baseValue;

    time -= 2;

    return change / 2 * (time * time * time + 2) + baseValue;
  }

  // QUARTIC

  /**
   * Performs a quartic easy-in.
   */
  static num easeInQuartic(double ratio, num change, num baseValue) {
    return change * ratio * ratio * ratio * ratio + baseValue;
  }

  /**
   * Performs a quartic easy-out.
   */
  static num easeOutQuartic(double ratio, num change, num baseValue) {
    ratio--;
    return -change * (ratio * ratio * ratio * ratio - 1) + baseValue;
  }

  /**
   * Performs a quartic easy-in-out.
   */
  static num easeInOutQuartic(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time * time * time + baseValue;

    time -= 2;

    return -change / 2 * (time * time * time * time - 2) + baseValue;
  }

  // QUINTIC

  /**
   * Performs a quintic easy-in.
   */
  static num easeInQuintic(double ratio, num change, num baseValue) {
    return change * ratio * ratio * ratio * ratio * ratio + baseValue;
  }

  /**
   * Performs a quintic easy-out.
   */
  static num easeOutQuintic(double ratio, num change, num baseValue) {
    ratio--;
    return change * (ratio * ratio * ratio * ratio * ratio + 1) + baseValue;
  }

  /**
   * Performs a quintic easy-in-out.
   */
  static num easeInOutQuintic(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time * time * time * time + baseValue;

    time -= 2;

    return change / 2 * (time * time * time * time * time + 2) + baseValue;
  }

  // SINUSOIDAL

  /**
   * Performs a sine easy-in.
   */
  static num easeInSine(double ratio, num change, num baseValue) {
    return -change * math.cos(ratio * (math.PI / 2)) + change + baseValue;
  }

  /**
   * Performs a sine easy-out.
   */
  static num easeOutSine(double ratio, num change, num baseValue) {
    return change * math.sin(ratio * (math.PI / 2)) + baseValue;
  }

  /**
   * Performs a sine easy-in-out.
   */
  static num easeInOutSine(double ratio, num change, num baseValue) {
    return -change / 2 * (math.cos(ratio * math.PI) - 1) + baseValue;
  }

  // EXPONENTIAL

  /**
   * Performs an exponential easy-in.
   */
  static num easeInExponential(double ratio, num change, num baseValue) {
    return change * math.pow(2, 10 * (ratio - 1)) + baseValue;
  }

  /**
   * Performs an exponential easy-out.
   */
  static num easeOutExponential(double ratio, num change, num baseValue) {
    return change * (-math.pow(2, -10 * ratio) + 1) + baseValue;
  }

  /**
   * Performs an exponential easy-in-out.
   */
  static num easeInOutExponential(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * math.pow(2, 10 * (time - 1)) + baseValue;

    time--;

    return change / 2 * (-math.pow(2, -10 * time) + 2) + baseValue;
  }

  // CIRCULAR

  /**
   * Performs a circular easy-in.
   */
  static num easeInCircular(double ratio, num change, num baseValue) {
    return -change * (math.sqrt(1 - ratio * ratio) - 1) + baseValue;
  }

  /**
   * Performs a circular easy-out.
   */
  static num easeOutCircular(double ratio, num change, num baseValue) {
    ratio--;

    return change * math.sqrt(1 - ratio * ratio) + baseValue;
  }

  /**
   * Performs a circular easy-in-out.
   */
  static num easeInOutCircular(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return -change / 2 * math.sqrt(1 - time * time) + baseValue;

    time -= 2;

    return change / 2 * (math.sqrt(1 - time * time) + 1) + baseValue;
  }
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