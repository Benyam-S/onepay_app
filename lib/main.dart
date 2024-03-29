import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/account.provider.dart';
import 'package:onepay_app/models/app.meta.dart';
import 'package:onepay_app/models/currency.rate.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/models/user.preference.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/pages/authorized/authorized.dart';
import 'package:onepay_app/pages/authorized/background.fetch.dart';
import 'package:onepay_app/pages/authorized/settings/accounts/add.account.dart';
import 'package:onepay_app/pages/authorized/settings/accounts/manage.accounts.dart';
import 'package:onepay_app/pages/authorized/settings/notification/notifications.dart';
import 'package:onepay_app/pages/authorized/settings/profile/profile.dart';
import 'package:onepay_app/pages/authorized/settings/profile/update.basic.info.dart';
import 'package:onepay_app/pages/authorized/settings/profile/update.email.dart';
import 'package:onepay_app/pages/authorized/settings/profile/update.phone.number.dart';
import 'package:onepay_app/pages/authorized/settings/recharge/recharge.dart';
import 'package:onepay_app/pages/authorized/settings/security/change.password.dart';
import 'package:onepay_app/pages/authorized/settings/security/security.dart';
import 'package:onepay_app/pages/authorized/settings/security/session.management.dart';
import 'package:onepay_app/pages/authorized/settings/vault/vault.dart';
import 'package:onepay_app/pages/authorized/settings/withdraw/withdraw.dart';
import 'package:onepay_app/pages/forgot.password.dart';
import 'package:onepay_app/pages/signup/signup.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';

import 'models/linked.account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);

  runApp(OnePay());

  BackgroundFetch.registerHeadlessTask(headlessBackgroundFetch);
}

class OnePay extends StatefulWidget {
  @override
  _OnePay createState() => _OnePay();

  static _OnePay of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppState>().appState;
  }
}

class _AppState extends InheritedWidget {
  final _OnePay appState;

  _AppState({Key key, @required Widget child, @required this.appState})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_AppState oldWidget) {
    return oldWidget.appState != this.appState;
  }
}

class _OnePay extends State<OnePay> {
  StreamController _appStateController = StreamController.broadcast();
  Stream _accessTokenStream;
  Stream _userStream;
  Stream _userPreferenceStream;
  Stream _walletStream;
  Stream _historyStream;
  Stream _linkedAccountStream;
  Stream _accountProviderStream;
  Stream _dataSaverStream;
  Stream _fNotificationStream;
  Stream _bNotificationStream;

  AccessToken accessToken;
  User currentUser;
  UserPreference userPreference;
  Wallet userWallet;
  List<History> histories = List<History>();
  List<AccountProvider> accountProviders = List<AccountProvider>();
  List<LinkedAccount> linkedAccounts = List<LinkedAccount>();
  List<CurrencyRate> currencyRates = List<CurrencyRate>();
  DataSaverState dataSaverState;
  ForegroundNotificationState fNotificationState;
  BackgroundNotificationState bNotificationState;
  AppMeta appMetaData;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final navKey = new GlobalKey<NavigatorState>();

  Stream get accessTokenStream => this._accessTokenStream;

  Stream get userStream => this._userStream;

  Stream get userPreferenceStream => this._userPreferenceStream;

  Stream get walletStream => this._walletStream;

  Stream get historyStream => this._historyStream;

  Stream get accountProviderStream => this._accountProviderStream;

  Stream get linkedAccountStream => this._linkedAccountStream;

  Stream get dataSaverStream => this._dataSaverStream;

  Stream get fNotificationStream => this._fNotificationStream;

  Stream get bNotificationStream => this._bNotificationStream;

  StreamController get appStateController => this._appStateController;

