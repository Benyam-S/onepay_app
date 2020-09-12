import 'package:flutter/material.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/widgets/dialog/DEvalidation.dart';
import 'package:onepay_app/widgets/dialog/loader.dart';
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

void showSuccessDialog(BuildContext context, String successMsg) {
  showDialog(
    context: context,
    barrierDismissible: true,
    child: SuccessDialog(successMsg),
  );
}
