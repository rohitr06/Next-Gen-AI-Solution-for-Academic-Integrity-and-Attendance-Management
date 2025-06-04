import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vibration/vibration.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AttendanceScannerApp());
}


class AttendanceScannerApp extends StatelessWidget {
  const AttendanceScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _showMarkedMessage = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _onDetect(Barcode barcode, MobileScannerArguments? args) async {
  if (_showMarkedMessage) return;

  final String? rawValue = barcode.rawValue;

  if (rawValue != null && rawValue.isNotEmpty) {
    // Save to Firestore attendance collection
    await firestore.collection('attendance').add({
      'barcode': rawValue,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _showMarkedMessage = true;
    });

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 300);
    }

    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _showMarkedMessage = false;
    });
  }
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            allowDuplicates: false,
            onDetect: _onDetect,
          ),
          if (_showMarkedMessage)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText('Attendance matched and marked',
                        speed: const Duration(milliseconds: 100)),
                  ],
                  totalRepeatCount: 1,
                  onFinished: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }
}