  _OnePay() {
    this._accessTokenStream =
        _appStateController.stream.where((event) => event is AccessToken);

    this._userStream =
        _appStateController.stream.where((event) => event is User);

    this._userPreferenceStream =
        _appStateController.stream.where((event) => event is UserPreference);

    this._walletStream =
        _appStateController.stream.where((event) => event is Wallet);

    this._historyStream =
        _appStateController.stream.where((event) => event is List<History>);

    this._accountProviderStream = _appStateController.stream
        .where((event) => event is List<AccountProvider>);

    this._linkedAccountStream = _appStateController.stream
        .where((event) => event is List<LinkedAccount>);

    this._dataSaverStream =
        _appStateController.stream.where((event) => event is DataSaverState);

    this._fNotificationStream = _appStateController.stream
        .where((event) => event is ForegroundNotificationState);

    this._bNotificationStream = _appStateController.stream
        .where((event) => event is BackgroundNotificationState);

    this._accessTokenStream.listen((accessToken) {
      this.accessToken = accessToken as AccessToken;
    });

    this._userStream.listen((user) {
      this.currentUser = user as User;
    });

    this._userPreferenceStream.listen((userPreference) {
      this.userPreference = userPreference as UserPreference;
    });

    this._walletStream.listen((wallet) {
      this.userWallet = wallet as Wallet;
    });

    this._historyStream.listen((histories) {
      _filterAndAddHistories(histories);
    });

    this._accountProviderStream.listen((accountProviders) {
      _filterAndAddAccountProviders(accountProviders);
    });

    this._linkedAccountStream.listen((linkedAccounts) {
      _filterAndAddLinkedAccounts(linkedAccounts);
    });

    this._dataSaverStream.listen((dataSaverState) {
      this.dataSaverState = dataSaverState as DataSaverState;
    });

    this._fNotificationStream.listen((fNotificationState) {
      this.fNotificationState =
          fNotificationState as ForegroundNotificationState;
    });

    this._bNotificationStream.listen((bNotificationState) {
      this.bNotificationState =
          bNotificationState as BackgroundNotificationState;
    });
  }

  void _filterAndAddHistories(List<History> newHistories) {
    List<History> filteredHistories = List<History>();
    newHistories.forEach((newHistory) {
      bool addFlag = true;
      histories.forEach((history) {
        if (history.id == newHistory.id) {
          addFlag = false;
          return;
        }
      });
      if (addFlag) filteredHistories.add(newHistory);
    });

    histories.addAll(filteredHistories);
    // Ordering in reverse order
    histories.sort((a, b) => b.id.compareTo(a.id));
  }

  void _filterAndAddAccountProviders(
      List<AccountProvider> newAccountProviders) {
    List<AccountProvider> filteredAccountProviders = List<AccountProvider>();
    newAccountProviders.forEach((newAccountProvider) {
      bool addFlag = true;
      accountProviders.forEach((accountProvider) {
        if (accountProvider.id == newAccountProvider.id) {
          addFlag = false;
          return;
        }
      });
      if (addFlag) filteredAccountProviders.add(newAccountProvider);
    });

    accountProviders.addAll(filteredAccountProviders);

    // Since we can't set accountProviders to empty set
    // Removing all the previous account providers not found in the current response
    accountProviders.removeWhere((prevAccountProvider) {
      bool removeFlag = true;

      newAccountProviders.forEach((newAccountProvider) {
        if (prevAccountProvider.id == newAccountProvider.id) {
          removeFlag = false;
          return;
        }
      });

      return removeFlag;
    });

    accountProviders.sort((a, b) => a.name.compareTo(b.name));
  }

  void _filterAndAddLinkedAccounts(List<LinkedAccount> newLinkedAccounts) {
    List<LinkedAccount> filteredLinkedAccounts = List<LinkedAccount>();
    newLinkedAccounts.forEach((newLinkedAccount) {
      bool addFlag = true;

      linkedAccounts.forEach((linkedAccount) {
        if (linkedAccount.id == newLinkedAccount.id) {
          linkedAccount.copyWith(newLinkedAccount);
          addFlag = false;
          return;
        }
      });

      if (addFlag) filteredLinkedAccounts.add(newLinkedAccount);
    });

    linkedAccounts.addAll(filteredLinkedAccounts);

    // Since we can't set linkedAccounts to empty set
    // Removing all the previous linked accounts not found in the current response
    linkedAccounts.removeWhere((prevLinkedAccount) {
      bool removeFlag = true;

      newLinkedAccounts.forEach((newLinkedAccount) {
        if (prevLinkedAccount.id == newLinkedAccount.id) {
          removeFlag = false;
          return;
        }
      });

      return removeFlag;
    });

    linkedAccounts
        .sort((a, b) => a.accountProviderName.compareTo(b.accountProviderName));
  }

