import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notifications_screen_one.dart';
import 'constants/routes.dart' as routes;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Local Notifications Demo'),
      routes: <String, WidgetBuilder>{
        routes.notificationsScreenOne: (_) => NotificationsScreenOne(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      final details = await flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        _navigationService(details.payload);
      }
    });
    WidgetsBinding.instance!.addObserver(this);
    initLocalNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('state is $state');
    switch (state) {
      case AppLifecycleState.paused:
        _scheduleNotification();
        break;
      case AppLifecycleState.resumed:
        _cancelAllNotifications();
        break;
    }
  }

  void _cancelAllNotifications() => flutterLocalNotificationsPlugin.cancelAll();

  void initLocalNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    const initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      print(payload);
      _navigationService(payload);
    });
  }

  Future onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title ?? 'title'),
        content: Text(body ?? 'body'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.pushNamed(context, routes.notificationsScreenOne);
            },
          )
        ],
      ),
    );
  }

  void _navigationService(String? payload) {
    if (payload == routes.notificationsScreenOne) {
      Navigator.pushNamed(context, routes.notificationsScreenOne);
    }
  }

  void _scheduleNotification() async {
    print(DateTime.now());
    print(tz.TZDateTime.now(tz.local));
    await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'scheduled title',
        'scheduled body',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'One', 'MyChannel', 'My channel description',
                largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
                importance: Importance.max,
                priority: Priority.high,
                showWhen: false)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: routes.notificationsScreenOne);

    // await flutterLocalNotificationsPlugin.schedule(
    //     1,
    //     'scheduled title',
    //     'scheduled body',
    //     DateTime.now().add(const Duration(seconds: 10)),
    //     const NotificationDetails(
    //         android: AndroidNotificationDetails(
    //             'One', 'MyChannel', 'My channel description',
    //             importance: Importance.max,
    //             priority: Priority.high,
    //             showWhen: false)),
    //     androidAllowWhileIdle: true,
    //     payload: routes.notificationsScreenOne);
  }

  void _displayNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('One', 'MyChannel', 'My channel description',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: routes.notificationsScreenOne);
  }

  void _scheduleIntervalNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('repeating channel id',
            'repeating channel name', 'repeating description');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(0, 'repeating title',
        'repeating body', RepeatInterval.everyMinute, platformChannelSpecifics,
        androidAllowWhileIdle: true);
  }

  Widget _decoratedBox(Widget child, {Color? color}) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
              color: color ?? Theme.of(context).primaryColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _decoratedBox(
                Column(
                  children: <Widget>[
                    Text(
                      'Display notification',
                    ),
                    ElevatedButton(
                      onPressed: _displayNotification,
                      child: Text('One'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _decoratedBox(
                Column(
                  children: <Widget>[
                    Text(
                      'Schedule a notification',
                    ),
                    ElevatedButton(
                      // onPressed: kReleaseMode ? _scheduleNotification : null,
                      onPressed: _scheduleNotification,
                      child: Text('Two'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _decoratedBox(
                Column(
                  children: <Widget>[
                    Text(
                      'Just a push',
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                          context, routes.notificationsScreenOne),
                      child: Text('Three'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _decoratedBox(
                Column(
                  children: <Widget>[
                    Text(
                      'Schedule interval notification',
                    ),
                    ElevatedButton(
                      onPressed: _scheduleIntervalNotification,
                      child: Text('Four'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _decoratedBox(
                Column(
                  children: <Widget>[
                    Text(
                      'Remove all notifications',
                    ),
                    ElevatedButton(
                      onPressed: () => _cancelAllNotifications(),
                      child: Text('Five'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
