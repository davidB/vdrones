library screens;

import 'dart:html';
import 'package:simple_audio/simple_audio.dart';
import 'package:intl/intl.dart';
import 'events.dart';

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
      _onPlayEnabled = (x == IGStatus.INITIALIZED || x == IGStatus.STOPPED);
      update();
    });
    _onPlay = (_){
      bus.fire(eventInGameReqAction, IGAction.PLAY);
    };
  }

  update(){
    if (el == null) return;
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
  }

  _update0(k, v) {
    var el0 = el.querySelector("[data-text=$k]");
    if (el0 != null) {
      el0.text = v.toString();
    }
  }
}