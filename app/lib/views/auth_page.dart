import 'package:chainmetric/controllers/references_adapter.dart';
import 'package:flutter/material.dart';
import 'package:chainmetric/controllers/blockchain_adapter.dart';
import 'package:chainmetric/model/auth_model.dart';
import 'package:chainmetric/model/organization_model.dart';

class AuthPage extends StatefulWidget {
  final Function submitAuth;

  AuthPage({Key key, this.submitAuth}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthCredentials credentials = AuthCredentials();

  final _formKey = GlobalKey<FormState>();

  Future<void> submitIdentity() async {
    if (_formKey.currentState.validate()) {
      try {
        if (await Blockchain.authenticate(credentials)) {
          widget.submitAuth();
        }
      } on Exception catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...[
                        Text(
                          "Sign In",
                          style: TextStyle(fontSize: 36),
                        ),
                        DropdownButtonFormField(
                          decoration: InputDecoration(
                            filled: true,
                            hintText: "Choose your organization",
                            labelText: "Organization",
                            fillColor: Colors.teal.shade600,
                          ),
                          items: References.organizations.map<DropdownMenuItem<String>>(
                                  (org) => DropdownMenuItem<String>(
                                        value: org.mspID,
                                        child: Text(org.name),
                                      ))
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "You must specify your organization in order to authenticate";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => credentials.organization = value);
                          },
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              filled: true,
                              hintText: "Enter a certificate",
                              labelText: "Certificate",
                              fillColor: Colors.teal.shade600),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "You must provide certificate to identify you";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => credentials.certificate = value);
                          },
                          maxLines: 5,
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              filled: true,
                              hintText: "Enter a private key",
                              labelText: "Private key",
                              fillColor: Colors.teal.shade600),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "You must provide private key to identify you";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() => credentials.privateKey = value);
                          },
                          maxLines: 5,
                        ),
                        ElevatedButton(
                          onPressed: submitIdentity,
                          child: const Text("Submit identity",
                              style: TextStyle(fontSize: 20)),
                        ),
                      ].expand((widget) => [
                            widget,
                            SizedBox(
                              height: 12,
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
}
