import 'package:flutter/material.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/widgets/tile/security.dart';

class Notifications extends StatefulWidget {
  _Notifications createState() => _Notifications();
}

class _Notifications extends State<Notifications> with WidgetsBindingObserver {
  bool _dataSaverState = false;
  PermissionStatus _notificationPermissionStatus;

  bool _foregroundNotificationState = false;
  bool _foregroundNotificationStateProgress = false;

  bool _backgroundNotificationState = false;
  bool _backgroundNotificationStateProgress = false;

  Future<void> _initPreferences() async {
    DataSaverState dataSaverState =
        OnePay.of(context).dataSaverState ?? await getLocalDataSaverState();
    ForegroundNotificationState foregroundNotificationState =
        OnePay.of(context).fNotificationState ??
            await getLocalForegroundNotificationState();
    BackgroundNotificationState backgroundNotificationState =
        OnePay.of(context).bNotificationState ??
            await getLocalBackgroundNotificationState();

    _notificationPermissionStatus =
        await NotificationPermissions.getNotificationPermissionStatus();

    if (foregroundNotificationState == ForegroundNotificationState.Enabled) {
      _foregroundNotificationState = true;
    } else {
      _foregroundNotificationState = false;
    }

    if (backgroundNotificationState == BackgroundNotificationState.Enabled) {
      _backgroundNotificationState = true;
    } else {
      _backgroundNotificationState = false;
    }

    if (dataSaverState == DataSaverState.Enabled) {
      _dataSaverState = true;
    } else {
      _dataSaverState = false;
    }

    setState(() {});
  }

  Future<void> _onForegroundNotificationStateChange(
      BuildContext context, bool value) async {
    setState(() {
      _foregroundNotificationStateProgress = true;
    });

    _foregroundNotificationState = value;

    if (value) {
      OnePay.of(context)
          .appStateController
          .add(ForegroundNotificationState.Enabled);
      await setLocalForegroundNotificationState(
          ForegroundNotificationState.Enabled);
    } else {
      OnePay.of(context)
          .appStateController
          .add(ForegroundNotificationState.Disabled);
      await setLocalForegroundNotificationState(
          ForegroundNotificationState.Disabled);
    }

    setState(() {
      _foregroundNotificationStateProgress = false;
    });
  }

  Future<void> _onBackgroundNotificationStateChange(
      BuildContext context, bool value) async {
    setState(() {
      _backgroundNotificationStateProgress = true;
    });

    _backgroundNotificationState = value;

    if (value) {
      OnePay.of(context)
          .appStateController
          .add(BackgroundNotificationState.Enabled);
      await setLocalBackgroundNotificationState(
          BackgroundNotificationState.Enabled);
    } else {
      OnePay.of(context)
          .appStateController
          .add(BackgroundNotificationState.Disabled);
      await setLocalBackgroundNotificationState(
          BackgroundNotificationState.Disabled);
    }

    setState(() {
      _backgroundNotificationStateProgress = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Future<PermissionStatus> notificationPermissionStatus =
        NotificationPermissions.getNotificationPermissionStatus();
    notificationPermissionStatus.then((status) {
      if (status != _notificationPermissionStatus) {
        setState(() {
          _notificationPermissionStatus = status;
        });
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return ListView(
            children: [
              Visibility(
                visible: _dataSaverState,
                child: Container(
                  child: Text(
                    "Please turn off data-saver inorder to interact with notification settings.",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        // fontSize: 12,
                        color: Colors.orange),
                  ),
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
                ),
              ),
              Visibility(
                visible: _notificationPermissionStatus ==
                        PermissionStatus.denied ||
                    _notificationPermissionStatus == PermissionStatus.unknown,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .iconTheme
                                .color
                                .withOpacity(0.1),
                          ),
                          top: BorderSide(
                            color: Theme.of(context)
                                .iconTheme
                                .color
                                .withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => NotificationPermissions
                            .requestNotificationPermissions(openSettings: true),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 20, 5, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.notification_important_sharp,
                                  color: Theme.of(context).errorColor),
                              SizedBox(width: 10),
                              Text(
                                "System Notification Settings",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Roboto',
                                    color: Theme.of(context).errorColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Text(
                        "Notifications from OnePay are blocked in system settings. "
                        "Tap System Notification Settings to unblock them.",
                        style: TextStyle(
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 10),
                      ),
                    )
                  ],
                ),
              ),
              SecurityTile(
                title: "Notifications",
                desc:
                    "Allow OnePay to forward notifications when your account state changes"
                    " only when your app is running or in foreground.",
                onChange: (value) =>
                    _onForegroundNotificationStateChange(context, value),
                value: _foregroundNotificationState,
                isChanging: _foregroundNotificationStateProgress,
                disabled: _dataSaverState,
              ),
              SecurityTile(
                title: "Background notifications",
                desc:
                    "Allow OnePay to continuously check your account state even if the "
                    "app is closed or not running.",
                onChange: (value) =>
                    _onBackgroundNotificationStateChange(context, value),
                value: _backgroundNotificationState,
                isChanging: _backgroundNotificationStateProgress,
                disabled: _dataSaverState,
              ),
            ],
          );
        },
      ),
    );
  }
}
