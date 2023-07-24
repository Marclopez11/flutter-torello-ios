import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project1/notifi_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final service = FlutterBackgroundService();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');

  String? payload = notificationResponse.payload;
  if (payload != null) {
    launchURL(payload); // Call the launchURL function with the payload
  }

  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

void launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    print('Could not launch $url');
  }
}

String uuid = ''; // Variable global 'uuid'
String ids = ''; // Variable global 'uuid'
String subs = ''; // Variable global 'uuid'

Future<void> initializeService() async {
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      // notificationChannelId: 'my_foreground',
      // initialNotificationTitle: 'AWESOME SERVICE',
      // initialNotificationContent: 'Initializing',
      // foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );

  //service.startService();
  //service.invoke("setAsBackground");
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  /// OPTIONAL when use custom notification

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  // bring to foreground
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    //activeBackgroundService();
    NotifiService.showNotification();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotifiService.init();
  // await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late WebViewController controller;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
            activeBackgroundService();
          },
          onPageStarted: (String url) async {
            // await initializeService();
          },
          onPageFinished: (String url) async {},
          onWebResourceError: (WebResourceError error) {},
          onUrlChange: (change) {},
        ),
      )
      ..loadRequest(Uri.parse('https://www.torellojove.cat/webnova/app/'));

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    activeBackgroundService();
  }

  Future<void> stopBackgroundService() async {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    const String jsCode = '''
            var myValue = joveConfig[0].subs;
            myValue.toString();
          ''';

    var subsObject = await controller.runJavaScriptReturningResult(jsCode);
    String subs = subsObject.toString();

    if (subs.contains("0")) {
      service.invoke('stopService');
      print('stop');
    }

    print('subs: $subs');
  }

  Future<void> activeBackgroundService() async {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    const String jsCode = '''
            var myValue = joveConfig[0].subs;
            myValue.toString();
          ''';

    var subsObject = await controller.runJavaScriptReturningResult(jsCode);
    subs = subsObject.toString();

    const String jsCode2 = '''
            var myValue = joveConfig[0].ids;
            myValue.toString();
          ''';

    var subsObject2 = await controller.runJavaScriptReturningResult(jsCode2);
    ids = subsObject2.toString();

    const String jsCode3 = '''
            var myValue = joveConfig[0].uuid;
            myValue.toString();
          ''';

    var subsObject3 = await controller.runJavaScriptReturningResult(jsCode3);
    uuid = subsObject3.toString();

    // bring to foreground
    /* Timer.periodic(const Duration(seconds: 10), (timer) async {
      //   activeBackgroundService();
      NotifiService.showNotification(ids, uuid, subs);
    });*/

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('subs', subs);
    await prefs.setString('ids', ids);
    await prefs.setString('uuid', uuid);

    if (subs.contains("1")) {
      // Guardar los datos en shared_preferences
      print('start initializeService');
      initializeService();
    } else {
      stopBackgroundService();
      print('stop');
    }

    print('subs: $subs');
    print('ids: $ids');
    print('uuid: $uuid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(
          controller: controller,
        ),
      ),
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   activeBackgroundService();
      // }, child: Icon(Icons.abc),),
    );
  }
}
