import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/account.provider.dart';
import 'package:onepay_app/models/app.meta.dart';
import 'package:onepay_app/models/currency.rate.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/models/user.preference.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------- Local Access Token Management ----------------------------

Future<AccessToken> getLocalAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString("api_key");
  final accessToken = prefs.getString("access_token");
  final type = prefs.getString("type");

  if (apiKey == null || accessToken == null) {
    return null;
  }

  return AccessToken(accessToken, apiKey, type);
}

Future<void> setLocalAccessToken(AccessToken accessToken) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString("api_key", accessToken?.apiKey);
  prefs.setString("access_token", accessToken?.accessToken);
  prefs.setString("type", accessToken?.type);
}

// ---------------------------- Login Management ----------------------------

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool("logged_in") ?? false;

  // Since we need the access token to perform an api call we need to make sure the access token is different from null
  if (isLoggedIn && null != await getLocalAccessToken()) {
    return true;
  }

  return false;
}

Future<void> setLoggedIn(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool("logged_in", value);
}

// ---------------------------- Local User Profile Management ----------------------------

Future<User> getLocalUserProfile() async {
  final prefs = await SharedPreferences.getInstance();

  final userID = prefs.getString("user_id");
  final firstName = prefs.getString("first_name");
  final lastName = prefs.getString("last_name");
  final email = prefs.getString("email");
  final phoneNumber = prefs.getString("phone_number");
  final profilePic = prefs.getString("profile_pic");
  final createdAtS = prefs.getString("created_at");
  final updatedAtS = prefs.getString("updated_at");

  if (userID == null) {
    return null;
  }

  DateTime createdAt = DateTime.parse(createdAtS);
  DateTime updatedAt = DateTime.parse(updatedAtS);

  return User(userID, firstName, lastName, email, phoneNumber, profilePic,
      createdAt, updatedAt);
}

Future<void> setLocalUserProfile(User user) async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setString("user_id", user?.userID);
  prefs.setString("first_name", user?.firstName);
  prefs.setString("last_name", user?.lastName);
  prefs.setString("email", user?.email);
  prefs.setString("phone_number", user?.phoneNumber);
  prefs.setString("profile_pic", user?.profilePic);
  prefs.setString("created_at", user?.createdAt?.toIso8601String());
  prefs.setString("updated_at", user?.updatedAt?.toIso8601String());
}

// ---------------------------- Local User Preference Management ----------------------------

Future<UserPreference> getLocalUserPreference() async {
  final prefs = await SharedPreferences.getInstance();

  final userID = prefs.getString("user_id");
  final twoStepVerification = prefs.getBool("two_step_verification");

  return UserPreference(userID, twoStepVerification);
}

Future<void> setLocalUserPreference(UserPreference userPreference) async {
  final prefs = await SharedPreferences.getInstance();

  // Only need to set two_step_verification value
  prefs.setBool("two_step_verification", userPreference?.twoStepVerification);
}

// ---------------------------- Local User Wallet Management ----------------------------

Future<Wallet> getLocalUserWallet() async {
  final prefs = await SharedPreferences.getInstance();

  final userID = prefs.getString("wallet_owner_id");
  final amount = prefs.getDouble("wallet_amount");
  final seen = prefs.getBool("wallet_seen");
  final updatedAtS = prefs.getString("wallet_updated_at");

  if (userID == null) {
    return null;
  }
  DateTime updatedAt = DateTime.parse(updatedAtS);

  return Wallet(userID, amount, seen, updatedAt);
}

Future<void> setLocalUserWallet(Wallet wallet) async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setString("wallet_owner_id", wallet?.userID);
  prefs.setDouble("wallet_amount", wallet?.amount);
  prefs.setBool("wallet_seen", wallet?.seen);
  prefs.setString("wallet_updated_at", wallet?.updatedAt?.toIso8601String());
}

Future<void> markLocalUserWallet(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool("wallet_seen", value);
}

// ---------------------------- Local View Bys Management ----------------------------

Future<Map<String, bool>> getLocalViewBys() async {
  final prefs = await SharedPreferences.getInstance();

  final transferSent = prefs.getBool("transfer_sent");
  final transferReceived = prefs.getBool("transfer_received");
  final paymentSent = prefs.getBool("payment_sent");
  final paymentReceived = prefs.getBool("payment_received");
  final withdrawn = prefs.getBool("withdrawn");
  final recharged = prefs.getBool("recharged");

  Map<String, bool> viewBys = {
    "transfer_sent": transferSent ?? true,
    "transfer_received": transferReceived ?? true,
    "payment_sent": paymentSent ?? true,
    "payment_received": paymentReceived ?? true,
    "recharged": recharged ?? true,
    "withdrawn": withdrawn ?? true
  };

  return viewBys;
}

