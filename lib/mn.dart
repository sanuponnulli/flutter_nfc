// import 'dart:developer';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'NFC Reader App',
//       home: NFCReaderScreen(),
//     );
//   }
// }

// class NFCReaderScreen extends StatefulWidget {
//   @override
//   _NFCReaderScreenState createState() => _NFCReaderScreenState();
// }

// class _NFCReaderScreenState extends State<NFCReaderScreen> {
//   String _nfcData = 'Scan an NFC tag';

//   Future<void> _startNFC() async {
//     try {
//       final result = await FlutterNfcKit.transceive(
//           Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x07]));

//       log(result.toString());
//       // if (result.success) {
//       //   setState(() {
//       //     _nfcData = result.content;
//       //   });
//       // } else {
//       //   setState(() {
//       //     _nfcData = 'Error reading NFC: ${result.errorMessage}';
//       //   });
//       // }
//     } catch (e) {
//       print(e.toString());
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('NFC Reader'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Text(
//               _nfcData,
//               style: TextStyle(fontSize: 18),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _startNFC,
//               child: Text('Start NFC Reading'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
