import 'package:onepay_app/models/response/access.token.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  prefs.setString("api_key", accessToken.apiKey);
  prefs.setString("access_token", accessToken.accessToken);
  prefs.setString("type", accessToken.type);
}

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool("logged_in") ?? false;

  // Since we need the access token to perform an api call we need to make sure the access token is different from null
  if (isLoggedIn && null != await getLocalAccessToken()) {
    return true;
  }

  return false;
}

Future<void> setLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool("logged_in", true);
}
