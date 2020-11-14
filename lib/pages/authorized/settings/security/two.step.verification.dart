import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/user.preference.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';

Future<bool> onChangeTwoStepVerification(
    BuildContext context, bool value) async {
  var requester = HttpRequester(path: "/oauth/user/profile/preference");
  try {
    var response = await requester.put(context, {
      'type': 'two_step_verification',
      'value': value.toString(),
    });

    if (!isResponseAuthorized(context, response)) {
      return !value;
    }

    if (response.statusCode == HttpStatus.ok) {
      UserPreference userPreference = UserPreference(null, value);
      OnePay.of(context).appStateController.add(userPreference);
      setLocalUserPreference(userPreference);

      // Since the idea is for changing the value of the switch
      return value;
    } else {
      return !value;
    }
  } on SocketException {
    showUnableToConnectError(context);
  } on AccessTokenNotFoundException {
    logout(context);
  } catch (e) {
    showServerError(context, SomethingWentWrongError);
  }

  return !value;
}
