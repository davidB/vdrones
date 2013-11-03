library vdrone_info_test;

import 'package:unittest/unittest.dart';
import 'package:crypto/crypto.dart';
import '../lib/vdrone_info.pb.dart';

main() {
  group("audio", (){
    test("default values", (){
      var sut = new AudioSettings();
      expect(sut.mute, equals(false));
      expect(sut.masterVolume, equals(90));
      expect(sut.musicVolume, equals(50));
      expect(sut.soundVolume, equals(70));
    });
    test("save/loaddefault values", (){
      var sut = new AudioSettings();
      sut.mute = true;
      sut.masterVolume =  33;
      sut.musicVolume = 44;
      sut.soundVolume = 55;
      var bufSaved = sut.writeToBuffer();
      var stored = CryptoUtils.bytesToBase64(bufSaved);
      var bufLoaded  = CryptoUtils.base64StringToBytes(stored); 
      var l0 = new AudioSettings.fromBuffer(bufLoaded);
      expect(l0, equals(sut));
      expect(l0.mute, equals(true));
      expect(l0.masterVolume, equals(33));
      expect(l0.musicVolume, equals(44));
      expect(l0.soundVolume, equals(55));
    });
    test("load buffer empty : []", (){
      var sut = new AudioSettings.fromBuffer([]);
      expect(sut.mute, equals(false));
      expect(sut.masterVolume, equals(90));
      expect(sut.musicVolume, equals(50));
      expect(sut.soundVolume, equals(70));
    });
  });
}

