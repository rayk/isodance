/// Provision isolate test Stub;

import 'dart:isolate';

/// Permanently kill the isolate running this code after the current
/// event and before the next one starts.
void kill() => Isolate.current.kill(priority: 1);

main(List args, int message) {
  ReceivePort inBoundMessagePort = new ReceivePort();
  SendPort outBoundMessagePort;
  SendPort tempProvisionPort;
  String isolateID;
  String executorPath;


  if (args.length == 4) {
    outBoundMessagePort = args[0]; // Regular out bound msg sent here.
    assert(outBoundMessagePort is SendPort);
    isolateID = args[1]; // ID the client knows this Isolate as.
    assert(isolateID is String && isolateID.isNotEmpty);
    executorPath = args[2]; // Codebase that this isolate has access to.
    assert(executorPath is String && executorPath.isNotEmpty);
    tempProvisionPort = args[3]; // Provisioning port.
    assert(tempProvisionPort is SendPort);

    /// Carry out a port exchange so client can send to inBoundMessagePort.
    if (message == 9999) {
      String onExitMessage =("$isolateID : ${Isolate.current.hashCode}");
      List reply = [9999, inBoundMessagePort.sendPort, onExitMessage];
      tempProvisionPort.send(reply);
    }
  }

  inBoundMessagePort.listen((List msg) {
    if (msg[0] == 0000) {
      List reply = [isolateID, executorPath];
      outBoundMessagePort.send(reply);
    }
  });
}
