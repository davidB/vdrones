library vdrones_layer2d;

import 'dart:html';
import 'events.dart';

//  showScreen = (id) ->
//    screens = document.getElementsByClassName('screen_info')
//    for screen in screens
//      #screen.style.opacity = (screen.id === id)?1 : 0;
//      screen.style.display = if (screen.id == id) then 'block' else 'none'
//    false
//

void setupLayer2D(Evt evt, Element container){
  var _droneIdP = "!";

  evt.GameStates.score.add((v){
    container.query("#score").text = v.toString();
  });
  evt.GameStates.progressMax.add((v){
    container.query("#gameload").attributes["max"] = v.toString();
  });
  evt.GameStates.progressCurrent.add((v){
    container.query("#gameload").attributes["value"] = v.toString();
  });
  evt.GameStates.countdown.add((v){
    container.query("#countdown").text = v.toString();
  });




  evt.GameInit.add((areaPath){
    //showScreen('screenInit')
    //ko.applyBindings(_viewModel, container)
  });
  evt.GameInitialized.add(() {
      evt.GameStart.dispatch(null);
  });
  evt.HudSpawn.add((objId, domElem) {
    if (domElem != null) {
      document.query("#hud").nodes.add(domElem);
      container.query("#score").text = evt.GameStates.score.v.toString();
    }
    //ko.applyBindings(_viewModel, container)
  });
  evt.SetLocalDroneId.add((objId) {
    _droneIdP = "${objId}/";
  });
//  evt.ValUpdate.add((key, value) ->
//      if key.indexOf(_droneIdP) is 0
//        fieldName = key.substring(_droneIdP.length)
//        field = _viewModel[fieldName]
//        field(value) if field?
//      else if key is "countdown"
//        totalSec = Math.floor(value)
//        minutes = parseInt(totalSec / 60, 10)
//        seconds = parseInt(totalSec % 60, 10)
//        result = (
//          (if minutes < 10 then "0" + minutes else minutes)
//          + ":"
//          + (if seconds < 10 then "0" + seconds else seconds)
//        )
//        _viewModel.countdown(result)
//    )
//  evt.LoadProgress.add((current, max){
//    _viewModel.progressMax = max;
//    _viewModel.progressCurrent = current;
//  });
  evt.Error.add((msg, exc){
    window.console.error(msg);
    window.console.error(exc);
    //_viewModel.alert = msg;
    //_viewModel.shouldShowAlert(true);
  });
}

