import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:my_project/providers/mqtt_providers.dart';
import 'package:provider/provider.dart';

// connection states for easy identification
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

int mqtt_broker_port = 8883;
String mqtt_broker_host =
    "5e0583f9805f4600ba9e0fe2afc9bc76.s1.eu.hivemq.cloud"; // "46ccbc0fc88649cbb3b7b951f0e0c837.s1.eu.hivemq.cloud"
// String mqtt_topic01 = "drone/ike_igwe/telemetry";
String user_name = "Hardware";
String password = "Adedamola30";

class MQTTClientWrapper {
  late MqttServerClient client;

  bool is_Connected = false;
  String recievedMessage = "";

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  // void setConnectionParameters({int index = 0}) {
  //   dynamic drones = jsonDecode(DataSharedPrefs.getData("allDrones"));
  //   List<Drone> dronesObjs = List<Drone>.from(
  //     drones.map((x) => Drone.fromJson(x)),
  //   );
  // }
// void prepareMqttClient({required Function callback}) async {
  // using async tasks, so the connection won't hinder the code flow
  void prepareMqttClient() async {
    // mqtt_broker_host = DataSharedPrefs.getData("mqttBrokerHost");
    // mqtt_broker_port = int.parse(DataSharedPrefs.getData("mqttBrokerPort"));
    mqtt_broker_host = mqtt_broker_host;
    mqtt_broker_port = mqtt_broker_port;
    client = MqttServerClient.withPort(
        mqtt_broker_host, generateID(), mqtt_broker_port);
    // the next 2 lines are necessary to connect with tls, which is used by HiveMQ Cloud
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    // if (callback != null) {
    //   callback(client);
    // }
    // await connectClient();
  }

  // waiting for the connection, if an error occurs, print it and disconnect
  Future<void> connectClient() async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(user_name, password);
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;

      client.disconnect();
    }

    // when connected, print a confirmation, else print an error
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print("CONNECTED");
      // is_Connected = true;
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;

      client.disconnect();
    }
  }

  Future<void> disconnectClient() async {
    client.disconnect();
  }

  void subscribeToTopic(String topicName, Function callback, bool isListening,
      BuildContext context) {
    final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
    var pay_load = Map();
    print('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);

    // print the message when it is received
    //and it should only listen on the first subscription
    if (!isListening) {
      client.updates?.listen(
        (List<MqttReceivedMessage<MqttMessage>> c) async {
          var recMess = c[0].payload as MqttPublishMessage;
          var message =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          // mess_age = message;
          print("Message: ${message}");
          pay_load['topic'] = (c[0].topic).toString();
          pay_load['msg'] = message.toString();
          recievedMessage = pay_load['msg'];
          print("Calling provider method........");
          mqttProvider.checkMessages();
          
          // latitude = pay_load['msg'];
          callback(pay_load);
          
          
        },
      );
    }
  }

  void publishMessage(String message, String topic) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message $message to topic $topic');
    client.publishMessage(
      topic,
      MqttQos.exactlyOnce,
      builder.payload!,
      retain: true,
    );
  }

  // callbacks for different events
  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was sucessful');
    isConnected(true, () {});
  }

  void isConnected(bool data, Function callback) {
    callback(data);
  }

  String generateID() {
    const length = 10;
    final lettersLowerCase = 'abcdefghijklmnopqrstuvwxyz';
    final lettersUppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final numbers = '0123456789';
    final spacialChar = '!@#\$%^&*()_+-={[}]?/~`|';
    final date_time = DateTime.now();

    String chars = '';
    chars += '$lettersLowerCase$lettersUppercase';
    chars += '$numbers';
    chars += '$spacialChar';

    return List.generate(length, (index) {
          final indexRandom = Random.secure().nextInt(chars.length);
          return chars[indexRandom];
        }).join("") +
        date_time.toString();
  }
}
