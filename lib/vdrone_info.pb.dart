///
//  Generated code. Do not modify.
///
library vdrone_info;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class From extends ProtobufEnum {
  static const From SHOP = const From._(0, 'SHOP');
  static const From GIFT = const From._(1, 'GIFT');
  static const From AREA = const From._(2, 'AREA');

  static const List<From> values = const <From> [
    SHOP,
    GIFT,
    AREA,
  ];

  static final Map<int, From> _byValue = ProtobufEnum.initByValue(values);
  static From valueOf(int value) => _byValue[value];

  const From._(int v, String n) : super(v, n);
}

class AreaBook extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AreaBook')
    ..m(1, 'areaStats', () => new AreaStat(), () => new PbList<AreaStat>())
  ;

  AreaBook() : super();
  AreaBook.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  AreaBook.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  AreaBook clone() => new AreaBook()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  List<AreaStat> get areaStats => getField(1);
}

class PCache extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('PCache')
    ..a(1, 'lastModification', GeneratedMessage.Q6, () => makeLongInt(0))
    ..a(2, 'scoreCubes', GeneratedMessage.Q3)
    ..p(3, 'achievements', GeneratedMessage.PS)
  ;

  PCache() : super();
  PCache.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  PCache.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  PCache clone() => new PCache()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  Int64 get lastModification => getField(1);
  void set lastModification(Int64 v) { setField(1, v); }
  bool hasLastModification() => hasField(1);
  void clearLastModification() => clearField(1);

  int get scoreCubes => getField(2);
  void set scoreCubes(int v) { setField(2, v); }
  bool hasScoreCubes() => hasField(2);
  void clearScoreCubes() => clearField(2);

  List<String> get achievements => getField(3);
}

class AreaStat extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AreaStat')
    ..a(1, 'id', GeneratedMessage.QS)
    ..a(2, 'runCount', GeneratedMessage.Q3)
    ..a(3, 'crashCount', GeneratedMessage.Q3)
    ..a(4, 'exitingCount', GeneratedMessage.Q3)
    ..a(5, 'cubeBestRun', GeneratedMessage.OM, () => new RunReport(), () => new RunReport())
    ..a(6, 'lastStartTime', GeneratedMessage.O6, () => makeLongInt(0))
  ;

  AreaStat() : super();
  AreaStat.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  AreaStat.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  AreaStat clone() => new AreaStat()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get id => getField(1);
  void set id(String v) { setField(1, v); }
  bool hasId() => hasField(1);
  void clearId() => clearField(1);

  int get runCount => getField(2);
  void set runCount(int v) { setField(2, v); }
  bool hasRunCount() => hasField(2);
  void clearRunCount() => clearField(2);

  int get crashCount => getField(3);
  void set crashCount(int v) { setField(3, v); }
  bool hasCrashCount() => hasField(3);
  void clearCrashCount() => clearField(3);

  int get exitingCount => getField(4);
  void set exitingCount(int v) { setField(4, v); }
  bool hasExitingCount() => hasField(4);
  void clearExitingCount() => clearField(4);

  RunReport get cubeBestRun => getField(5);
  void set cubeBestRun(RunReport v) { setField(5, v); }
  bool hasCubeBestRun() => hasField(5);
  void clearCubeBestRun() => clearField(5);

  Int64 get lastStartTime => getField(6);
  void set lastStartTime(Int64 v) { setField(6, v); }
  bool hasLastStartTime() => hasField(6);
  void clearLastStartTime() => clearField(6);
}

