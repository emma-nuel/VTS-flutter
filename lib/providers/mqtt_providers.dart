import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:my_project/main.dart';
import 'package:my_project/services/mqttservices.dart';

class MqttProvider extends ChangeNotifier {
  MQTTClientWrapper newclient = MQTTClientWrapper();
  String subscriptionTopic = "A9G/tracker/data";
  bool _isMqttConnected = false;
  String _recievedMessage = "";
  double _latitude = 0.0;
  double _longitude = 0.0;
  int? _tracked = 0;
  int? _visible = 0;

  bool get isMqttConnected => _isMqttConnected;
  String get recievedMessage => _recievedMessage;
  double get latitude => _latitude;
  double get longitude => _longitude;
  int? get tracked => _tracked;
  int? get visible => _visible;

  Future<void> connectMqtt(BuildContext context) async {
    newclient.prepareMqttClient();
    await newclient.connectClient();
    newclient.subscribeToTopic(subscriptionTopic, () {}, false, context);
    monitorMqttConnectionState();

    // notifyListeners();
  }

  void monitorMqttConnectionState() {
    if (newclient.connectionState == MqttCurrentConnectionState.CONNECTED) {
      _isMqttConnected = true;
    } else {
      _isMqttConnected = false;
    }
    notifyListeners();
  }

  void checkMessages() {
    _recievedMessage = newclient.recievedMessage;
    Map<String, dynamic> jsonData = json.decode(_recievedMessage);

    print("Json Data: $jsonData");

    _latitude = jsonData["latitude"];
    _longitude = jsonData["longitude"];

    notifyListeners();

    CameraPosition _newLocation = CameraPosition(
      // bearing: 192.8334901395799,
      target: LatLng(_latitude, _longitude),
      // tilt: 59.440717697143555,
      zoom: 18,
    );
    moveCameraPosistion(_newLocation);
    // mapController.moveCamera(CameraUpdate.newCameraPosition(_newLocation));
  }
}

// class CounterProvider with ChangeNotifier {
//   int _counter = 0;

//   int get counter => _counter;

//   void incrementCounter() {
//     _counter++;
//     notifyListeners();
//   }
// }
