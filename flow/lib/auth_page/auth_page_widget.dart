import '../flutter_flow/flutter_flow_drop_down_template.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_widgets.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPageWidget extends StatefulWidget {
  AuthPageWidget({Key key}) : super(key: key);

  @override
  _AuthPageWidgetState createState() => _AuthPageWidgetState();
}

class _AuthPageWidgetState extends State<AuthPageWidget> {
  String organizationValue;
  TextEditingController certificateController;
  TextEditingController privateKeyController;
  bool privateKeyVisibility;
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    certificateController = TextEditingController();
    privateKeyController = TextEditingController();
    privateKeyVisibility = false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.primaryBG,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Container(
                      width: 100,
                      height: 250,
                      decoration: BoxDecoration(),
                      child: AutoSizeText(
                        'CHAINMETRIC',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.title1.override(
                          fontFamily: 'IBM Plex Mono',
                          color: Color(0xFF04AFD3),
                          fontSize: 32,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            FlutterFlowDropDown(
                              options: [
                                'Chipa INU',
                                'Blueberry Go',
                                'Moon LAN'
                              ],
                              onChanged: (value) {
                                setState(() => organizationValue = value);
                              },
                              height: 50,
                              textStyle: FlutterFlowTheme.bodyText1.override(
                                fontFamily: 'Roboto Mono',
                              ),
                              icon: Icon(
                                Icons.corporate_fare_sharp,
                                size: 15,
                              ),
                              fillColor: FlutterFlowTheme.formField,
                              elevation: 2,
                              borderColor: Colors.transparent,
                              borderWidth: 0,
                              borderRadius: 8,
                              margin: EdgeInsets.fromLTRB(8, 4, 8, 4),
                              hidesUnderline: true,
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: TextFormField(
                                controller: certificateController,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'CERTIFICATE',
                                  labelStyle:
                                      FlutterFlowTheme.bodyText1.override(
                                    fontFamily: 'Roboto Mono',
                                    color: FlutterFlowTheme.tertiaryColor,
                                  ),
                                  hintText: 'Enter a certificate',
                                  hintStyle:
                                      FlutterFlowTheme.bodyText1.override(
                                    fontFamily: 'Roboto Mono',
                                    color: FlutterFlowTheme.tertiaryColor,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.formField,
                                ),
                                style: FlutterFlowTheme.bodyText1.override(
                                  fontFamily: 'Roboto Mono',
                                  color: FlutterFlowTheme.tertiaryColor,
                                ),
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.multiline,
                                validator: (val) {
                                  if (val.isEmpty) {
                                    return 'You must provide a certificate to identify you';
                                  }
                                  if (val.length < 800) {
                                    return 'Requires at least 800 characters.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: TextFormField(
                                controller: privateKeyController,
                                obscureText: !privateKeyVisibility,
                                decoration: InputDecoration(
                                  labelText: 'PRIVATE KEY',
                                  labelStyle:
                                      FlutterFlowTheme.bodyText1.override(
                                    fontFamily: 'Roboto Mono',
                                    color: FlutterFlowTheme.tertiaryColor,
                                  ),
                                  hintText: 'Enter a private key',
                                  hintStyle:
                                      FlutterFlowTheme.bodyText1.override(
                                    fontFamily: 'Roboto Mono',
                                    color: FlutterFlowTheme.tertiaryColor,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: FlutterFlowTheme.formField,
                                  suffixIcon: InkWell(
                                    onTap: () => setState(
                                      () => privateKeyVisibility =
                                          !privateKeyVisibility,
                                    ),
                                    child: Icon(
                                      privateKeyVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: FlutterFlowTheme.tertiaryColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                style: FlutterFlowTheme.bodyText1.override(
                                  fontFamily: 'Roboto Mono',
                                  color: FlutterFlowTheme.tertiaryColor,
                                ),
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.multiline,
                                validator: (val) {
                                  if (val.isEmpty) {
                                    return 'You must provide a private key to identify you';
                                  }
                                  if (val.length < 200) {
                                    return 'Requires at least 200 characters.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                              child: FFButtonWidget(
                                onPressed: () {
                                  print('Button pressed ...');
                                },
                                text: 'LOGIN',
                                options: FFButtonOptions(
                                  width: 200,
                                  height: 50,
                                  color: FlutterFlowTheme.primaryColor,
                                  textStyle:
                                      FlutterFlowTheme.subtitle2.override(
                                    fontFamily: 'Roboto Mono',
                                    color: FlutterFlowTheme.formField,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  elevation: 3,
                                  borderSide: BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  borderRadius: 12,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
