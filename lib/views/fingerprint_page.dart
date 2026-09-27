import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocalAuthentication auth = LocalAuthentication();

  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    checkDeviceSupport();
  }

  Future<void> checkDeviceSupport() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        log("support");
      } else {
        log("unsupported");
      }
    } on LocalAuthException catch (e) {
      log("$e");
    } on PlatformException catch (e) {
      log("$e");
    }
    if (!mounted) {
      return;
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason:
            'Scan your fingerprint (or face or whatever) to authenticate',
        // local_auth 3.x replaced AuthenticationOptions with flat parameters.
        // stickyAuth -> persistAcrossBackgrounding, and useErrorDialogs was
        // removed with no replacement.
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on LocalAuthException catch (e) {
      log("$e");
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.description}';
      });
      return;
    } on PlatformException catch (e) {
      log("$e");
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    final String message =
        authenticated ? 'Authorized' : 'Failed to Authorized';
    setState(() {
      _authorized = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 30),
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Divider(height: 100),
                Text('Current State: $_authorized\n'),
                ElevatedButton(
                  onPressed: _authenticateWithBiometrics,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_isAuthenticating
                          ? 'Cancel'
                          : 'Authenticate: biometrics only'),
                      const Icon(Icons.fingerprint),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
