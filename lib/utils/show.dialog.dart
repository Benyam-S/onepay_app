import 'package:flutter/material.dart';
import 'package:onepay_app/models/linked.account.dart';
import 'package:onepay_app/models/money.token.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/widgets/dialog/DEvalidation.dart';
import 'package:onepay_app/widgets/dialog/amount.verification.dart';
import 'package:onepay_app/widgets/dialog/delete.account.dart';
import 'package:onepay_app/widgets/dialog/linked.account.remove.dart';
import 'package:onepay_app/widgets/dialog/loader.dart';
import 'package:onepay_app/widgets/dialog/logout.dart';
import 'package:onepay_app/widgets/dialog/money.token.dart';
import 'package:onepay_app/widgets/dialog/password.authorization.dart';
import 'package:onepay_app/widgets/dialog/qrcode.dart';
import 'package:onepay_app/widgets/dialog/receiver.verification.dart';
import 'package:onepay_app/widgets/dialog/success.dart';

void showDEValidationDialog(BuildContext context, Function currentCallback) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    transitionDuration: Duration(seconds: 1),
    barrierLabel: MaterialLocalizations.of(context).dialogLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    pageBuilder: (context, _, __) {
      return Scaffold(
        body: DEValidationDialog(currentCallback),
        backgroundColor: Colors.transparent,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ).drive(Tween<Offset>(
          begin: Offset(0, -1.0),
          end: Offset.zero,
        )),
        child: child,
      );
    },
  );
}

void showPasswordAuthorizationDialog(
    BuildContext context, Function currentCallback) {
  showDialog(
    context: context,
    barrierDismissible: false,
    child: PasswordAuthorizationDialog(currentCallback),
  );
}

void showLoaderDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    child: WillPopScope(
      child: LoaderDialog(),
      onWillPop: () {},
    ),
  );
}

void showQrCodeDialog(BuildContext context, String code, String type) {
  showDialog(
    context: context,
    barrierDismissible: false,
    // barrierColor: Colors.black.withOpacity(0.5),
    child: type == "send"
        ? QrCodeDialog.forSend(code)
        : QrCodeDialog.forPayment(code),
  );
}

void showReceiverVerificationDialog(
    BuildContext context, String amount, User user, Function callback) {
  showDialog(
    context: context,
    barrierDismissible: false,
    child: ReceiverVerificationDialog(amount, user, callback),
  );
}

void showAmountVerificationDialog(
    BuildContext context, String amount, String method, Function callback) {
  showDialog(
    context: context,
    barrierDismissible: false,
    child: AmountVerificationDialog(amount, method, callback),
  );
}

void showSuccessDialog(BuildContext context, String successMsg) {
  showDialog(
    context: context,
    barrierDismissible: true,
    child: SuccessDialog(successMsg),
  );
}

void showMoneyTokenDialog(
    BuildContext context, MoneyToken moneyToken, Function removeMoneyToken) {
  showDialog(
    context: context,
    child: MoneyTokenDialog(context, moneyToken, removeMoneyToken),
  );
}

void showRemoveLinkedAccountDialog(
    BuildContext context, LinkedAccount linkedAccount, Function callback) {
  showDialog(
    context: context,
    barrierDismissible: false,
    child: RemoveLinkedAccountDialog(linkedAccount, callback),
  );
}

void showLogOutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    child: LogoutDialog(),
  );
}

void showDeleteAccountDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).dialogLabel,
    pageBuilder: (_, __, ___) {
      return Scaffold(
        body: DeleteUserAccountDialog(context),
        backgroundColor: Colors.transparent,
      );
    },
  );
}
