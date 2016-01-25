library dance_moves;

import 'dart:async';
import 'dart:isolate';

import 'package:darpule/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:darpule/predicate.dart' as prd;

Future<Isolate> acquireIso(Tuple isolateRequest, SendPort exchangePort) async {
  int startUpMsgCode = 9999; // Code to request handshake.
  ReceivePort clientsInboundMsgPort = isolateRequest[1];
  Uri executorPath = isolateRequest[0];
  SendPort xchagePort = exchangePort;

  List startUpArgs = [
    clientsInboundMsgPort.sendPort,
    new Uuid().v4(),
    executorPath.toString(),
    xchagePort
  ];


  return await Isolate.spawnUri(executorPath, startUpArgs, startUpMsgCode);
}

Future<List> exchangePorts(ReceivePort tempExchangePort) async {
  var completer = new Completer();

  completeExchange(List reply) {
    tempExchangePort.close();
    completer.complete(reply);
  }

  // Listen to 9999 reply from executor.
  tempExchangePort.listen((List reply) {
    if (reply[0] == 9999 ) {
      assert (reply[1] is SendPort);
      assert (reply[2] is String);
      completeExchange(reply);
    }
  });

  return completer.future;
}

bool isIsolateRequestValid(Tuple isolateRequest) {
  if (prd.isPairple(isolateRequest) &&
      isolateRequest[0] is Uri &&
      !isolateRequest[0].hasEmptyPath &&
      isolateRequest[1] is ReceivePort) {
    return true;
  }
  return false;
}


