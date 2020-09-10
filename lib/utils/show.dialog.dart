import 'package:flutter/material.dart';
import 'package:onepay_app/widgets/dialog/DEvalidation.dart';
import 'package:onepay_app/widgets/dialog/loader.dart';
import 'package:onepay_app/widgets/dialog/qrcode.dart';

void showDEValidationDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    transitionDuration: Duration(seconds: 1),
    barrierLabel: MaterialLocalizations.of(context).dialogLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    pageBuilder: (context, _, __) {
      return Scaffold(
        body: DEValidationDialog(),
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
