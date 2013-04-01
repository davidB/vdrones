part of vdrones;

void showScreen(id){
  document.queryAll('.screen_info').forEach((screen) {
    //screen.style.opacity = (screen.id === id)?1 : 0;
    if (screen.id == id) {
      screen.classes.remove('hidden');
      screen.classes.add('show');
    } else {
      screen.classes.remove('show');
      screen.classes.add('hidden');
    }
  });
}

void setupLayer2D(Evt evt, Element container, Stats stats){
  var areaId = "";

  evt.GameStates.progressMax.add((v){
    container.query("#gameload").attributes["max"] = v.toString();
  });
  evt.GameStates.progressCurrent.add((v){
    container.query("#gameload").attributes["value"] = v.toString();
  });



  evt.GameInit.add((areaPath){
    areaId = areaPath;
    showScreen('screenInit');
  });
  evt.GameInitialized.add(() {
    container.query("#msgConnecting").style.opacity = "0";
    container.query("#btnStart")
    ..attributes.remove("disabled")
    ..onClick.listen((e){
      showScreen('none');
//      evt.GameStart.dispatch(null);
    });
//    container.query("#btnReplay")
//    ..onClick.listen((e){
//      showScreen('none');
//      evt.GameStart.dispatch(null);
//    });
  });
  evt.HudSpawn.add((objId, domElem) {
    if (domElem != null) {
      document.query("#hud").nodes.add(domElem);
      container.query("#score").text = evt.GameStates.score.v.toString();
      container.query("#countdown").classes.remove("blinking5s");
      evt.GameStates.score.add((v){
        container.query("#score").text = v.toString();
      });
      evt.GameStates.countdown.add((v){
        int totalSec = v.toInt();
        int minutes = totalSec ~/ 60;
        int seconds = totalSec % 60;
        var txt = "${minutes < 10 ? "0" : ""}${minutes}:${seconds < 10 ? "0" : ""}${seconds}";
        var el = container.query("#countdown");
        el.text = txt;
        if (totalSec == 5) {
          el.classes.add("blinking5s");
        }
      });
      evt.GameStates.energy.add((v){
        var bar = container.query("#energyBar");
        var max = evt.GameStates.energyMax.v;
        if (bar != null && max > 0) {
          int r = (v * 449) ~/ max;
          bar.attributes["width"] = r.toString();
        }
      });
    }
  });
  evt.GameStop.add((exiting) {
//    container.query("#screenEndArea").text = areaId;
//    container.query("#screenEndCubesLast").text = stats[areaId + Stats.AREA_CUBES_LAST_V].toString();
//    container.query("#screenEndCubesMax").text = stats[areaId + Stats.AREA_CUBES_MAX_V].toString();
//    container.query("#screenEndCubesTotal").text = stats[areaId + Stats.AREA_CUBES_TOTAL_V].toString();
//
//    if (!exiting) {
//      container.query("#screenEndCubesLast").text = "TIME OUT";
//    }
    var runresult = query('#runresult').xtag;
    runresult.areaId = areaId;
    runresult.cubesLast = stats[areaId + Stats.AREA_CUBES_LAST_V];
    runresult.cubesMax = stats[areaId + Stats.AREA_CUBES_MAX_V];
    runresult.cubesTotal = stats[areaId + Stats.AREA_CUBES_TOTAL_V];
    //runresult.show();
    query('#runresult_dialog').xtag.show();
  });
  evt.Error.add((msg, exc){
    window.console.error(msg);
    window.console.error(exc);
    //_viewModel.alert = msg;
    //_viewModel.shouldShowAlert(true);
  });
}

