import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'api.dart';
import 'notify_model.dart';

class NotifiService {
  static int index = 0;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static init() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher');

    InitializationSettings initializationSettings =
        const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'MY FOREGROUND SERVICE', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.low, // importance must be at low or higher level
    );

    //const InitializationSettings initializationSettings =
    //    InitializationSettings(
    //  android: initializationSettingsAndroid,
    //);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(
        initializationSettings
        /* onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        print(notificationResponse.toString());
        String link = notificationResponse.payload ?? '';
        if(link != '') {

          var urllaunchable = await canLaunchUrlString(link); //canLaunch is from url_launcher package
          if(urllaunchable){
            await launchUrlString(link); //launch is from url_launcher package to launch URL
          }else{
            print("URL can't be launched.");
          }

        }
      }*/
        ,
        onDidReceiveNotificationResponse: openNotification
        // onDidReceiveBackgroundNotificationResponse: notificationTapBackground
        );
  }

  @pragma('vm:entry-point')
  static void openNotification(
      NotificationResponse notificationResponse) async {
    print(notificationResponse.toString());
    String link = notificationResponse.payload ?? '';

    if (link != '') {
      //var urllaunchable = await canLaunchUrlString(link); //canLaunch is from url_launcher package
      //if (urllaunchable) {
      await launchUrlString(
          link); //launch is from url_launcher package to launch URL
      //} else {
      await launchUrlString(
          link); // Suponiendo que tienes la función launchUrlString
      //}
    }
  }

  static showNotification() async {
    List<NotifyModel> data = await Api.getData();

    //if (data.isNotEmpty) {
    // Verificar si la lista tiene elementos
    int index = 0; // Índice inicial
    while (index < data.length) {
      /* while (true) {
        int newValue = Random().nextInt(data.length);
        if (newValue != index) {
          index = newValue;
          break;
        }
      }*/

      var filePath =
          await Api().getImageFromApiAndShowNotification(data[index].icon!);

      var bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath!),
        largeIcon: FilePathAndroidBitmap(filePath),
        contentTitle: data[index].title ?? 'No title',
        summaryText: data[index].text ?? 'No body',
      );

      AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigPictureStyleInformation,
        ticker: 'ticker',
        icon: '@drawable/ic_launcher',
      );

      // Obtener un ID aleatorio único para cada notificación
      int notificationId = generateRandomNotificationId();

      NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        data[index].title ?? 'No title',
        data[index].text ?? 'No body',
        notificationDetails,
        payload: data[index].link,
      );
      index++;
    }
    // }
  }

  // Generar una función que genere IDs aleatorios únicos
  static int generateRandomNotificationId() {
    Random random = Random();
    return random.nextInt(999999);
  }
}
