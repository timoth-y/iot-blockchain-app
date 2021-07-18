import 'dart:math';
import 'dart:ui';

import 'package:chainmetric/controllers/bluetooth_adapter.dart';
import 'package:chainmetric/controllers/devices_controller.dart';
import 'package:chainmetric/controllers/gps_adapter.dart';
import 'package:chainmetric/model/device_model.dart';
import 'package:chainmetric/views/components/ripple_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:rect_getter/rect_getter.dart';

import '../../components/jumping_dots_indicator.dart';

class DevicePairing extends StatefulWidget {
  final String deviceID;
  final completeAnimation = Duration(milliseconds: 800);

  DevicePairing(this.deviceID);

  @override
  _DevicePairingState createState() => _DevicePairingState();
}

class _DevicePairingState extends State<DevicePairing> with TickerProviderStateMixin  {
  DiscoveredDevice _device;

  String _message = "Getting things ready";
  double _messageSize = 25.0;

  bool _deviceFound = false;
  double _deviceProximityX = 150;
  double _deviceProximityY = 250;

  Rect _rect;
  GlobalKey _rectGetterKey = RectGetter.createGlobalKey();

  AnimationController _controllerScan;
  Animation _animationScan;
  AnimationController _controllerDevice;
  Animation _animationDevice;
  Path _path;

  Function _cancelScan = () {};


  @override
  void initState() {
    super.initState();

    _controllerScan = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 5000)
    );

    _animationScan = Tween(begin: 0.0, end: 1.0).animate(_controllerScan)
      ..addListener(() {
        setState(() {});
        if (_controllerScan.isCompleted) {
          _controllerScan.repeat();
        }
      });

    _controllerScan.forward();
    _path  = _drawPath();

    _sendCommandToDevice();
  }

  @override
  Widget build(BuildContext context) => Container(
    child: Stack(
      children: [
        Positioned.fill(
          top: 30,
          child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(icon: Icon(Icons.close, size: 35, color: Colors.white.withAlpha(200)), onPressed: _dismiss)
          ),
        ),
        Positioned.fill(
          top: 150,
          child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_message, style: TextStyle(
                      fontSize: _messageSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withAlpha(200)
                  ), textAlign: TextAlign.center),
                  SizedBox(width: 3),
                  JumpingDotsProgressIndicator(
                      fontSize: _messageSize + 5,
                      fontWeight: FontWeight.w900,
                      numberOfDots: 3,
                      color: Colors.white.withAlpha(200)
                  )
                ],
              )
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 500,
            width: 500,
            child: Ripples(
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: _calculate(_animationScan.value).dy,
                      left: _calculate(_animationScan.value).dx,
                      child: Center(child: Icon(Icons.search, size: 30)),
                    ),
                    Positioned.fill(
                      top: _deviceProximityY * -1,
                      left: _deviceProximityX,
                      child: Visibility(
                        visible: _deviceFound,
                        child: RectGetter(
                          key: _rectGetterKey,
                          child: Icon(Icons.memory, size: 50),
                        )
                      ),
                    )
                  ]
                ),
            ),
          ),
        ),
        buildCompletedView()
      ],
    ),
  );

  Widget buildCompletedView() {
    if (_rect == null) {
      return Container();
    }
    return AnimatedPositioned(
      duration: widget.completeAnimation,
      left: _rect.left,
      right: MediaQuery.of(context).size.width - _rect.right,
      top: _rect.top,
      bottom: MediaQuery.of(context).size.height - _rect.bottom,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.teal,
        ),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Visibility(
                  visible: _device != null,
                  child: Positioned.fill(
                    top: 30,
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(icon: Icon(Icons.close, size: 35, color: Colors.white.withAlpha(200)), onPressed: _dismiss)
                    ),
                  ),
                ),
                Visibility(
                  visible: _device != null,
                  child: Positioned.fill(
                    top: -300,
                    child: Center(
                      child: Text("Successfully paired with ${"Chainmetric IoT"}!", style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ), textAlign: TextAlign.center),
                    ),
                  ),
                ),
                Center(
                    child: Icon(Icons.memory, size: 50 + _animationDevice.value)
                ),
                Visibility(
                  visible: _device != null,
                  child: Positioned.fill(
                    top: 300,
                    child: Center(
                      child: Text("Now this device would be able to access GPS location from your phone", style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ), textAlign: TextAlign.center),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendCommandToDevice() async {
    setState(() {
      _messageSize = 22;
      _message = "Sending command to the device";
    });
    var ok = await DevicesController.sendCommand(widget.deviceID, DeviceCommand.pairBluetooth);
    if (ok) {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _messageSize = 22;
          _message = "Scanning devices nearby";
        });

        _scanForDevice();
      });
    }
  }

  void _scanForDevice() {
    _cancelScan = Bluetooth.discoverDevice(widget.deviceID, onFound: (device) {
      _displayDevice(device);
      setState(() => _message = "Pairing with ${device.name}");
      _pairWithDevice(device);
    });
  }

  void _pairWithDevice(DiscoveredDevice device) {
    Bluetooth.connectToDevice(widget.deviceID, onConnect: (_) async {
      setState(() => _message = "Paired! Sending your GPS location");
      await GeoService.postLocation(widget.deviceID);
      _showCompleteView(device);
    });
  }

  void _displayDevice(DiscoveredDevice device) {
    var rand = Random(DateTime.now().millisecond);
    setState(() {
      _deviceProximityX = ((rand.nextBool() ? 1 : -1) * (100 + rand.nextInt(200))).toDouble();
      _deviceProximityY = ((rand.nextBool() ? 1 : -1) * (100 + rand.nextInt(200))).toDouble();
      _deviceFound = true;
    });
  }

  void _showCompleteView(DiscoveredDevice device) {
    _controllerDevice = AnimationController(
        vsync: this,
        duration: widget.completeAnimation
    );

    _animationDevice = Tween(begin: 0.0, end: 100.0).animate(_controllerDevice)
      ..addListener(() {
        setState(() {
          if (_controllerDevice.isCompleted) {
            _device = device;
          }
        });
      });

    setState(() => _rect = RectGetter.getRectFromKey(_rectGetterKey));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerDevice.forward();
      setState(() => _rect = _rect.inflate(MediaQuery.of(context).size.longestSide));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _rect = Rect.fromLTWH(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2, 0, 0).
        inflate(MediaQuery.of(context).size.longestSide);
      });
    });
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  Path _drawPath(){
    Path path = Path();
    path.addOval(Rect.fromCircle(radius: 25, center: Offset.zero));
    return path;
  }

  Offset _calculate(value) {
    PathMetrics pathMetrics = _path.computeMetrics();
    PathMetric pathMetric = pathMetrics.elementAt(0);
    value = pathMetric.length * value;
    Tangent pos = pathMetric.getTangentForOffset(value);
    return pos.position;
  }

  @override
  void dispose() {
    _controllerScan.dispose();
    _controllerDevice?.dispose();
    _cancelScan();
    super.dispose();
  }
}


