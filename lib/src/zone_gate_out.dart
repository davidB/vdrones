part of vdrones;

class Zone4GateOut {
  final String _id;
  final Evt evt;

  Zone4GateOut(this._id, this.evt, EntityProvider entityProvider) {
    evt.ContactBeginDroneItem.add(onHit);
    evt.ObjSpawn.dispatch([this._id, Position.zero, entityProvider]);
  }


  void onHit(String droneId, String objId){
    if (objId !=  _id) return;
    evt.GameStop.dispatch([true]);
  }
}

