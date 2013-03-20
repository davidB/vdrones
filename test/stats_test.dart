library stats_test;

import 'package:unittest/unittest.dart';
import '../lib/vdrones.dart';

main() {
  var areaId = "foo";

  test("starting Stats is empty", () {
    var evt = new Evt();
    var sut = new Stats(evt, "dbtest0", clean : true);
    evt.GameInit.dispatch([areaId]);
    sut.store.then(expectAsync1((_) {
      expect(sut[Stats.MONEY_CURRENT_V], equals(0));
      expect(sut[Stats.MONEY_CUMUL_V], equals(0));
      expect(sut[Stats.MONEY_LAST_V], equals(0));
      expect(sut[Stats.AREA_CUBES_MAX_V], equals(0));
      expect(sut[Stats.AREA_CUBES_TOTAL_V], equals(0));
      expect(sut[Stats.AREA_CUBES_LAST_V], equals(0));
    }));
  });
  test("Stats update indicators", () {
    var evt = new Evt();
    var sut = new Stats(evt, "dbtest0", clean : true);
    evt.GameInit.dispatch([areaId]);
    sut.store.then(expectAsync1((_) {
      sut.updateCubesLast(areaId, 1);
      expect(sut[Stats.MONEY_CURRENT_V], equals(1));
      expect(sut[Stats.MONEY_CUMUL_V], sut[Stats.MONEY_CURRENT_V]);
      expect(sut[Stats.MONEY_LAST_V], equals(1));
      expect(sut[Stats.AREA_CUBES_MAX_V], equals(1));
      expect(sut[Stats.AREA_CUBES_TOTAL_V], equals(1));
      expect(sut[Stats.AREA_CUBES_LAST_V], equals(1));

      sut.updateCubesLast(areaId, 0);
      expect(sut[Stats.MONEY_CURRENT_V], equals(1));
      expect(sut[Stats.MONEY_CUMUL_V], sut[Stats.MONEY_CURRENT_V]);
      expect(sut[Stats.MONEY_LAST_V], equals(0));
      expect(sut[Stats.AREA_CUBES_MAX_V], equals(1));
      expect(sut[Stats.AREA_CUBES_TOTAL_V], equals(1));
      expect(sut[Stats.AREA_CUBES_LAST_V], equals(0));

      sut.updateCubesLast(areaId, 1);
      expect(sut[Stats.MONEY_CURRENT_V], equals(1.25));
      expect(sut[Stats.MONEY_CUMUL_V], sut[Stats.MONEY_CURRENT_V]);
      expect(sut[Stats.MONEY_LAST_V], equals(0.25));
      expect(sut[Stats.AREA_CUBES_MAX_V], equals(1));
      expect(sut[Stats.AREA_CUBES_TOTAL_V], equals(2));
      expect(sut[Stats.AREA_CUBES_LAST_V], equals(1));

      sut.updateCubesLast(areaId, 2);
      expect(sut[Stats.MONEY_CURRENT_V], equals(2.50));
      expect(sut[Stats.MONEY_CUMUL_V], sut[Stats.MONEY_CURRENT_V]);
      expect(sut[Stats.MONEY_LAST_V], equals(1.25));
      expect(sut[Stats.AREA_CUBES_MAX_V], equals(2));
      expect(sut[Stats.AREA_CUBES_TOTAL_V], equals(4));
      expect(sut[Stats.AREA_CUBES_LAST_V], equals(2));

      sut.updateCubesLast(areaId, 1);
      expect(sut[Stats.MONEY_CURRENT_V], equals(2.75));
      expect(sut[Stats.MONEY_CUMUL_V], sut[Stats.MONEY_CURRENT_V]);
      expect(sut[Stats.MONEY_LAST_V], equals(0.25));
      expect(sut[Stats.AREA_CUBES_MAX_V], equals(2));
      expect(sut[Stats.AREA_CUBES_TOTAL_V], equals(5));
      expect(sut[Stats.AREA_CUBES_LAST_V], equals(1));
    }));
  });

}

