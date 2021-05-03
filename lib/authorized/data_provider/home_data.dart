import 'package:http/http.dart' as http;
import 'package:onepay_app/models/access.token.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationDataProvider {
  Future<http.Response> getAccessTokenFromNetwork(
      String identifier, String password) async {
    var requester = HttpRequester(path: "/oauth/login/app.json");

    var response =
        await http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'identifier': identifier,
      'password': password,
    }).timeout(Duration(minutes: 1));

    return response;
  }

  Future<void> setLocalAccessToken(AccessToken accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("api_key", accessToken?.apiKey);
    prefs.setString("access_token", accessToken?.accessToken);
    prefs.setString("type", accessToken?.type);
  }

  Future<void> setLoggedIn(bool value) async {
    // There is a chance in which the value can be null
    if (value == null) return;

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("logged_in", value);
  }

  Future<http.Response> verifyLoginOTP(String nonce, String otp) async {
    var requester = HttpRequester(path: "/oauth/login/app/verify.json");

    return http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'nonce': nonce,
      'otp': otp,
    });
  }

  Future<http.Response> resendOTP(String nonce) async {
    var requester = HttpRequester(path: "/oauth/resend");

    return http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'message_id': MessageIDPrefix + nonce,
    });
  }

  Future<http.Response> requestPasswordReset(
      String method, String identifier) async {
    var requester = HttpRequester(path: "/user/password/rest/init.json");
    var response =
        await http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'method': method,
      'identifier': identifier,
    });

    return response;
  }
}
