import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../api/check_pin_api.dart';
import 'bus.dart';

class PinCodeWidget extends StatefulWidget {
  const PinCodeWidget({super.key});

  @override
  State<PinCodeWidget> createState() => _PinCodeWidgetState();
}

class _PinCodeWidgetState extends State<PinCodeWidget> {
  final CheckPinApi checkPinApi = CheckPinApi();
  String enteredPin = '';
  String checkpin = '';
  String check = '';
  String ipAddress = '49.0.69.152'; //add
  bool isPinVisible = false;

  // Start for call API
  void startCheckPin(String chkpin) async {
    List<Map<String, dynamic>> tmpResult = [];
    check = '';

    if (ipAddress.isEmpty) {
      // หาก IP Address ว่าง แสดงข้อความเตือน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter IP Address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Call API
    await checkPinApi.checkPin(pin: chkpin, ipAddress: ipAddress).then((value) {
      tmpResult = value.cast<Map<String, dynamic>>();
    });

    String check_code;

    for (Map<String, dynamic>? message in tmpResult) {
      check_code = message?['code'] ??
          ''; // ถ้า code เป็น null จะใช้ค่าเริ่มต้นเป็น '' (string ว่าง)
      check = message?['message'] ??
          ''; // ถ้า message เป็น null จะใช้ค่าเริ่มต้นเป็น '' (string ว่าง)
    }

    // Check PIN if found next page
    if (check == 'found') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return Bus(ipAddress: ipAddress);
          },
        ),
      );
    } else {
      // If PIN is incorrect, show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รหัส PIN ไม่ถูกต้อง กรุณากรอกใหม่'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  // End call API

  /// This widget will be used for each digit
  Widget numButton(int number) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton(
        onPressed: () {
          setState(() {
            if (enteredPin.length < 4) {
              enteredPin += number.toString();
            }
          });
        },
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const BouncingScrollPhysics(),
          children: [
            const Center(
              child: Text(
                'Enter Your Pin',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 50),

            // เพิ่ม TextField สำหรับกรอก IP Address
            // TextField(
            //   decoration: const InputDecoration(
            //     labelText: 'Enter IP Address',
            //   ),
            //   onChanged: (value) {
            //     setState(() {
            //       ipAddress = value; // อัปเดตค่า IP Address
            //     });
            //   },
            // ),

            const SizedBox(height: 50),

            /// Pin code area
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) {
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    width: isPinVisible ? 50 : 16,
                    height: isPinVisible ? 50 : 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      color: index < enteredPin.length
                          ? isPinVisible
                              ? Colors.green
                              : CupertinoColors.activeBlue
                          : CupertinoColors.activeBlue.withOpacity(0.1),
                    ),
                    child: isPinVisible && index < enteredPin.length
                        ? Center(
                            child: Text(
                              enteredPin[index],
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),

            /// Visibility toggle button
            IconButton(
              onPressed: () {
                setState(() {
                  isPinVisible = !isPinVisible;
                });
              },
              icon: Icon(
                isPinVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),

            SizedBox(height: isPinVisible ? 50.0 : 8.0),

            /// Digits
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (index) => numButton(1 + 3 * i + index),
                  ).toList(),
                ),
              ),

            /// 0 digit with back remove
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TextButton(onPressed: null, child: SizedBox()),
                  numButton(0),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (enteredPin.isNotEmpty) {
                          enteredPin =
                              enteredPin.substring(0, enteredPin.length - 1);
                        }
                      });
                    },
                    child: const Icon(
                      Icons.backspace,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            /// Reset button
            TextButton(
              onPressed: () {
                setState(() {
                  enteredPin = '';
                });
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Check for PIN with JSON Odoo
                checkpin = enteredPin;
                // START CALL API CHECK PIN
                startCheckPin(checkpin);
                // END
              },
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
