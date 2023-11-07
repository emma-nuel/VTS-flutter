class TrackerData {
  final double latitude;
  final double longitude;
  final int tracked;
  final int visible;

  TrackerData({required this.latitude, required this.longitude, this.tracked = 0, this.visible = 0});

  factory TrackerData.fromJson(Map<String, dynamic> json) {
    print("Type: ${json.runtimeType}");
    return TrackerData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      tracked: json['tracked'],
      visible: json['visible'],
    );
  }

  
}
