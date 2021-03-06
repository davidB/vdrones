part of vdrones;

class System_Hud extends IntervalEntitySystem {
  ComponentMapper<DroneNumbers> _droneNumbersMapper;
  ComponentMapper<Chronometer> _chronometerMapper;
  PlayerManager _playerManager;

  String playerToFollow;
  Element _container;
  Element _scoreEl;
  Element _chronometerEl;
  Element _energyBarEl;
  Element _viewRedEl;
  bool _initialized = false;

  System_Hud(this._container, this.playerToFollow):super(1000.0/15, Aspect.getAspectForOneOf([DroneNumbers, Chronometer]));

  void initialize(){
    _playerManager = world.getManager(PlayerManager) as PlayerManager;
    _droneNumbersMapper = new ComponentMapper<DroneNumbers>(DroneNumbers, world);
    _chronometerMapper = new ComponentMapper<Chronometer>(Chronometer, world);
    //TODO Window.resizeEvent.forTarget(window).listen(_updateViewportSize);
    //TODO use AssetManager to retreive dom or a web_ui component
    reset();
  }

  void _initializeDom(domElem) {
    if (domElem != null) {
      _scoreEl = _container.querySelector("#score");
      if (_scoreEl != null) _scoreEl.text = "0";

      _chronometerEl = _container.querySelector("#chronometer");
      if (_chronometerEl != null) {
        _chronometerEl.classes.remove("blinking5s");
        _updateChronometer(0);
      }

      _energyBarEl = _container.querySelector("#energyBar");
      _viewRedEl = _container.querySelector("#view_red");
      _initialized = true;
    }
  }

  void _updateChronometer(int v) {
    if (_chronometerEl == null) return;
    int totalSec = v.abs();
    int minutes = totalSec ~/ 60;
    int seconds = totalSec % 60;
    var txt = "${minutes < 10 ? "0" : ""}${minutes}:${seconds < 10 ? "0" : ""}${seconds}";
    _chronometerEl.text = txt;
    if (v == -5) {
      _chronometerEl.classes.add("blinking5s");
    }
  }

  bool checkProcessing() {
    var b = super.checkProcessing();
    if (!_initialized) reset();
    return b && _initialized;
  }
  void processEntities(ReadOnlyBag<Entity> entities) {
    entities.forEach((entity){
      if (_playerManager.getPlayer(entity) == playerToFollow) {
        var numbers = _droneNumbersMapper.getSafe(entity);
        if (numbers != null) {
          if (_scoreEl != null) _scoreEl.text = numbers.score.toString();
          if (_energyBarEl != null) {
            var max = numbers.energyMax;
            if (max > 0) {
              int r = (numbers.energy * 449) ~/ max;
              _energyBarEl.attributes["width"] = r.toString();
            }
          }
          if (_viewRedEl != null) {
            _viewRedEl.style.opacity = (numbers.hit / 100.0).toString();
          }
        }
      } else {
        var chrono = _chronometerMapper.getSafe(entity);
        if (chrono != null) {
          _updateChronometer(chrono.millis ~/1000);
        }
      }
    });
  }

  void reset() {
    _initialized = false;
    var c = _container.querySelector("#hud").childNodes;
    if (c.length == 1) _initializeDom(c[0]);
  }
}
