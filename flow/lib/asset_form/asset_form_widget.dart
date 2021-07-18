import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class AssetFormWidget extends StatefulWidget {
  AssetFormWidget({Key key}) : super(key: key);

  @override
  _AssetFormWidgetState createState() => _AssetFormWidgetState();
}

class _AssetFormWidgetState extends State<AssetFormWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.appBarBG,
        automaticallyImplyLeading: true,
        title: Text(
          'New asset',
          style: FlutterFlowTheme.title2.override(
            fontFamily: 'Roboto',
            fontSize: 24,
          ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 4,
      ),
      backgroundColor: FlutterFlowTheme.primaryBG,
    );
  }
}
