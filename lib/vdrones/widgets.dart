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

/**
 * [XDropdown] aligns closely with the model provided by the
 * [dropdown functionality](http://twitter.github.com/bootstrap/javascript.html#dropdowns)
 * in Bootstrap.
 *
 * [XDropdown] content is inferred from all child elements that have
 * class `dropdown-menu`. Bootstrap defines a CSS selector for `.dropdown-menu`
 * with an initial display of `none`.
 *
 * [XDropdown] listens for `click` events and toggles visibility of content if the
 * click target has attribute `data-toggle="dropdown"`.
 *
 * Bootstrap also defines a CSS selector which sets `display: block;` for elements
 * matching `.open > .dropdown-menu`. When [XDropdown] opens, the class `open` is
 * added to the inner element wrapping all content. Causing child elements with
 * class `dropdown-menu` to become visible.
 */
class UiDropdown {
  static final ShowHideEffect _effect = new ScaleEffect(orientation: Orientation.VERTICAL, yOffset : VerticalAlignment.TOP);
  static const int _duration = 100;

  static void bind(Element e) {
    e.querySelectorAll("[is=x-dropdown]").forEach((el){
      el.querySelector(".dropdown-toggle").onClick.listen(_onClick);
      el.onKeyDown.listen(_onKeyDown);
      _apply(el, ShowHideAction.HIDE);
    });
  }
  
  static void _onKeyDown(KeyboardEvent evt) {
    final Element target = evt.target;
    if(!evt.defaultPrevented && evt.keyCode == KeyCode.ESC) {
      _apply(target, ShowHideAction.HIDE);
      evt.preventDefault();
    }
  }

  static void _onClick(MouseEvent evt) {
    final Element target = evt.currentTarget;
    if(!evt.defaultPrevented && target != null) {
      _apply(target.parent, ShowHideAction.TOGGLE);
      evt.preventDefault();
      target.focus();
    }
  }
  
  static void _apply(e, ShowHideAction action) {
    print("action : $action");
    final headerElement = e.querySelector('[is=x-dropdown] > .dropdown');
    if(headerElement != null) {
      switch(action) {
        case ShowHideAction.HIDE:
          headerElement.classes.remove('open');
          break;
        case ShowHideAction.SHOW:
          headerElement.classes.add('open');
          break;
        case ShowHideAction.TOGGLE:
          headerElement.classes.remove('open');
          break;
      }
    }
    final contentDiv = e.querySelector('[is=x-dropdown] > .dropdown-menu');
    if(contentDiv != null) {
      ShowHide.begin(action, contentDiv, effect: _effect);
    }
    print("action : $action $e $headerElement $contentDiv");
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
  var onPlayEnabled = false;
  Function onPlay;
  
  update(){
    if (el == null) return;
    _update0("areaId", areaId);
    _update0("cubesLast", cubesLast);
    _update0("cubesMax", cubesMax);
    _update0("cubesGain", cubesGain);
    _update0("cubesTotal", cubesTotal);
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