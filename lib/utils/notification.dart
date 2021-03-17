import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/notification.history.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/currency.formatter.dart';

Future<void> showNotification(BuildContext context, int id, String channelID,
    String channelName, String title, String desc,
    {String playLoad}) async {
  var styleInformation = BigTextStyleInformation('', htmlFormatContent: true);

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(channelID, channelName, '',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
          color: Theme.of(context).colorScheme.primary,
          styleInformation: styleInformation);

  NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  OnePay.of(context)
      .flutterLocalNotificationsPlugin
      .show(id, title, desc, platformChannelSpecifics, payload: playLoad);
}

NotificationHistory makeHistoryNotification(History history, User user) {
  NotificationHistory notification = NotificationHistory();

  if (history == null || user == null) {
    return null;
  }

  switch (history.method) {
    case MethodTransferQRCodeB:
      if (history.senderID == user.userID) {
        notification.title = "History Alert";
        notification.description =
            "Money token with the code - <span style='color: black;'>"
            "${history.code}</span> has been claimed by OnePay account ${history.receiverID}.";
        return notification;
      }

      break;
    case MethodTransferOnePayIDB:
      if (history.senderID != user.userID) {
        notification.title = "History Alert";
        notification.description =
            "You have been credited with <span style='color: black;'>"
            "${CurrencyInputFormatter.toCurrency(history.amount.toString())} ETB</span>"
            " from OnePay account ${history.senderID}.";
        return notification;
      }

      break;
    case MethodPaymentQRCodeB:
      if (history.senderID == user.userID) {
        notification.title = "History Alert";
        notification.description =
            "You have been payed of an amount <span style='color: black;'>"
            "${CurrencyInputFormatter.toCurrency(history.amount.toString())} ETB</span>"
            " from OnePay account ${history.receiverID}.";
        return notification;
      }

      break;
  }

  return null;
}
