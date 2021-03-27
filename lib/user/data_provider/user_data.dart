import 'package:http/http.dart' as http;
import 'package:onepay_app/utils/request.maker.dart';

class UserDataProvider {
  Future<http.Response> signUpInit(String firstName, String lastName,
      String email, String phoneNumber) async {
    var requester = HttpRequester(path: "/oauth/user/register/init");

    var response =
        await http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
    });

    return response;
  }

  Future<http.Response> signUpVerify(String nonce, String otp) async {
    var requester = HttpRequester(path: "/oauth/user/register/verify");

    var response =
        await http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'nonce': nonce,
      'otp': otp,
    });

    return response;
  }

  Future<http.Response> signUpFinish(
      String newPassword, String verifyPassword, nonce) async {
    var requester = HttpRequester(path: "/oauth/user/register/finish.json");

    var response =
        await http.post(requester.requestURL, headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: <String, String>{
      'password': newPassword,
      'vPassword': verifyPassword,
      'nonce': nonce,
    });

    return response;
  }
}