Future<void> setLocalViewBys(Map<String, bool> viewBys) async {
  final prefs = await SharedPreferences.getInstance();

  // Resetting the view by settings
  if (viewBys == null) {
    prefs.setBool("transfer_sent", true);
    prefs.setBool("transfer_received", true);
    prefs.setBool("payment_sent", true);
    prefs.setBool("payment_received", true);
    prefs.setBool("withdrawn", true);
    prefs.setBool("recharged", true);
    return;
  }

  prefs.setBool("transfer_sent", viewBys["transfer_sent"]);
  prefs.setBool("transfer_received", viewBys["transfer_received"]);
  prefs.setBool("payment_sent", viewBys["payment_sent"]);
  prefs.setBool("payment_received", viewBys["payment_received"]);
  prefs.setBool("withdrawn", viewBys["withdrawn"]);
  prefs.setBool("recharged", viewBys["recharged"]);
}

// ---------------------------- Local Linked Account Management ----------------------------

Future<List<LinkedAccount>> getLocalLinkedAccounts() async {
  final prefs = await SharedPreferences.getInstance();

  final jsonLinkedAccounts = prefs.getString("linked_accounts");
  List<dynamic> jsonList =
      jsonLinkedAccounts == null ? [] : json.decode(jsonLinkedAccounts);
  List<LinkedAccount> linkedAccounts = List<LinkedAccount>();

  jsonList.forEach((element) {
    LinkedAccount linkedAccount = LinkedAccount.fromJson(element);
    linkedAccounts.add(linkedAccount);
  });

  return linkedAccounts;
}

Future<void> setLocalLinkedAccounts(String jsonLinkedAccounts) async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setString("linked_accounts", jsonLinkedAccounts);
}

// ---------------------------- Local Account Provider Management ----------------------------

Future<List<AccountProvider>> getLocalAccountProviders() async {
  final prefs = await SharedPreferences.getInstance();

  final jsonAccountProviders = prefs.getString("account_providers");
  List<dynamic> jsonList =
      jsonAccountProviders == null ? [] : json.decode(jsonAccountProviders);
  List<AccountProvider> accountProviders = List<AccountProvider>();

  jsonList.forEach((element) {
    AccountProvider accountProvider = AccountProvider.fromJson(element);
    accountProviders.add(accountProvider);
  });

  return accountProviders;
}

Future<void> setLocalAccountProviders(String jsonAccountProviders) async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setString("account_providers", jsonAccountProviders);
}

// ---------------------------- Local Device Information ----------------------------

// getAppMeta is a function that retrieves that application's meta data
Future<AppMeta> getAppMeta() async {
  AppMeta appMeta;
  String applicationName;
  String applicationVersion;
  String userAgent = "";
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  String readAndroidBuildData(AndroidDeviceInfo build) {
    return '${build.device} Build/${build.id}';
  }

  String readIosDeviceInfo(IosDeviceInfo data) {
    return data.name;
  }

  try {
    await FlutterUserAgent.init();
    if (Platform.isAndroid) {
      var deviceData = readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      userAgent =
          '($deviceData ${(await FlutterUserAgent.getPropertyAsync('systemName'))} '
                  '${(await FlutterUserAgent.getPropertyAsync('systemVersion'))} )' ??
              "";
    } else if (Platform.isIOS) {
      var deviceData = readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      userAgent =
          '($deviceData ${(await FlutterUserAgent.getPropertyAsync('systemName'))}/'
                  '${(await FlutterUserAgent.getPropertyAsync('systemVersion'))} )' ??
              "";
    }

    applicationName = FlutterUserAgent.getProperty('applicationName');
    applicationVersion = FlutterUserAgent.getProperty('applicationVersion');
  } catch (e) {}

  if (applicationName == null || applicationName == "") {
    applicationName = "OnePay Mobile";
  } else {
    applicationName = "$applicationName Mobile";
  }

  if (applicationVersion == null || applicationVersion == "") {
    applicationVersion = "v1.0.0";
  } else {
    applicationVersion = "v$applicationVersion";
  }

  appMeta = AppMeta(applicationName, applicationVersion, userAgent);
  return appMeta;
}

// ---------------------------- Local In App Settings Management ----------------------------

Future<DataSaverState> getLocalDataSaverState() async {
  final prefs = await SharedPreferences.getInstance();

  final dataSaverStateB = prefs.getBool("data_saver_state");
  DataSaverState dataSaverState;

  if (dataSaverStateB == null || !dataSaverStateB) {
    dataSaverState = DataSaverState.Disabled;
  } else {
    dataSaverState = DataSaverState.Enabled;
  }

  return dataSaverState;
}

