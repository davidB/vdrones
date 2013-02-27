library utils_test;

import 'package:unittest/unittest.dart';
import '../web/_lib/utils.dart';
import 'dart:html';
import 'dart:async';

main() {
  test("SimpleLinkedList", () {
    var d = new LinkedBag();
    d.add(1);
    d.add(2);
    d.add(3);
    d.add(1);
    expect(d.length, equals(4));

    var ndeleted = 0;
    var lbefore = 0;
    var lafter = 0;

    lbefore =  d.length;
    ndeleted = d.iterateAndRemove((v) => v != 2);
    lafter = d.length;
    expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");

    lbefore =  d.length;
    ndeleted = d.iterateAndRemove((v) => v != 1);
    lafter = d.length;
    expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(1));

    lbefore =  d.length;
    ndeleted = d.iterateAndRemove((v) => v != 1);
    lafter = d.length;
    expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(1));

    d.add(3);
    d.add(1);
    d.add(1);
    expect(d.length, equals(4));

    lbefore =  d.length;
    ndeleted = d.iterateAndRemove((v) => v != 3);
    lafter = d.length;
    expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(2));

    lbefore =  d.length;
    ndeleted = d.iterateAndRemove((v) => v != 1);
    lafter = d.length;
    expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(0));
  });

  test("SimpleLinkedList in async land", () {
    var sut = new SimpleLinkedList();

    var running = true;
    void loop(t) {
      if (running) {
        window.requestAnimationFrame(loop);
      }
      var lbefore =  sut.length;
      var ndeleted = sut.iterateAndRemove((v){
        //longtask
        var u = 0;
        for(var i = 0; i < 1000000; i++) {
          u += i * 2;
        }
        return v % 10 != 0;
      });
      var lafter = sut.length;
      expect(lafter, equals(lbefore - ndeleted), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    }
    window.requestAnimationFrame(loop);

    var fs = new List<Future>();

    for(var i = 0; i < 100; i++) {
      fs.add(new Future.immediate(i).then((x) => x * 2).then((x) => new Future.of((){ sut.add(x); return x;})));
    }
    Future.wait(fs).then((x){ print('DONE : ${sut.length}'); running = false; return true;}).catchError((e){print(e);});
  });
}


