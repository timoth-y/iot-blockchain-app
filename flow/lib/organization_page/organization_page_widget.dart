import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class OrganizationPageWidget extends StatefulWidget {
  OrganizationPageWidget({Key key}) : super(key: key);

  @override
  _OrganizationPageWidgetState createState() => _OrganizationPageWidgetState();
}

class _OrganizationPageWidgetState extends State<OrganizationPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.primaryBG,
    );
  }
}
