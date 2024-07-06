import "package:flutter/material.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";

/// Serializers ///
const jsonSerializer = "JSON";
const cborSerializer = "CBOR";
const msgPackSerializer = "MsgPack";

/// Topic Name ///
const topicName = "io.xconn.location";

/// Realm ///
const realm = "realm1";

/// Url Link ///
const urlLink = "ws://192.168.0.124:8080/ws";

SpinKitChasingDots spinKitRotatingCircle = const SpinKitChasingDots(
  color: Colors.deepPurple,
);
