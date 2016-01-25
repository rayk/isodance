// Copyright (c) 2016, Ray King. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library isodance.base;

import 'dart:async';
import 'dart:isolate';

import 'package:darpule/tuple.dart';
import 'package:isodance/src/core.dart';

export 'dart:isolate' show ReceivePort, Isolate, SendPort, Capability;

/// Returns turn if the Isolate response correctly within the time window.
Future isIsolateAlive(Isolate iso) {
  Duration timeLimit = new Duration(milliseconds: 10);
  Completer completer = new Completer();
  ReceivePort pingResponsePort = new ReceivePort();

  fail() => completer.complete(false);
  success() => completer.complete(true);
  timeout() => false;

  int expResponse =
      (new DateTime.now().millisecondsSinceEpoch / iso.hashCode).round();

  pingResponsePort.listen((response) {
    pingResponsePort.close();
    (expResponse == response) ? success() : fail();
  });

  iso.ping(pingResponsePort.sendPort, response: expResponse, priority: 1);

  return completer.future.timeout(timeLimit, onTimeout: timeout);
}

/// Returns Isolate running the specified executor, by default the isolate is
/// running, this can be changed with the optional paused parameter.
///
/// Isolate request contains a URi to the code to execute on the isolate and
/// contains a receive port that the requester will listen to for message from
/// the Isolate.
///
/// Returned Tuple contain :0 Isolate, :1 Message Sent Point, 2: Primary Receive Port,
/// 3: PreSet Exist Message, 4: onExistPortMessage Port 5: Uncaught Error Port.
///
Future<Tuple> provisionIsolate(Tuple isolateRequest,
    {bool paused: false}) async {
  if (!isIsolateRequestValid(isolateRequest)) {
    throw new ArgumentError('IsolateRequest Arguments are not as expected!');
  }

  Tuple provisionedIsoPackage; // Contains the completed provisioning.
  ReceivePort provTempRecPort = new ReceivePort(); // Listen on for msg.
  SendPort provTempSendPort = provTempRecPort.sendPort; // Send msg to Iso

  await acquireIso(isolateRequest, provTempSendPort).then((Isolate iso) async {
    await exchangePorts(provTempRecPort).then((List provision) {
      ReceivePort onExistPort = new ReceivePort();
      ReceivePort onUncaughtErrors = new ReceivePort();
      iso.addOnExitListener(onExistPort.sendPort, response: provision[2]);
      iso.addErrorListener(onUncaughtErrors.sendPort);
      Capability pauseCap = iso.pauseCapability;
      Capability resumeCap;

      if (paused) {
        resumeCap = iso.pause(pauseCap);
      }

      provisionedIsoPackage = new Tuple([
        iso,
        provision[1],
        isolateRequest[1],
        provision[2],
        onExistPort,
        onUncaughtErrors,
        pauseCap,
        resumeCap,
      ]);
    }).catchError((e) => throw e);
  }).catchError((e) => throw e);

  return provisionedIsoPackage;
}

/// Terminates an isolate, closing ports and performs any necessary clean up.
void terminateIsolate(Tuple isolatePackage) {
  Isolate iso = isolatePackage[0];
  ReceivePort recPort = isolatePackage[2];
  ReceivePort exitPort = isolatePackage[4];
  ReceivePort errorPort = isolatePackage[5];
  iso.kill(priority: 1);
  recPort.close();
  errorPort.close();
  exitPort.close();
}
