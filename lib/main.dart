import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:my_project/providers/mqtt_providers.dart';
import 'package:provider/provider.dart';

final Completer<GoogleMapController> _controller =
    Completer<GoogleMapController>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MqttProvider>(
          create: (_) => MqttProvider(),
        ),
        // ChangeNotifierProvider<CounterProvider>(
        //   create: (_) => CounterProvider(),
        // ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var mqttProvider = Provider.of<MqttProvider>(context, listen: false);
      await mqttProvider.connectMqtt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqttProvider = Provider.of<MqttProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("MY CAR"),
        centerTitle: true,
      ),
      body: Center(
        child: mqttProvider.isMqttConnected
            ? const MapScreen()
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // 9.543515, 6.469192
  @override
  Widget build(BuildContext context) {
    final mqttProvider = Provider.of<MqttProvider>(context);
    // debugPrint("Map Lat: ${mqttProvider.recievedMessage[0]}");
    final initialCameraPosition = CameraPosition(
        target: LatLng(mqttProvider.latitude, mqttProvider.longitude),
        zoom: 18);
    debugPrint("${mqttProvider.latitude}");
    return GoogleMap(
      zoomControlsEnabled: false,
      initialCameraPosition: initialCameraPosition,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController mapController) {
        _controller.complete(mapController);
      },
      markers: {
        Marker(
          markerId: const MarkerId("My Car"),
          position: LatLng(mqttProvider.latitude, mqttProvider.longitude),
        ),
      },
    );
  }
}

Future<void> moveCameraPosistion(CameraPosition newpos) async {
  final GoogleMapController controller = await _controller.future;
  await controller.moveCamera(CameraUpdate.newCameraPosition(newpos));
}
