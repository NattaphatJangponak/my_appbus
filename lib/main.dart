import 'package:flutter/material.dart';
// import 'package:my_appbus/screen/bus.dart';
import 'package:my_appbus/screen/pin_code_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "My Title",
      home: Scaffold(
        backgroundColor: Color(0xFFD6F1FF),
        // appBar: AppBar(
        //   title: const Text("Login Bus"),
        //   backgroundColor: Color(0xFFD9D9D9),
        // ),
        // body: Login(),
        // body: Bus(ipAddress: '49.0.81.242'),
        body: PinCodeWidget(),
      ),
    );
  }
}
