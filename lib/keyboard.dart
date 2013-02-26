library vdrones_keyboard;

import 'dart:html';
import 'events.dart';

typedef void Action(Evt evt);

class KeyCtrl {
  var codes = [];
  var label = "";
  var active = false;
  Action start;
  Action stop;

  KeyCtrl({this.codes, this.label, this.start, this.stop});
}


void setupKeyboard(Evt evt) {
  var _droneId = null;


  var _keys = [
    new KeyCtrl(
      codes: [ KeyCode.UP, KeyCode.W, KeyCode.Z ],
      label: 'Forward',
      start: (evt){ evt.EvtReq.dispatch([evt.BoostShipStart, [_droneId]]); },
      stop: (evt){ evt.EvtReq.dispatch([evt.BoostShipStop, [_droneId]]); }
    ),
    new KeyCtrl(
      codes: [ KeyCode.LEFT, KeyCode.A, KeyCode.Q ],
      label: 'Rotate Left',
      start: (evt){evt.EvtReq.dispatch( [evt.RotateShipStart, [_droneId, 0.5]]);},
      stop: (evt){evt.EvtReq.dispatch( [evt.RotateShipStop, [_droneId]]);}
    ),
    new KeyCtrl(
      codes: [KeyCode.RIGHT, KeyCode.D],
      label: 'Rotate Right',
      start: (evt){ evt.EvtReq.dispatch([ evt.RotateShipStart, [_droneId, -0.5]]); },
      stop: (evt){ evt.EvtReq.dispatch( [ evt.RotateShipStop, [_droneId]]); }
    ),
    new KeyCtrl(
      codes: [KeyCode.SPACE],
      label: 'Shoot',
      start: (evt){ evt.EvtReq.dispatch( [ evt.ShootingStart, [_droneId]]); },
      stop: (evt){ evt.EvtReq.dispatch( [ evt.ShootingStop, [_droneId]]); }
    )
  ];
  var _subUp, _subDown;

  void bindShipControl(droneId){
    _droneId = droneId;
    _subUp = document.onKeyUp.listen((KeyboardEvent e) {
      _keys.forEach((keyCtrl){
        if (keyCtrl.codes.contains(e.keyCode)) {
          keyCtrl.active = false;
          keyCtrl.stop(evt);
        }
      });
    });
    _subDown = document.onKeyDown.listen((KeyboardEvent e) {
      _keys.forEach((keyCtrl){
        if (keyCtrl.codes.contains(e.keyCode) && !keyCtrl.active) {
          keyCtrl.active = true;
          keyCtrl.start(evt);
        }
      });
    });
  };

  void diseableControl() {
    _keys.forEach((keyCtrl) {
      if(keyCtrl.active) {
        keyCtrl.active = false;
        keyCtrl.stop(evt);
      }
    });
    if (_subUp != null) _subUp.cancel();
    if (_subDown != null) _subDown.cancel();
  }

  evt.GameInit.add((areaId) => diseableControl());
  evt.GameStop.add(diseableControl);
  evt.SetLocalDroneId.add(bindShipControl);
}

