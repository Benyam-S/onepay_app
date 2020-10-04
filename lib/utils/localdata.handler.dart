import 'dart:convert';

import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/models/user.dart';
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
  List<dynamic> jsonList = json.decode(jsonLinkedAccounts);
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