Future<void> setLocalDataSaverState(DataSaverState dataSaverState) async {
  final prefs = await SharedPreferences.getInstance();

  if (dataSaverState == DataSaverState.Enabled) {
    prefs.setBool("data_saver_state", true);
  } else if (dataSaverState == DataSaverState.Disabled) {
    prefs.setBool("data_saver_state", false);
  } else {
    prefs.setBool("data_saver_state", null);
  }
}

Future<ForegroundNotificationState>
    getLocalForegroundNotificationState() async {
  final prefs = await SharedPreferences.getInstance();

  final foregroundNotificationStateB =
      prefs.getBool("foreground_notification_state");
  ForegroundNotificationState foregroundNotificationState;

  // foreground notification is enabled by default so if the value is null the
  // it has to be set to 'Enabled'.
  if (foregroundNotificationStateB == null || foregroundNotificationStateB) {
    foregroundNotificationState = ForegroundNotificationState.Enabled;
  } else {
    foregroundNotificationState = ForegroundNotificationState.Disabled;
  }

  return foregroundNotificationState;
}

Future<void> setLocalForegroundNotificationState(
    ForegroundNotificationState foregroundNotificationState) async {
  final prefs = await SharedPreferences.getInstance();

  if (foregroundNotificationState == ForegroundNotificationState.Enabled) {
    prefs.setBool("foreground_notification_state", true);
  } else if (foregroundNotificationState ==
      ForegroundNotificationState.Disabled) {
    prefs.setBool("foreground_notification_state", false);
  } else {
    prefs.setBool("foreground_notification_state", null);
  }
}

Future<BackgroundNotificationState>
    getLocalBackgroundNotificationState() async {
  final prefs = await SharedPreferences.getInstance();

  final backgroundNotificationStateB =
      prefs.getBool("background_notification_state");
  BackgroundNotificationState backgroundNotificationState;

  if (backgroundNotificationStateB == null || backgroundNotificationStateB) {
    backgroundNotificationState = BackgroundNotificationState.Enabled;
  } else {
    backgroundNotificationState = BackgroundNotificationState.Disabled;
  }

  return backgroundNotificationState;
}

Future<void> setLocalBackgroundNotificationState(
    BackgroundNotificationState backgroundNotificationState) async {
  final prefs = await SharedPreferences.getInstance();

  if (backgroundNotificationState == BackgroundNotificationState.Enabled) {
    prefs.setBool("background_notification_state", true);
  } else if (backgroundNotificationState ==
      BackgroundNotificationState.Disabled) {
    prefs.setBool("background_notification_state", false);
  } else {
    prefs.setBool("background_notification_state", null);
  }
}

// ---------------------------- Local Currency Rate Management ----------------------------

Future<List<CurrencyRate>> getRecentLocalCurrencyRates() async {
  final prefs = await SharedPreferences.getInstance();

  final jsonData = prefs.getString("currency_rates");
  if (jsonData == null) return [];

  List<dynamic> rates = json.decode(jsonData);
  List<CurrencyRate> currencyRates = List<CurrencyRate>();

  rates.forEach((rate) {
    CurrencyRate currencyRate = CurrencyRate.fromJson(rate);
    currencyRates.add(currencyRate);
  });

  DateTime timeStamp = currencyRates.length > 0
      ? currencyRates[0].dates.last
      : DateTime.fromMicrosecondsSinceEpoch(0);

  // If the stored currency rates are out-dated return empty list
  if (timeStamp.add(Duration(days: 1)).isBefore(DateTime.now())) {
    return [];
  }

  return currencyRates;
}

Future<void> setLocalCurrencyRates(List<CurrencyRate> currencyRates) async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setString("currency_rates", json.encode(currencyRates));
}

// ---------------------------- Local History Management ----------------------------
Future<List<History>> getRecentLocalHistories(
    {SharedPreferences preferences}) async {
  // For reducing redundant preference instantiating
  if (preferences == null) {
    preferences = await SharedPreferences.getInstance();
  }

  final jsonData = preferences.getString("recent_histories");
  if (jsonData == null) return [];

  List<dynamic> historiesMap = json.decode(jsonData);
  List<History> histories = List<History>();

  historiesMap.forEach((element) {
    History history = History.fromJson(element);
    histories.add(history);
  });

  return histories;
}

Future<void> setRecentLocalHistories(List<History> histories,
    {SharedPreferences preferences}) async {
  if (preferences == null) {
    preferences = await SharedPreferences.getInstance();
  }

  List<History> recentHistories =
      await getRecentLocalHistories(preferences: preferences);
  if (recentHistories.length + histories.length > 360) {
    int index = -1;
    recentHistories.removeWhere((history) {
      index++;
      if (index > 360 - (histories.length + 1)) return true;
      return false;
    });
  }

  histories.addAll(recentHistories);
  preferences.setString("recent_histories", json.encode(histories));
}