class RunReport extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('RunReport')
    ..a(1, 'exiting', GeneratedMessage.QB)
    ..a(2, 'cubeCount', GeneratedMessage.Q3)
    ..a(3, 'crashCount', GeneratedMessage.Q3)
    ..a(4, 'timeLeft', GeneratedMessage.Q3)
    ..a(5, 'startTime', GeneratedMessage.Q6, () => makeLongInt(0))
    ..a(6, 'endTime', GeneratedMessage.Q6, () => makeLongInt(0))
    ..a(7, 'nohit', GeneratedMessage.QB)
  ;

  RunReport() : super();
  RunReport.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  RunReport.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  RunReport clone() => new RunReport()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  bool get exiting => getField(1);
  void set exiting(bool v) { setField(1, v); }
  bool hasExiting() => hasField(1);
  void clearExiting() => clearField(1);

  int get cubeCount => getField(2);
  void set cubeCount(int v) { setField(2, v); }
  bool hasCubeCount() => hasField(2);
  void clearCubeCount() => clearField(2);

  int get crashCount => getField(3);
  void set crashCount(int v) { setField(3, v); }
  bool hasCrashCount() => hasField(3);
  void clearCrashCount() => clearField(3);

  int get timeLeft => getField(4);
  void set timeLeft(int v) { setField(4, v); }
  bool hasTimeLeft() => hasField(4);
  void clearTimeLeft() => clearField(4);

  Int64 get startTime => getField(5);
  void set startTime(Int64 v) { setField(5, v); }
  bool hasStartTime() => hasField(5);
  void clearStartTime() => clearField(5);

  Int64 get endTime => getField(6);
  void set endTime(Int64 v) { setField(6, v); }
  bool hasEndTime() => hasField(6);
  void clearEndTime() => clearField(6);

  bool get nohit => getField(7);
  void set nohit(bool v) { setField(7, v); }
  bool hasNohit() => hasField(7);
  void clearNohit() => clearField(7);
}

class Inventory extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Inventory')
    ..m(1, 'items', () => new Item(), () => new PbList<Item>())
  ;

  Inventory() : super();
  Inventory.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Inventory.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Inventory clone() => new Inventory()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  List<Item> get items => getField(1);
}

class Item extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Item')
    ..a(1, 'id', GeneratedMessage.QS)
    ..a(2, 'qty', GeneratedMessage.Q3)
    ..a(3, 'used', GeneratedMessage.Q3)
    ..m(4, 'sources', () => new Source(), () => new PbList<Source>())
  ;

  Item() : super();
  Item.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Item.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Item clone() => new Item()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get id => getField(1);
  void set id(String v) { setField(1, v); }
  bool hasId() => hasField(1);
  void clearId() => clearField(1);

  int get qty => getField(2);
  void set qty(int v) { setField(2, v); }
  bool hasQty() => hasField(2);
  void clearQty() => clearField(2);

  int get used => getField(3);
  void set used(int v) { setField(3, v); }
  bool hasUsed() => hasField(3);
  void clearUsed() => clearField(3);

  List<Source> get sources => getField(4);
}

class Source extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Source')
    ..a(1, 'at', GeneratedMessage.Q6, () => makeLongInt(0))
    ..a(2, 'price', GeneratedMessage.Q3)
    ..e(3, 'from', GeneratedMessage.OE, () => From.SHOP, (var v) => From.valueOf(v))
  ;

  Source() : super();
  Source.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Source.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Source clone() => new Source()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  Int64 get at => getField(1);
  void set at(Int64 v) { setField(1, v); }
  bool hasAt() => hasField(1);
  void clearAt() => clearField(1);

  int get price => getField(2);
  void set price(int v) { setField(2, v); }
  bool hasPrice() => hasField(2);
  void clearPrice() => clearField(2);

  From get from => getField(3);
  void set from(From v) { setField(3, v); }
  bool hasFrom() => hasField(3);
  void clearFrom() => clearField(3);
}

class AudioSettings extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AudioSettings')
    ..a(1, 'mute', GeneratedMessage.QB)
    ..a(2, 'masterVolume', GeneratedMessage.Q3, () => 90)
    ..a(3, 'musicVolume', GeneratedMessage.Q3, () => 50)
    ..a(4, 'soundVolume', GeneratedMessage.Q3, () => 70)
  ;

  AudioSettings() : super();
  AudioSettings.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  AudioSettings.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  AudioSettings clone() => new AudioSettings()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  bool get mute => getField(1);
  void set mute(bool v) { setField(1, v); }
  bool hasMute() => hasField(1);
  void clearMute() => clearField(1);

  int get masterVolume => getField(2);
  void set masterVolume(int v) { setField(2, v); }
  bool hasMasterVolume() => hasField(2);
  void clearMasterVolume() => clearField(2);

  int get musicVolume => getField(3);
  void set musicVolume(int v) { setField(3, v); }
  bool hasMusicVolume() => hasField(3);
  void clearMusicVolume() => clearField(3);

  int get soundVolume => getField(4);
  void set soundVolume(int v) { setField(4, v); }
  bool hasSoundVolume() => hasField(4);
  void clearSoundVolume() => clearField(4);
}

