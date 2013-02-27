part of vdrones;

class PeriodicTask {
  String id;
  num interval;
  Signal signal;
  List args;
  num runAt = 0;
  PeriodicTask(this.id, this.interval, this.signal, this.args);
}
class CountdownTask {
  String id;
  num timeout;
  Signal signal;
  List args;
  State state;
  CountdownTask(this.id, this.timeout, this.signal, this.args, this.state);
}

void setupPeriodic(Evt evt){
  final _ptasks = new LinkedBag<PeriodicTask>();

  void registerPeriodic(String id, num interval, Signal signal, List args){
    _ptasks.add(new PeriodicTask(id, interval, signal, args));
  }

  void unregisterPeriodic(String id) {
    _ptasks.iterateAndRemove((v) => v.id != id );
  }

  // other implementation could be to use an array sort by runAt and only process runAt < t (like a priorityQueue)
  void ping(num t, num dt500){
    _ptasks.iterateAndRemove((task){
      if (task.runAt < t) {
        task.signal.dispatch(task.args);
        task.runAt = t + task.interval;
      }
      return true;
    });
  }
  evt.PeriodicEvtAdd.add(registerPeriodic);
  evt.PeriodicEvtDel.add(unregisterPeriodic);
  evt.Tick.add(ping);

  final _ctasks = new LinkedBag<CountdownTask>();

  void decCountdown(num t, num delta500) {
    if (delta500 <= 0) return;
    if (_ctasks.length == 0) return;

    List todelete = [];
    var delta = (delta500 / 2);
    _ctasks.iterateAndRemove((t){
      var keep = true;
      var v = math.max(0, t.timeout - delta);
      if (t.state != null) {
        t.state.v = v;
      }
      if (v == 0) {
        t.signal.dispatch(t.args);
        keep = false;
      } else {
        t.timeout = v;
      }
      return keep;
    });
  }

  evt.CountdownStart.add((String id, num timeout, Signal signal, List args, [State state]){
    _ctasks.add(new CountdownTask(id, timeout, signal, args, state));
  });
  evt.CountdownStop.add((id){
    _ctasks.iterateAndRemove((v) => v.id != id );
  });
  evt.Tick.add(decCountdown);
}

