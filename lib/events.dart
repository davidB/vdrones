library events;

import 'package:event_bus/event_bus.dart';

//see https://github.com/marcojakob/dart-event-bus

makeBus() => new EventBus();
//final EventBus bus = new EventBus();
final EventType<RunResult> eventRunResult = new EventType<RunResult>();
final EventType<int> eventInGameStatus = new EventType<int>();
final EventType<int> eventInGameReqAction = new EventType<int>();
final EventType<Err> eventErr = new EventType<Err>();
final EventType<Auth> eventAuth = new EventType<Auth>();

class Err {
  var category;
  var exc;
  var stacktrace;
}

class Auth {
  var auth;
  var logged;
}

class IGStatus {
  static const NONE = 0;
  static const INITIALIZING = 1;
  static const INITIALIZED = 2;
  static const PLAYING = 3;
  static const PAUSED = 4;
  static const STOPPING = 5;
  static const STOPPED = 6;
}

class IGAction {
  static const INITIALIZE = 1;
  static const PLAY = 2;
  static const PAUSE = 3;
  static const STOP = 4;
}

class RunResult {
  String area = 'undef';
  int cubes = 0;
  int gain = 0;
  int previousMax = 0;
  int cubesTotal = 0;
  bool exiting = true;
  List achievementsUnlocked = new List<String>();
}
