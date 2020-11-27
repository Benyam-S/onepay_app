import 'dart:convert';
import 'dart:io';

import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recase/recase.dart';

class DeleteUserAccountDialog extends StatefulWidget {
  final BuildContext context;

  DeleteUserAccountDialog(this.context);

  @override
  _DeleteUserAccountDialog createState() => _DeleteUserAccountDialog();
}

class _DeleteUserAccountDialog extends State<DeleteUserAccountDialog> {
  FocusNode _passwordFocusNode;
  TextEditingController _passwordController;
  String _passwordErrorText;
  bool _loading = false;

  void _showGoodByeDialog() {
    showDialog(
      context: widget.context,
      barrierDismissible: false,
      child: WillPopScope(
        onWillPop: () {},
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Icon(
                CustomIcons.waving_hand,
                size: 60,
              ),
              SizedBox(height: 20),
              Text("We are grateful for your time with us.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(widget.context).iconTheme.color)),
              SizedBox(height: 5),
              Text(
                "Sorry, but we have to say good bye!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  color: Theme.of(widget.context).iconTheme.color,
                ),
              ),
              SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );

    Future.delayed(Duration(seconds: 4)).then((_) => logout(widget.context));
  }

  Future<bool> _checkPermission() async {
    if (Theme.of(widget.context).platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  void _downloadClosingStatement(String location) async {
    Navigator.of(widget.context).pop();

    User currentUser =
        OnePay.of(widget.context).currentUser ?? await getLocalUserProfile();
    String fileName =
        (currentUser?.firstName ?? "") + "_" + (currentUser?.lastName ?? "");
    if (fileName.isEmpty) {
      fileName = "OnePay_account_statement.txt";
    } else {
      fileName += "_OnePay_account_statement.txt";
    }

    var isPermissionGranted = await _checkPermission();
    if (isPermissionGranted) {
      await FlutterDownloader.enqueue(
        url: 'http://$Host/api/v1/oauth/user/statement/$location',
        fileName: fileName,
        savedDir: (await DownloadsPathProvider.downloadsDirectory).path,
        showNotification: true,
        openFileFromNotification: true,
      );
    } else {
      showInternalError(widget.context, "storage access denied");
    }

    _showGoodByeDialog();
  }

  void _showStatementDialog(String location) {
    showDialog(
      context: widget.context,
      barrierDismissible: false,
      child: WillPopScope(
        onWillPop: () {},
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Do you wish to download your account closing statement?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(widget.context).iconTheme.color),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CupertinoButton(
                    onPressed: () => _downloadClosingStatement(location),
                    child: Text("Sure", style: TextStyle(fontSize: 14)),
                    minSize: 0,
                    padding: EdgeInsets.zero,
                  ),
                  CupertinoButton(
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontSize: 14),
                    ),
                    minSize: 0,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(widget.context).pop();
                      _showGoodByeDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSuccess(Response response) async {
    Navigator.of(context).pop();

    var jsonData = json.decode(response.body);
    _showStatementDialog(jsonData["Location"]);
  }

  void _onError(Response response) {
    if (response.statusCode == HttpStatus.badRequest) {
      String error = response.body?.trim();
      FocusScope.of(context).requestFocus(_passwordFocusNode);

      switch (error) {
        case TooManyAttemptsErrorB:
          error = TooManyAttemptsError;
          break;
        case InvalidPasswordErrorB:
          error = InvalidPasswordError;
          break;
        case UnDrainedWalletErrorB:
          error = UnDrainedWalletError;
          showInternalError(context, error);
          return;
        case UnClaimedMoneyTokenErrorB:
          error = UnClaimedMoneyTokenError;
          showInternalError(context, error);
          return;
        default:
          showInternalError(context, error);
          return;
      }
      setState(() {
        _passwordErrorText = ReCase(error).sentenceCase;
      });
    } else if (response.statusCode == HttpStatus.internalServerError) {
      showServerError(context, FailedOperationError);
    } else {
      showServerError(context, SomethingWentWrongError);
    }
  }

  Future<void> _makeDeleteUserAccountRequest(String password) async {
    var requester = HttpRequester(path: "/oauth/user.json");
    try {
      Response response =
          await requester.delete(context, {'password': password});

      setState(() {
        _loading = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        await _onSuccess(response);
      } else {
        _onError(response);
      }
    } on SocketException {
      setState(() {
        _loading = false;
      });
      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      setState(() {
        _loading = false;
      });
      showServerError(context, SomethingWentWrongError);
    }
  }

  void _deleteUserAccount() async {
    // Cancelling if loading
    if (_loading) {
      return;
    }

    var password = _passwordController.text;
    if (password.isEmpty) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
      return;
    }

    setState(() {
      _loading = true;
      _passwordErrorText = null;
    });

    await _makeDeleteUserAccountRequest(password);
  }

  @override
  void initState() {
    super.initState();

    _passwordFocusNode = FocusNode();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {},
      child: AlertDialog(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.delete),
            SizedBox(width: 5),
            Text("Delete Account", style: TextStyle(fontFamily: 'Roboto')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Are you sure you want to delete your OnePay account?",
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).errorColor),
            ),
            SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 13,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                      text: 'Warning: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: "deleting your OnePay account is irreversible,"
                        " you may lose any information related to this account permanently. "
                        "Also drain your OnePay wallet and reclaim any money token before proceeding.",
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: TextFormField(
                obscureText: true,
                focusNode: _passwordFocusNode,
                controller: _passwordController,
                decoration: InputDecoration(
                  suffix: _loading
                      ? Container(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))
                      : null,
                  enabled: !_loading,
                  labelText: "Password",
                  errorText: _passwordErrorText,
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                onChanged: (_) => this.setState(() {
                  _passwordErrorText = null;
                }),
                keyboardType: TextInputType.visiblePassword,
              ),
            ),
            SizedBox(height: 35),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CupertinoButton(
                  onPressed: _loading ? null : _deleteUserAccount,
                  child: Text(
                    "Delete",
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).errorColor),
                  ),
                  minSize: 0,
                  padding: EdgeInsets.zero,
                ),
                CupertinoButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: 14),
                  ),
                  minSize: 0,
                  padding: EdgeInsets.zero,
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
