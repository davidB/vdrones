library vdrones;


import 'package:logging/logging.dart';
import 'package:box2d/box2d_browser.dart' hide Position;
import 'dart:async';
import 'dart:math' as math;
import 'dart:json' as JSON;
import 'dart:html';
import 'dart:svg' as svg;
import 'package:js/js.dart' as js;

import 'utils.dart';

part 'animations.dart';
part 'controls.dart';
part 'entities.dart';
part 'events.dart';
part 'gameplay.dart';
part 'layer2d.dart';
part 'periodic.dart';
part 'physics.dart';
part 'renderer.dart';
part 'zone_cubes.dart';

Evt setup() {

  var evt = new Evt();
  var devMode = true; //document.location.href.indexOf('dev=true') > -1;

  var container = document.query('#layers');
  if (container == null) throw new StateError("#layers not found");

//  Stage4Periodic(evt)
//  Rules4Countdown(evt)
//  Rules4TargetG1(evt)
//  Stage4GameRules(evt)
//  Stage4Physics(evt)
//  Stage4UserInput(evt)
//  Stage4Animation(evt)
  setupPeriodic(evt);
  setupGameplay(evt);
  setupPhysics(evt);
  var animator  = setupAnimations(evt);
  setupRenderer(evt, container, animator);
  setupLayer2D(evt, document.query('#game_area'));
  setupControls(evt);
  //  if (devMode) {
//    Stage4DevMode(evt);
//    Stage4LogEvent(evt, ['Init', 'SpawnObj', 'DespawnObj', 'BeginContact', 'Start', 'Stop', 'Initialized']);
//    Stage4DatGui(evt);
//  }

  //ring.push(evt.Start); //TODO push Start when ready and user hit star button
  var _running = false;
  evt.GameStop.add((){
    _running = false;
  });
  evt.GameStart.add(() {
    _running = true;
    var tickArgs = [0, 0];
    var lastDelta500 = -1;
    void loop(num highResTime) {
      // loop on request animation loop
      // - it has to be at the beginning of the function
      // - @see http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
      //RequestAnimationFrame.request(loop);
      // note: three.js includes requestAnimationFrame shim
      //setTimeout(function() { requestAnimationFrame(loop); }, 1000/30);

      var t = highResTime; //new Date().getTime();
      var delta500 = 0;
      if (lastDelta500 == -1) {
        lastDelta500 = t;
        delta500 = 0;
        print("init ${t}");
      }
      var d = (t - lastDelta500) / 500;
      if (d >=  1) {
        lastDelta500 = t;
        delta500 = d;
      }
      tickArgs[0] = t;
      tickArgs[1] = delta500;
      evt.Tick.dispatch(tickArgs);
      evt.Render.dispatch(null);
      if (_running) {
        window.requestAnimationFrame(loop);
      }
    };
    window.requestAnimationFrame(loop);
  });
  return evt;
}
