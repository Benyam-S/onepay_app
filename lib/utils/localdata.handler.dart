import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/user.dart';
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