  void _initNotificationChannel() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _selectNotification);
  }

  Future _selectNotification(String payload) async {
    bool loggedIn = await isLoggedIn();

    if (loggedIn) {
      await navKey.currentState.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => Authorized(index: 3),
          ),
          (Route<dynamic> route) => false);
    } else {
      await navKey.currentState.pushNamedAndRemoveUntil(
          AppRoutes.logInRoute, (Route<dynamic> route) => false);
    }
  }

  @override
  void initState() {
    super.initState();

    getAppMeta().then((appMeta) => appMetaData = appMeta);
    getLocalDataSaverState().then((dataSaverS) => dataSaverState = dataSaverS);

    _initNotificationChannel();
    _initBackgroundFetchState();
  }

  Future<void> _initBackgroundFetchState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 40,
          forceAlarmManager: false,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ),
        (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return _AppState(
      appState: this,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navKey,
        theme: ThemeData(
            inputDecorationTheme: InputDecorationTheme(
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(color: Color.fromRGBO(4, 148, 255, 1)),
              errorStyle: TextStyle(fontSize: 9, fontFamily: "Segoe UI"),
            ),
            snackBarTheme: SnackBarThemeData(
                backgroundColor: Color.fromRGBO(78, 78, 78, 1),
                contentTextStyle: TextStyle(fontSize: 11)),
            appBarTheme: AppBarTheme(color: Color.fromRGBO(6, 103, 208, 1)),
            tabBarTheme: TabBarTheme(
                labelPadding: EdgeInsets.zero,
                unselectedLabelColor: Color.fromRGBO(4, 148, 255, 1),
                labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Raleway"),
                unselectedLabelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Raleway")),
            iconTheme: IconThemeData(color: Color.fromRGBO(120, 120, 120, 1)),
            primaryColor: Color.fromRGBO(4, 148, 255, 1),
            backgroundColor: Color.fromRGBO(249, 250, 254, 1),
            textTheme: TextTheme(
                bodyText2: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontFamily: "Segoe UI"),
                subtitle1:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                overline: TextStyle(fontSize: 9),
                headline3: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 10, fontFamily: "Segoe UI"),
                headline5: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 15, fontFamily: "Segoe UI"),
                headline6: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 14, fontFamily: "Segoe UI")),
            buttonTheme: Theme.of(context).buttonTheme.copyWith(
                buttonColor: Color.fromRGBO(4, 148, 255, 1),
                disabledColor: Color.fromRGBO(4, 148, 255, 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                )),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Color.fromRGBO(4, 148, 255, 1),
                primaryVariant: Color.fromRGBO(6, 103, 208, 1),
                secondary: Color.fromRGBO(209, 87, 17, 1),
                surface: Color.fromRGBO(120, 120, 120, 1),
                secondaryVariant: Color.fromRGBO(153, 39, 0, 1))),
        routes: {
          AppRoutes.logInRoute: (context) => Authorized(),
          AppRoutes.singUpRoute: (context) => SignUp(),
          AppRoutes.forgotPasswordRoute: (context) => ForgotPassword(),
          AppRoutes.authorizedRoute: (context) => Authorized(),
          AppRoutes.moneyVault: (context) => MoneyVault(),
          AppRoutes.recharge: (context) => Recharge(),
          AppRoutes.withdraw: (context) => Withdraw(),
          AppRoutes.accounts: (context) => ManageAccounts(),
          AppRoutes.addAccount: (context) => AddLinkedAccount(),
          AppRoutes.profile: (context) => Profile(),
          AppRoutes.updateBasicInfo: (context) => UpdateBasicInfo(),
          AppRoutes.updateEmail: (context) => UpdateEmail(),
          AppRoutes.updatePhoneNumber: (context) => UpdatePhoneNumber(),
          AppRoutes.security: (context) => Security(),
          AppRoutes.notification: (context) => Notifications(),
          AppRoutes.changePassword: (context) => ChangePassword(),
          AppRoutes.sessionManagement: (context) => SessionManagement(),
        },
      ),
    );
  }

  @override
  void dispose() {
    _appStateController.close();
    super.dispose();
  }
}
