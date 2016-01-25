//@Timeout(const Duration(seconds: 5))
@Timeout(const Duration(seconds: 1))
library isodance.test;

import 'package:darpule/tuple.dart';
import 'package:isodance/isodance.dart';
import 'package:test/test.dart';

void main() {
  Uri isolateTestStub = new Uri.file(
      '/Users/rayk/Projects/isodance/test/test_executor_stub.dart');

  group('Provision Isolate', () {
    test('Should throw ArgumentError if the Isolate Request is faulty.',
        () async {
      Tuple isoRequest = new Tuple(['test_executor_stub.dart']);
      expect(provisionIsolate(isoRequest),
          throwsA(new isInstanceOf<ArgumentError>()));
    });

    test('Should not throw when Isolate request is valid.', () async {
      Tuple isoRequest = new Tuple([isolateTestStub, new ReceivePort()]);
      expect(await provisionIsolate(isoRequest), returnsNormally);
    });

    test('Should return a provisioned Running Isolate Package.', () async {
      ReceivePort myReceivePort = new ReceivePort();
      Tuple isoRequest = new Tuple([isolateTestStub, myReceivePort]);
      Tuple provisionedIsolate = await provisionIsolate(isoRequest);
      expect(provisionedIsolate, isNotNull);
      expect(provisionedIsolate[0] is Isolate, isTrue); // New Isolate
      expect(provisionedIsolate[1] is SendPort, isTrue); // Send Port Iso
      expect(provisionedIsolate[2] is ReceivePort, isTrue); // Receive Port
      expect(provisionedIsolate[3] is String, isTrue); // Preset Exit message
      expect(provisionedIsolate[4] is ReceivePort, isTrue); // Port to listen for exit
      expect(provisionedIsolate[5] is ReceivePort, isTrue); // Port for Uncaught errors
      expect(provisionedIsolate[6] is Capability, isTrue); // Pause Capability
      expect(await isIsolateAlive(provisionedIsolate[0]), isTrue);
    });

    test('Should return a provisioned Paused Isolate.',() async{
      ReceivePort myReceivePort = new ReceivePort();
      Tuple isoRequest = new Tuple([isolateTestStub, myReceivePort]);
      Tuple provisionedIsolate = await provisionIsolate(isoRequest, paused: true);
      expect(provisionedIsolate, isNotNull);
      expect(provisionedIsolate[0] is Isolate, isTrue); // New Isolate
      expect(provisionedIsolate[1] is SendPort, isTrue); // Send Port Iso
      expect(provisionedIsolate[2] is ReceivePort, isTrue); // Receive Port
      expect(provisionedIsolate[3] is String, isTrue); // Preset Exit message
      expect(provisionedIsolate[4] is ReceivePort, isTrue); // Port to listen for exit
      expect(provisionedIsolate[5] is ReceivePort, isTrue); // Port for Uncaught errors
      expect(provisionedIsolate[6] is Capability, isTrue); // Pause Capability
      expect(provisionedIsolate[7] is Capability, isTrue);  // Capability to resume isolate
      expect(await isIsolateAlive(provisionedIsolate[0]), isFalse);
    });

    test('Should be able to resume a pasued Isolate.',() async{
      ReceivePort myReceivePort = new ReceivePort();
      Tuple isoRequest = new Tuple([isolateTestStub, myReceivePort]);
      Tuple provisionedIsolate = await provisionIsolate(isoRequest, paused: true);
      expect(provisionedIsolate, isNotNull);
      expect(provisionedIsolate[0] is Isolate, isTrue); // New Isolate
      expect(provisionedIsolate[1] is SendPort, isTrue); // Send Port Iso
      expect(provisionedIsolate[2] is ReceivePort, isTrue); // Receive Port
      expect(provisionedIsolate[3] is String, isTrue); // Preset Exit message
      expect(provisionedIsolate[4] is ReceivePort, isTrue); // Port to listen for exit
      expect(provisionedIsolate[5] is ReceivePort, isTrue); // Port for Uncaught errors
      expect(provisionedIsolate[6] is Capability, isTrue); // Pause Capability
      expect(provisionedIsolate[7] is Capability, isTrue);  // Capability to resume isolate
      expect(await isIsolateAlive(provisionedIsolate[0]), isFalse);
      Isolate iso = provisionedIsolate[0];
      iso.resume(provisionedIsolate[7]);
      expect(await isIsolateAlive(iso), isTrue);
    });
  });

  group('Pings Isolate and ensure reply in 10ms:\t', () {

    test('Should return a true.', () async {
      ReceivePort myReceivePort = new ReceivePort();
      Tuple isoRequest = new Tuple([isolateTestStub, myReceivePort]);
      Tuple provisionedIsolate = await provisionIsolate(isoRequest);
      bool reply = await isIsolateAlive(provisionedIsolate[0]);
      expect(reply, isTrue);
    });

    test("Should return false.",() async{
      ReceivePort myReceivePort = new ReceivePort();
      Tuple isoRequest = new Tuple([isolateTestStub, myReceivePort]);
      Tuple provisionedIsolate = await provisionIsolate(isoRequest);
      Isolate targetIso = provisionedIsolate[0];
      targetIso.kill(priority: 0);
      bool reply = await isIsolateAlive(targetIso);
      expect(reply, isFalse);
    });
  });

  group('Clean Isolate Shutdown:\t', () {
    setUp(() {

    });
    test('Should shutdown an isolate in a cleanly.',() async{
      ReceivePort myReceivePort = new ReceivePort();
      Tuple isoRequest = new Tuple([isolateTestStub, myReceivePort]);
      Tuple provisionedIsolate = await provisionIsolate(isoRequest);
      Isolate iso = provisionedIsolate[0];
      expect(await isIsolateAlive(iso), isTrue);
      terminateIsolate(provisionedIsolate);
      expect(await isIsolateAlive(iso), isFalse);
    });

  });


}
