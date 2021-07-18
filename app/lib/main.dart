import 'package:chainmetric/controllers/bluetooth_adapter.dart';
import 'package:chainmetric/controllers/gps_adapter.dart';
import 'package:chainmetric/controllers/preferences_adapter.dart';
import 'package:chainmetric/main_theme.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:chainmetric/model/readings_model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:chainmetric/model/device_model.dart';
import 'package:chainmetric/model/metric_model.dart';
import 'package:chainmetric/model/requirements_model.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:overlay_screen/overlay_screen.dart';
import 'package:yaml/yaml.dart';

import 'controllers/references_adapter.dart';
import 'main.reflectable.dart';
import 'package:chainmetric/controllers/blockchain_adapter.dart';
import 'views/pages/auth/auth_page.dart';
import 'package:chainmetric/views/components/loading_splash.dart';

import 'model/asset_model.dart';
import 'model/organization_model.dart';
import 'views/main_page.dart';
import 'package:flutter/material.dart';


void main() async {
  init();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _requireAuth = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initConfig();
    _initBackend();
    _initOverlay();
  }

  ThemeData mainTheme() => darkTheme;

  ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    backgroundColor: AppTheme.primaryBG,
    scaffoldBackgroundColor: AppTheme.primaryBG,
    primaryColor: AppTheme.primaryColor,
    primarySwatch: Colors.teal,
    bottomAppBarTheme: BottomAppBarTheme(
      color: AppTheme.appBarBG,
    ),
    cardColor: AppTheme.cardBG,
    textTheme: TextTheme(
      headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
      headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
      bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppTheme.inputBG,
    )
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "IoTChain client app",
      theme: mainTheme(),
      darkTheme: darkTheme,
      home: _isLoading
          ? LoadingSplash()
          : _requireAuth
              ? AuthPage(submitAuth: _initBackend)
              : MainPage(),
    );
  }

  Future<void> _initBackend() async {
    await Preferences.init();
    await References.init();
    await Blockchain.initWallet();
    if (await Blockchain.authRequired()) {
      setState(() => _isLoading = false);
      return;
    }
    await Blockchain.initConnection("supply-channel");
    setState(() => _requireAuth = _isLoading = false);

    await Bluetooth.init();
  }

  void _initOverlay() {
    OverlayScreen().saveScreens({
      "modal": CustomOverlayScreen(
        backgroundColor: darkTheme.primaryColor.withAlpha(225),
        content: Center(),
      ),
      "loading": CustomOverlayScreen(
        backgroundColor: darkTheme.primaryColor.withAlpha(225),
        content: LoadingBouncingGrid.square(
            size: 75,
            backgroundColor: Colors.teal.shade600,
            borderColor: Colors.black54
        ),
      ),
    });
  }
}

void init() {
  initJson();
}

Future<void> initConfig() async {
  YamlMap yaml = loadYaml(
      await rootBundle.loadString("assets/config.yaml")
  );

  GlobalConfiguration().loadFromMap(
  Map<String, dynamic>.fromIterable(yaml.keys, key: (key) => key, value: (key) => yaml[key])
  );
}

void initJson() {
  initializeReflectable();
  JsonMapper().useAdapter(JsonMapperAdapter(
      valueDecorators: {
        typeOf<List<String>>(): (value) => value.cast<String>(),
        typeOf<List<Asset>>(): (value) => value.cast<Asset>(),
        typeOf<List<AssetResponseItem>>(): (value) => value.cast<AssetResponseItem>(),
        typeOf<List<Device>>(): (value) => value.cast<Device>(),
        typeOf<List<Organization>>(): (value) => value.cast<Organization>(),
        typeOf<List<AssetType>>(): (value) => value.cast<AssetType>(),
        typeOf<List<DeviceProfile>>(): (value) => value.cast<DeviceProfile>(),
        typeOf<List<Metric>>(): (value) => value.cast<Metric>(),
        typeOf<Map<String, Requirement>>(): (value) => Map<String, Requirement>.from(value),
        typeOf<Map<String, List<MetricReadingPoint>>>(): (value) => Map<String, List<MetricReadingPoint>>.from(value),
        typeOf<List<MetricReadingPoint>>(): (value) => value.cast<MetricReadingPoint>(),
        typeOf<MetricReadingsStream>(): (value) => MetricReadingsStream.from(value.cast<MetricReadingPoint>().toList()),
        typeOf<List<DeviceCommandLogEntry>>(): (value) => value.cast<DeviceCommandLogEntry>(),
        typeOf<Map<String, PairedDevice>>(): (value) => Map<String, PairedDevice>.from(value),
      },
    enumValues: {
        DeviceCommand: EnumDescriptor(
            values: DeviceCommand.values,
            mapping: <DeviceCommand, String>{
              DeviceCommand.pause: "pause",
              DeviceCommand.resume: "resume",
              DeviceCommand.pairBluetooth: "ble_pair"
            }
        ),
    })
  );
}
