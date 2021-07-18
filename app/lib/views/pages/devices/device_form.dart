import 'dart:async';
import 'dart:io';

import 'package:chainmetric/model/location_model.dart';
import 'package:flutter/material.dart';
import 'package:chainmetric/controllers/devices_controller.dart';
import 'package:chainmetric/controllers/references_adapter.dart';
import 'package:chainmetric/model/device_model.dart';
import 'package:chainmetric/shared/exceptions.dart';
import 'package:chainmetric/shared/utils.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:multi_select_flutter/bottom_sheet/multi_select_bottom_sheet_field.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:overlay_screen/overlay_screen.dart';
import 'package:place_picker/entities/location_result.dart';
import 'package:place_picker/widgets/place_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class DeviceForm extends StatefulWidget {
  final Device model;

  DeviceForm({this.model});

  @override
  _DeviceFormState createState() => _DeviceFormState(model);
}

class _DeviceFormState extends State<DeviceForm> {
  Device device;
  QRViewController controller;
  String scannerTitle = defaultScannerTitle;
  String scannerSubtitle = defaultScannerSubtitle;
  bool flashOn = false;

  static const defaultScannerTitle = "Scan the device QR code";
  static const defaultScannerSubtitle = "The near by device will automatically display QR code with it's specification";
  final GlobalKey _qrKey = GlobalKey(debugLabel: "QR");
  final _formKey = GlobalKey<FormState>();

  _DeviceFormState(Device device) {
    this.device = device;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return device == null ? _buildScanner(context) : _buildForm(context);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register device"),
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...[
                        TextFormField(
                          initialValue: device.name,
                          decoration: InputDecoration(
                            filled: true,
                            hintText: "Enter an device name",
                            labelText: "Name",
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Please provide name for the device";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => device.name = value);
                          },
                        ),
                        TextFormField(
                          initialValue: device.hostname,
                          decoration: InputDecoration(
                            filled: true,
                            hintText: "Enter the device hostname",
                            labelText: "Hostname",
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Please provide device hostname";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => device.hostname = value);
                          },
                        ),
                        DropdownButtonFormField(
                          value: device.profile,
                          decoration: InputDecoration(
                            filled: true,
                            hintText: "Choose the device profile",
                            labelText: "Profile",
                          ),
                          items: References.deviceProfiles
                              .map<DropdownMenuItem<String>>(
                                  (profile) => DropdownMenuItem<String>(
                                        value: profile.profile,
                                        child: Text(profile.name),
                                      ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => device.profile = value);
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            boxShadow: kElevationToShadow[1],
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: Column(
                            children: [
                              MultiSelectBottomSheetField(
                                initialValue: device.supports,
                                title: Text("Supports metrics"),
                                buttonText: Text("Select supported metrics"),
                                listType: MultiSelectListType.CHIP,
                                chipColor: Colors.teal.shade800,
                                selectedColor: Colors.teal,
                                selectedItemsTextStyle: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                buttonIcon: Icon(Icons.arrow_drop_down),
                                items: References.metrics
                                    .map((metric) => MultiSelectItem(
                                          metric.metric,
                                          metric.name,
                                        ))
                                    .toList(),
                                onSelectionChanged: (value) {
                                  setState(() => device.supports = value);
                                },
                              ),
                              MultiSelectChipDisplay(
                                chipColor: Colors.teal,
                                textStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                items: device.supports
                                    .map((metric) => MultiSelectItem(
                                          metric,
                                          References.metricsMap[metric]?.name ?? "",
                                        ))
                                    .toList(),
                                onTap: (value) {
                                  setState(() => device.supports.remove(value));
                                },
                              )
                            ],
                          ),
                        ),
                        DropdownButtonFormField(
                          value: device.holder,
                          decoration: InputDecoration(
                            hintText: "Choose the holder organization",
                            labelText: "Holder",
                            filled: true,
                          ),
                          items: References.organizations
                              .map<DropdownMenuItem<String>>(
                                  (org) => DropdownMenuItem<String>(
                                        value: org.mspID,
                                        child: Text(org.name),
                                      ))
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please choose an holder organization";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => device.holder = value);
                          },
                        ),
                        SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _showLocationPicker,
                              style: ElevatedButton.styleFrom(
                                primary: Theme.of(context).inputDecorationTheme.fillColor,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_pin,
                                    color: Theme.of(context).hintColor,
                                    size: 26,
                                  ),
                                  SizedBox(width: 10),
                                  Text("Pick location",
                                    style: TextStyle(
                                        fontSize: 17,
                                        color: Theme.of(context).hintColor
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: decorateWithLoading(context, _submitDevice),
                              child: const Text("Register device",
                                  style: TextStyle(fontSize: 20)),
                            )),
                      ].expand((widget) => [
                            widget,
                            SizedBox(
                              height: 24,
                            )
                          ])
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          QRView(
            key: _qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.teal,
            ),
          ),
          Positioned.fill(
            top: 25,
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                  icon: Icon(Icons.arrow_back, size: 30),
                  onPressed: () => Navigator.pop(context)
              )
            )
          ),
          Positioned.fill(
              top: 25,
              child: Align(
                alignment: Alignment.topRight,
                  child: IconButton(
                      icon: Icon(flashOn ? Icons.flash_off : Icons.flash_on, size: 30),
                      onPressed: () {
                        controller.toggleFlash();
                        setState(() => flashOn = !flashOn);
                      }
                  )
              )
          ),
          Positioned.fill(
            top: -350,
            child: Center(
              child: Text(scannerTitle,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
              )
            )
          ),
          Positioned.fill(
            top: 350,
            child: Center(
              child: Text(scannerSubtitle,
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center
              )
            )
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    Timer timer;

    controller.scannedDataStream.listen((scanData) {
      if (scanData != null) {
        Device dev;
        try {
          dev = _parseQRCode(scanData.code);
          dev.name = dev.hostname;
          dev.profile = "common";
        } on QRScanException catch (e) {
          setState(() {
            scannerTitle = e.problem;
            scannerSubtitle = e.cause;
          });
          if (timer != null) timer.cancel();
          timer = Timer(Duration(seconds: 5), () {
            setState(() {
              scannerTitle = defaultScannerTitle;
              scannerSubtitle = defaultScannerSubtitle;
            });
          });
          return;
        }
        controller?.dispose();
        setState(() => device = dev);
      }
    });
  }

  Device _parseQRCode(String code) {
    var exp = RegExp(r"\$\{(.+?)\}");
    var match = exp.firstMatch(code);
    if (match == null) throw QRScanException(cause: "Expected pattern does not match");

    var data = match.group(1);
    var parts = data.split(';');
    if (parts.length != 3) throw QRScanException(cause: "Coded data is not valid");

    Device dev = Device();

    dev.hostname = parts[0];
    dev.ip = parts[1];

    var metrics = parts[2].split(',');

    dev.supports = metrics;

    return dev;
  }

  Future<void> _submitDevice() async {
    if (_formKey.currentState.validate()) {
      try {
        if (await DevicesController.registerDevice(device)) {
          Navigator.pop(context);
        }
      } on Exception catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showLocationPicker() async {
    LocationResult result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) =>
            PlacePicker(GlobalConfiguration().getValue("geo_location_api_key"),
            )
        )
    );

    if (result != null) {
      setState(() {
        device.location = Location()
          ..latitude = result.latLng.latitude
          ..longitude = result.latLng.longitude
          ..name = result.name;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location wasn't picked, please try again"))
      );
    }
  }
}
