import 'dart:io';

import 'package:check_webview/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Permission.camera.request();
  // await Permission.microphone.request();
  // await Permission.storage.request();

  // if (Platform.isAndroid) {
  //   await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  //
  //   var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
  //       AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
  //   var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
  //       AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);
  //
  //   if (swAvailable && swInterceptAvailable) {
  //     AndroidServiceWorkerController serviceWorkerController =
  //     AndroidServiceWorkerController.instance();
  //
  //     await serviceWorkerController
  //         .setServiceWorkerClient(AndroidServiceWorkerClient(
  //       shouldInterceptRequest: (request) async {
  //         print(request);
  //         return null;
  //       },
  //     ));
  //   }
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ExampleBrowser(),
    );
  }
}
