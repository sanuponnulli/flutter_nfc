import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform, sleep;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:logging/logging.dart';
import 'package:ndef/ndef.dart' as ndef;

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(MaterialApp(
      theme: ThemeData(
          useMaterial3: true,
          splashColor: Colors.green,
          primaryColor: Colors.greenAccent),
      home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String _platformVersion = '';
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String? _result, _writeResult;
  late TabController _tabController;
  List<ndef.NDEFRecord>? _records;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb)
      _platformVersion =
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    else
      _platformVersion = 'Web';
    initPlatformState();
    _tabController = new TabController(length: 2, vsync: this);
    _records = [];
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
      _availability = availability;
    });
  }

  String extractTextFromRecord(String textRecord) {
    List<String> lines = textRecord.split('\n');
    String extractedText = "N/A";

    for (String line in lines) {
      if (line.startsWith("text=")) {
        extractedText = "";
        extractedText = line.substring("text=".length);
        break;
      }
    }

    return extractedText;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('NFC Flutter'),
        ),
        body: Scrollbar(
            child: SingleChildScrollView(
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
              const SizedBox(height: 20),
              Text('Running on: $_platformVersion\nNFC: $_availability'),
              const SizedBox(height: 10),
              ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll<Color>(Colors.green)),
                onPressed: () async {
                  try {
                    NFCTag tag = await FlutterNfcKit.poll();
                    setState(() {
                      _tag = tag;
                    });
                    await FlutterNfcKit.setIosAlertMessage("Working on it...");
                    // if (tag.standard == "ISO 14443-4 (Type B)") {
                    //   // String result1 =
                    //   //     await FlutterNfcKit.transceive("060080080100");
                    //   // setState(() {
                    //   //   _result = '1: $result1\n';
                    //   // });
                    //   String result1 =
                    //       await FlutterNfcKit.transceive("00B0950000");
                    //   result1 += "ISO 14443-4 (Type B)";
                    //   String result2 = await FlutterNfcKit.transceive(
                    //       "00A4040009A00000000386980701");

                    //   setState(() {
                    //     _result = "ISO 14443-4 (Type B)";
                    //     // _result = '1: $result1\n2: $result2\n';
                    //   });
                    // } else if (tag.type == NFCTagType.iso18092) {
                    //   String result1 =
                    //       await FlutterNfcKit.transceive("060080080100");

                    //   setState(() {
                    //     _result = "NFCTagType.iso18092";
                    //     // _result = '1: $result1\n';
                    //   });
                    // } else
                    if (tag.type == NFCTagType.mifare_ultralight ||
                        tag.type == NFCTagType.mifare_classic ||
                        tag.type == NFCTagType.iso15693) {
                      var ndefRecords = await FlutterNfcKit.readNDEFRecords();
                      var ndefString = '';
                      for (int i = 0; i < ndefRecords.length; i++) {
                        ndefString += ndefRecords[i].basicInfoString;
                        ndefString += ndefRecords[i].idString;
                        if (ndefRecords[i].payload != null) {
                          ndefString += utf8.decode(ndefRecords[i].payload!);
                        }
                      }

                      // _result += "NFCTagType.mifare_ultralight ";
                      setState(() {
                        _result = ndefString;
                      });
                    } else if (tag.type == NFCTagType.webusb) {
                      var r = await FlutterNfcKit.transceive(
                          "00A4040006D27600012401");
                      log(r);
                    }
                  } catch (e) {
                    setState(() {
                      _result = 'error: $e';
                    });
                  }

                  // Pretend that we are working
                  if (!kIsWeb) sleep(new Duration(seconds: 1));
                  await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
                },
                child: const Text('Start polling'),
              ),
              const SizedBox(height: 10),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _tag != null
                      ? Builder(builder: (context) {
                          final result = extractTextFromRecord(_result ?? "");
                          return Column(
                            children: [
                              Text(
                                result == null
                                    ? "UNABLE TO READ CARD"
                                    : result.toString(),
                                style: const TextStyle(fontSize: 22),
                              ),
                              Text(
                                _result == null
                                    ? "UNABLE TO READ CARD"
                                    : _result.toString(),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          );
                        })
                      : const Text('No tag polled yet.')),
            ])))),
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:io' show Platform, sleep;

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
// import 'package:logging/logging.dart';
// import 'package:ndef/ndef.dart' as ndef;

