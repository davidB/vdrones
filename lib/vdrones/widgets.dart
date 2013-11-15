part of vdrones;

class UiAudioVolume {
  Element _element;
  AudioManager _audioManager;

  var subscriptions = new List();
  set element(Element v) {
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
  var onPlayEnabled = false;
  Function onPlay;

  update(){
    if (el == null) return;
    el.querySelector("#msgConnecting").style.opacity = onPlayEnabled ? "0" : "1";
    var btn = el.querySelector(".play");
    (btn as ButtonElement).disabled = !onPlayEnabled;
    btn.onClick.first.then((evt){
      if (onPlay != null) onPlay();
    });
  }

  _update0(k, v) {
    var el0 = el.querySelector("[data-text=$k]");
    if (el0 != null) {
      el0.text = v.toString();
    }
  }
}

class UiScreenRunResult {
  Element el;
  String areaId = "";
  num cubesLast = 0;
  num cubesMax = 0;
  num cubesGain = 0;
  num cubesTotal = 0;
  bool timeout = false;
  var onPlayEnabled = false;
  Function onPlay;
  var onNextEnabled = false;
  Function onNext;
  var _fmt = new NumberFormat("+00");
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
    (btnPlay as ButtonElement).disabled = !onPlayEnabled;
    btnPlay.onClick.first.then((evt){
      if (onPlay != null) onPlay();
    });
    var btnNext = el.querySelector(".next");
    (btnNext as ButtonElement).disabled = !onNextEnabled;
    btnNext.onClick.first.then((evt){
      if (onNext != null) onNext();
    });
  }

  _update0(k, v) {
    var el0 = el.querySelector("[data-text=$k]");
    if (el0 != null) {
      el0.text = v.toString();
    }
  }
}