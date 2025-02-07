import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';

class Bus extends StatefulWidget {
  final String ipAddress;

  const Bus({super.key, required this.ipAddress});

  @override
  State<Bus> createState() => _BusState();
}

class _BusState extends State<Bus> {
  String selectedRoute = 'BUS101';
  final List<String> busRoutes = ['BUS101', 'BUS102', 'BUS103'];

  String _data = '';
  String _data2 = '';

  LatLng? apiLocation;

  void handleData2() {
    if (_data2.isNotEmpty) {
      final parsedData = jsonDecode(_data2);

      if (parsedData['result']['success'] == 'True') {
        final double latitude = parsedData['result']['data']['latitude'];
        final double longitude = parsedData['result']['data']['longtitude'];

        setState(() {
          apiLocation = LatLng(latitude, longitude);
        });

        print('Latitude: $latitude');
        print('Longitude: $longitude');
      } else {
        print('Failed to fetch valid data.');
      }
    }
  }

  Future<bool> createDataGet() async {
    var url = Uri.parse('http://${widget.ipAddress}:4491/update_passenger');
    var response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json' // Set content-type to application/json
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "name": "station 08",
          "latitude": currentLocation != null
              ? currentLocation!.latitude.toString()
              : "12.8855589",
          "longtitude": currentLocation != null
              ? currentLocation!.longitude.toString()
              : "200.4544173"
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _data = 'Data created successfully : ${response.body}';
      });
      return true; // ส่งสำเร็จ
    } else {
      print('Failed to create data: ${response.body}');
      setState(() {
        _data = "Failed to create data";
      });
      return false; // ส่งไม่สำเร็จ
    }
  }

  Future<bool> createDataSearch() async {
    var url = Uri.parse('http://${widget.ipAddress}:4491/get_bus');
    var response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json' // Set content-type to application/json
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "params": {"name": busRoutes}
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _data2 = response.body;
      });
      handleData2();
      return true;
    } else {
      setState(() {
        _data2 = "Failed to create data";
      });
      return false;
    }
  }

  LatLng? currentLocation;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  void getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void trackLocation() {
    var locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        if (currentLocation != null) {
          mapController.move(currentLocation!, 17.0);
        }
      });
    }, onError: (e) {
      print('Error: ${e.toString()}');
    });
  }

  Timer? locationCheckTimer;
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    trackLocation();
    locationCheckTimer =
        Timer.periodic(Duration(seconds: 10), (Timer t) => createDataSearch());
  }

  @override
  void dispose() {
    locationCheckTimer?.cancel();
    super.dispose();
  }

  void _showSuccessToast() {
    const snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เรียกรถสำเร็จ!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                'BUS101',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _searchSuccessToast() {
    const snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ค้นหารถทั้งหมดสำเร็จ!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_bus, size: 30),
            Spacer(),
          ],
        ),
        backgroundColor: Color(0xFFD9D9D9),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedRoute,
                  icon: const Icon(Icons.arrow_drop_down, size: 30),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.blue,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRoute = newValue!;
                    });
                  },
                  items:
                      busRoutes.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      onPressed: () async {
                        var success = await createDataSearch();
                        if (success) {
                          _searchSuccessToast();
                        } else {
                          Fluttertoast.showToast(
                            msg: "Failed to create data search",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      child: const Text('ค้นหา'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      onPressed: () async {
                        var success = await createDataGet();
                        if (success) {
                          _showSuccessToast();
                        } else {
                          Fluttertoast.showToast(
                            msg: "Failed to create data get",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      child: const Text('เรียกรถ'),
                    ),
                  ],
                ),
                // SizedBox(
                //   height: 100,
                //   child: SingleChildScrollView(
                //     child: Text(_data),
                //   ),
                // ),
                // SizedBox(
                //   height: 100,
                //   child: SingleChildScrollView(
                //     child: Text(_data2),
                //   ),
                // ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation ?? LatLng(7.167384, 100.613034),
                initialZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.evo.app',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(7.167384, 100.613034),
                      width: 150,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(Icons.school_outlined,
                                size: 30, color: Colors.blue),
                            SizedBox(height: 5),
                            Text(
                              'อาคารวิทย์',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (currentLocation != null)
                      Marker(
                        point: currentLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(Icons.location_on,
                            size: 40, color: Colors.red),
                      ),
                    if (apiLocation != null)
                      Marker(
                        point: apiLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(Icons.directions_bus,
                            size: 40, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
