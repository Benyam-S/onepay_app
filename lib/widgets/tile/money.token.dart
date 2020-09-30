import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/money.token.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/formatter.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';

class MoneyTokenTile extends StatefulWidget {
  final MoneyToken moneyToken;
  final Key key;
  final bool isCheckable;
  final bool value;
  final Function onLongPress;
  final Function onCheckboxTap;
  final Function onReclaim;
  final Function remove;
  final Function refresh;

  MoneyTokenTile(this.moneyToken,
      {this.key,
      this.isCheckable,
      this.value,
      this.onLongPress,
      this.onCheckboxTap,
      this.onReclaim,
      this.remove,
      this.refresh})
      : super(key: key);

  @override
  _MoneyTokenTileState createState() => _MoneyTokenTileState();
}

class _MoneyTokenTileState extends State<MoneyTokenTile>
    with SingleTickerProviderStateMixin {
  AnimationController _rotationController;
  bool _isRefreshing = false;
  Color _refreshingColor = Color.fromRGBO(202, 240, 248, 1);

  void _onRefreshSuccess(Response response) {
    List<dynamic> jsonData = json.decode(response.body);
    MoneyToken refreshedMoneyToken = MoneyToken.fromJson(jsonData[0]);
    if (refreshedMoneyToken.code == widget.moneyToken.code) {
      widget.refresh(refreshedMoneyToken);
    }
  }

  void _onRefreshError(Response response) {
    showServerError(context, "Unable to refresh money token");
  }

  Future<void> _makeRefreshMoneyTokenRequest() async {
    if (_isRefreshing) {
      return;
    }

    _startIconRotation();
    setState(() {
      _isRefreshing = true;
    });

    var requester = HttpRequester(path: "/oauth/user/moneytoken/refresh.json");
    try {
      Response response =
          await requester.put(context, {"codes": widget.moneyToken.code});

      _stopIconRotation();
      setState(() {
        _isRefreshing = false;
      });

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onRefreshSuccess(response);
      } else {
        _onRefreshError(response);
      }
    } on AccessTokenNotFoundException {
      setState(() {
        _isRefreshing = false;
      });
      _stopIconRotation();
      logout(context);
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      _stopIconRotation();
    }
  }

  void _startIconRotation() {
    _rotationController.repeat();
  }

  void _stopIconRotation() {
    _rotationController.reset();
  }

  @override
  void initState() {
    super.initState();

    _rotationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String type = "";
    if (widget.moneyToken.method == MethodTransferQRCodeB) {
      type = "S";
    } else if (widget.moneyToken.method == MethodPaymentQRCodeB) {
      type = "P";
    }

    double checkedPadding = widget.isCheckable ? 10 : 20;
    return Card(
      shape: ContinuousRectangleBorder(),
      color: _isRefreshing ? _refreshingColor : Colors.white,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
          child: Row(
            children: [
              SizedBox(
                width: checkedPadding,
              ),
              Visibility(
                visible: widget.isCheckable,
                child: Checkbox(
                  onChanged: _isRefreshing
                      ? null
                      : (value) =>
                          widget.onCheckboxTap(widget.moneyToken.code, value),
                  value: _isRefreshing ? false : widget.value ?? false,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onLongPress: widget.onLongPress,
                  onTap: () => showMoneyTokenDialog(
                      context, widget.moneyToken, widget.remove),
                  child: Container(
                    color: _isRefreshing ? _refreshingColor : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    Icon(
                                      CustomIcons.barcode,
                                      size: 24,
                                    ),
                                    Container(
                                      height: 24,
                                      width: 24,
                                      alignment: Alignment.center,
                                      child: Text(type,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 3),
                                Text(
                                  widget.moneyToken.code,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            Text("Amount"),
                          ],
                        ),
                        SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat("yyyy-MM-dd")
                                  .format(widget.moneyToken.expirationDate),
                              style: TextStyle(
                                  color: Theme.of(context).iconTheme.color),
                            ),
                            Text(
                              CurrencyInputFormatter().toCurrency(
                                      widget.moneyToken.amount.toString()) +
                                  " ETB",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: widget.isCheckable || _isRefreshing,
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: IconButton(
                    icon: RotationTransition(
                      turns: _rotationController,
                      child: Icon(
                        Icons.refresh,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: _makeRefreshMoneyTokenRequest,
                  ),
                ),
              ),
              SizedBox(
                width: checkedPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