// void main() {
//   Logger.root.level = Level.ALL; // defaults to Level.INFO
//   Logger.root.onRecord.listen((record) {
//     print('${record.level.name}: ${record.time}: ${record.message}');
//   });
//   runApp(MaterialApp(theme: ThemeData(useMaterial3: true), home: MyApp()));
// }

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
//   String _platformVersion = '';
//   NFCAvailability _availability = NFCAvailability.not_supported;
//   NFCTag? _tag;
//   String? _result, _writeResult;
//   late TabController _tabController;
//   List<ndef.NDEFRecord>? _records;

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     if (!kIsWeb)
//       _platformVersion =
//           '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
//     else
//       _platformVersion = 'Web';
//     initPlatformState();
//     _tabController = new TabController(length: 2, vsync: this);
//     _records = [];
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {
//     NFCAvailability availability;
//     try {
//       availability = await FlutterNfcKit.nfcAvailability;
//     } on PlatformException {
//       availability = NFCAvailability.not_supported;
//     }

//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;

//     setState(() {
//       // _platformVersion = platformVersion;
//       _availability = availability;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('NFC Flutter '),
//         ),
//         body: SingleChildScrollView(
//             child: Center(
//                 child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: <Widget>[
//               const SizedBox(height: 20),
//               Text('Running on: $_platformVersion\nNFC: $_availability'),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   try {
//                     NFCTag tag = await FlutterNfcKit.poll();
//                     setState(() {
//                       _tag = tag;
//                     });
//                     await FlutterNfcKit.setIosAlertMessage("Working on it...");
//                     if (tag.standard == "ISO 14443-4 (Type B)") {
//                       String result1 =
//                           await FlutterNfcKit.transceive("00B0950000");
//                       String result2 = await FlutterNfcKit.transceive(
//                           "00A4040009A00000000386980701");
//                       setState(() {
//                         _result = '1: $result1\n2: $result2\n';
//                       });
//                     } else if (tag.type == NFCTagType.iso18092) {
//                       String result1 =
//                           await FlutterNfcKit.transceive("060080080100");
//                       setState(() {
//                         _result = '1: $result1\n';
//                       });
//                     } else if (tag.type == NFCTagType.mifare_ultralight ||
//                         tag.type == NFCTagType.mifare_classic ||
//                         tag.type == NFCTagType.iso15693) {
//                       var ndefRecords = await FlutterNfcKit.readNDEFRecords();
//                       var ndefString = '';
//                       for (int i = 0; i < ndefRecords.length; i++) {
//                         ndefString += '${i + 1}: ${ndefRecords[i]}\n';
//                       }
//                       setState(() {
//                         _result = ndefString;
//                       });
//                     } else if (tag.type == NFCTagType.webusb) {
//                       var r = await FlutterNfcKit.transceive(
//                           "00A4040006D27600012401");
//                       print(r);
//                     }
//                   } catch (e) {
//                     setState(() {
//                       _result = 'error: $e';
//                     });
//                   }

//                   // Pretend that we are working
//                   if (!kIsWeb) sleep(new Duration(seconds: 1));
//                   await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
//                 },
//                 child: Text('Start polling'),
//               ),
//               const SizedBox(height: 10),
//               Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _tag != null
//                       ? Text(
//                           'ID: ${_tag!.id}\nStandard: ${_tag!.standard}\nType: ${_tag!.type}\nATQA: ${_tag!.atqa}\nSAK: ${_tag!.sak}\nHistorical Bytes: ${_tag!.historicalBytes}\nProtocol Info: ${_tag!.protocolInfo}\nApplication Data: ${_tag!.applicationData}\nHigher Layer Response: ${_tag!.hiLayerResponse}\nManufacturer: ${_tag!.manufacturer}\nSystem Code: ${_tag!.systemCode}\nDSF ID: ${_tag!.dsfId}\nNDEF Available: ${_tag!.ndefAvailable}\nNDEF Type: ${_tag!.ndefType}\nNDEF Writable: ${_tag!.ndefWritable}\nNDEF Can Make Read Only: ${_tag!.ndefCanMakeReadOnly}\nNDEF Capacity: ${_tag!.ndefCapacity}\n\n Transceive Result:\n$_result')
//                       : const Text('No tag polled yet.')),
//             ]))),
//       ),
//     );
//   }
// }
