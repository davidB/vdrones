library screens;

import 'dart:html';
import 'package:simple_audio/simple_audio.dart';
import 'package:intl/intl.dart';
import 'events.dart';
import 'effects.dart';
import 'dart:js';
import 'dart:convert';

class UiAudioVolume {
  Element _element;
  AudioManager _audioManager;

  var subscriptions = new List();
  set el(Element v) {
    _element = v;
    _bind();
  }

  set audioManager(AudioManager v){
    _audioManager = v;
    _bind();
  }

  _bind() {
    subscriptions.forEach((x) => x.cancel());
    subscriptions.clear();
    if (_element == null || _audioManager == null) return;
    _bind0("#mute", _masterMute(), _changeMasterMute);
    _bind0("#masterVolume", _masterVolume(), _changeMasterVolume);
    _bind0("#musicVolume", _musicVolume(), _changeMusicVolume);
    _bind0("#sourceVolume", _sourceVolume(), _changeSourceVolume);
  }

  _bind0(selector, init, onChange) {
    var el = _element.querySelector(selector);
    if (el.type == "checkbox") el.checked = init;
    else if (el is InputElement) el.value = init.toString();
    else if (el is Element) el.text = init;
    subscriptions.add(el.onChange.listen(onChange));
  }

  _masterMute(){
    if (_audioManager == null) return true;
    return _audioManager.mute;
  }

  _changeMasterMute(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as CheckboxInputElement;
    _audioManager.mute = target.checked;
  }

  _masterVolume(){
    if (_audioManager == null) return "0";
    return _audioManager.masterVolume;
  }

  _changeMasterVolume(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as InputElement;
    _audioManager.masterVolume = double.parse(target.value);
  }

  _musicVolume(){
    if (_audioManager == null) return "0";
    return _audioManager.musicVolume;
  }

  _changeMusicVolume(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as InputElement;
    _audioManager.musicVolume = double.parse(target.value);
  }

  _sourceVolume(){
    if (_audioManager == null) return "0";
    return _audioManager.sourceVolume;
  }

  _changeSourceVolume(e){
    if(_audioManager == null) return;
    if(e.defaultPrevented) return;
    final target = e.target as InputElement;
    _audioManager.sourceVolume = double.parse(target.value);
  }
}



class UiScreenInit {
  Element el;
  var bus;

  var _onPlayEnabled = false;
  var _area = "";
  var _onPlay;

  init() {
    bus.on(eventInGameStatus).listen((x) {
      _onPlayEnabled = (x.kind == IGStatus.INITIALIZED || x.kind == IGStatus.STOPPED);
      _area = x.area;
      update();
    });
    _onPlay = (_){
      bus.fire(eventInGameReqAction, IGAction.PLAY);
    };
  }

  update(){
    if (el == null) return;
    el.querySelector("#msgConnecting").style.opacity = _onPlayEnabled ? "0" : "1";
    el.querySelector("[data-text=area]").text = _area;
    var btn = el.querySelector(".play");
    (btn as ButtonElement).disabled = !_onPlayEnabled;
    btn.onClick.first.then(_onPlay);
  }
}

class ScreenBuy {
  Element el;
  var _state = 0;
  var _defsF;
  var playerId = "me"; //gameservice.auth.token.userId
  var auth;

  init() {
    el.querySelector("button.buy").onClick.listen((_){
      _askJwt();
      _state = 1;
    });
  }

  reload() {
    _state = 0;
    update();
  }

  update() {
    var s = ShowHide.getState(el);
    //if (s == ShowHideState.HIDING || s == ShowHideState.HIDDEN) return;
    if (auth.token == null){
      _showPage("login");
      return;
    }
    if(_state == 0) {
      _showPage("ready");
    }
    if(_state == 1) {
      _showPage("loading");
    }
    if(_state == 1) {
      _showPage("thanks");
      _state = 0;
    }
    if (_state == -1) {
      _showPage("bad");
    }
  }

  _showPage(clazz) {
    el.children.forEach((e){
      var cs = e.classes;
      if (cs.contains("subpage")) {
        if (e.classes.contains(clazz)) {
          ShowHide.show(e);
        } else {
          ShowHide.hide(e);
        }
      }
    });
  }

  _askJwt() {
    var url = "/api/buy_bill";
    var amount = (el.querySelector("input.amount") as InputElement).value;
    var params = JSON.encode({
      "amount" : amount
    });
//    var requestHeaders = {
//      "Content-type": 'application/json; charset=utf-8'
//    };
    //Send the proper header information along with the request

    //http.setRequestHeader("Content-length", params.length);
    //http.setRequestHeader("Connection", "close");
    var http = HttpRequest.request(url, method: 'POST', mimeType: 'application/json; charset=utf-8', sendData: params);
    http.then((req){
      if(req.readyState == 4 && req.status == 200) {
        var info = JSON.decode(req.responseText);
        if (info["amount"] == amount) {
          context.callMethod('google.payments.inapp.buy',[new JsObject.jsify({
            'parameters': {},
            'jwt': info["jwt"],
            'success': this.buyOK,
            'failure': this.buyFailed,
          })]);
        }
      }
    }).catchError((err){
      print("failed to req $err");
    });
  }

  buyOK() {
    print(" buy success");
    _state = 2;
    update();
  }

  buyFailed() {
    print(" buy failure");
    _state = -1;
    update();
  }

}


class UiScreenRunResult {
  Element el;
  var bus;
  String areaId = "";
  num cubesLast = 0;
  num cubesMax = 0;
  num cubesGain = 0;
  num cubesTotal = 0;
  bool timeout = false;
  var _onPlayEnabled = false;
  Function _onPlay;
  var _onNextEnabled = false;
  Function _onNext;
  var _fmt = new NumberFormat("+00");

  init() {
    bus.on(eventRunResult).listen((x) {
      areaId = x.area;
      cubesLast = x.cubes;
      cubesGain = x.gain;
      cubesMax = x.previousMax;
      cubesTotal = x.cubesTotal;
      timeout = !x.exiting;
      update();
    });
    bus.on(eventInGameStatus).listen((x) {
      _onPlayEnabled = (x.kind == IGStatus.INITIALIZED || x.kind == IGStatus.STOPPED);
      update();
    });
    _onPlay = (_){
      bus.fire(eventInGameReqAction, IGAction.PLAY);
    };
  }

  update(){
    if (el == null) return;
    try {
      _update0("areaId", areaId);
      _update0("cubesLast", cubesLast);
      _update0("cubesMax", cubesMax);
      _update0("cubesGain", _fmt.format(cubesGain));
      _update0("cubesTotal", cubesTotal);
      el.querySelector("#shadow").style.display = "block";
      el.querySelector("#points").style.display = timeout ? "none":"block";
      el.querySelector("#timeout").style.display = timeout ? "block":"none";
      var btnPlay = el.querySelector(".play");
      (btnPlay as ButtonElement).disabled = !_onPlayEnabled;
      btnPlay.onClick.first.then(_onPlay);
      var btnNext = el.querySelector(".next");
      (btnNext as ButtonElement).disabled = !_onNextEnabled;
      btnNext.onClick.first.then(_onNext);
    } catch(e, st) {
      print("WARNING");
      print(e);
      print(st);
    }
  }

  _update0(k, v) {
    var el0 = el.querySelector("[data-text=$k]");
    if (el0 != null) {
      el0.text = v.toString();
    }
  }
}