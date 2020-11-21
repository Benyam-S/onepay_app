import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/custom_icons.dart';

class HistoryTile extends StatefulWidget {
  final History history;
  final User user;

  HistoryTile(this.history, this.user, {Key key}) : super(key: key);

  @override
  _HistoryTileState createState() => _HistoryTileState();
}

class _HistoryTileState extends State<HistoryTile>
    with TickerProviderStateMixin {
  Widget _historyIcon;
  String _historyAmount;
  String _historyMethod;
  String _collapsedHistoryTimeStamp;
  String _collapsedHistoryDesc;
  Color _cardColor;
  Color _unSeenColor = Color.fromRGBO(202, 240, 248, 1);

  Widget _detailsWidget;
  Widget _detail1;
  Widget _detail2;
  Widget _detail3;
  Widget _detail4;
  Widget _detail5;
  Widget _detailAmount;

  bool _collapsed = true;
  AnimationController _collapseAnimationController;
  AnimationController _expandAnimationController;
  Animation _collapseAnimation;
  Animation _expandAnimation;

  void _formatCard() {
    _setCollapsedHistoryState();
    _setExpandedHistoryState();
  }

  void _setExpandedHistoryState() {
    switch (widget.history.method) {
      case MethodTransferQRCodeB:
        Color avatarColor;
        String detail2Title;
        Widget detail2;
        String detail3Title;
        Widget detail3;
        String detail4Title;
        String detail4Text;
        if (_historyMethod == "Sent") {
          avatarColor = Theme.of(context).colorScheme.primary;
          detail2Title = "Created at";
          detail2 = Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                  DateFormat("EEE, MMM d, yyyy").format(widget.history.sentAt)),
              Text(
                DateFormat(" hh:mm aaa").format(widget.history.sentAt),
                style: TextStyle(fontSize: 9),
              ),
            ],
          );
          detail3Title = "Received at";
          detail3 = Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(DateFormat("EEE, MMM d, yyyy")
                  .format(widget.history.receivedAt)),
              Text(
                DateFormat(" hh:mm aaa").format(widget.history.receivedAt),
                style: TextStyle(fontSize: 9),
              ),
            ],
          );
          detail4Title = "Transaction type";
          detail4Text = "QR Code Transfer";

          _detail1 = Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Receiver",
              ),
              Text(widget.history.receiverID.toUpperCase()),
            ],
          );
          _detail5 = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Transaction code",
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(CustomIcons.barcode),
                    Text(widget.history.code),
                  ],
                ),
              ],
            ),
          );
        } else {
          avatarColor = Colors.green;
          detail2Title = "Received at";
          detail2 = Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(DateFormat("EEE, MMM d, yyyy")
                  .format(widget.history.receivedAt)),
              Text(
                DateFormat(" hh:mm aaa").format(widget.history.receivedAt),
                style: TextStyle(fontSize: 9),
              ),
            ],
          );
          detail3Title = "Transaction type";
          detail3 = Text("QR Code Transfer");
          detail4Title = "Code owner";
          detail4Text = widget.history.senderID.toUpperCase();

          _detail1 = Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Sender",
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CustomIcons.barcode),
                  Text(widget.history.code),
                ],
              ),
            ],
          );
          _detail5 = null;
        }

        _detailsWidget = Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: CircleAvatar(
                radius: 5,
                backgroundColor: avatarColor,
              ),
            ),
            Text(_historyMethod),
          ],
        );
        _detail2 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              detail2Title,
            ),
            detail2,
          ],
        );
        _detail3 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              detail3Title,
            ),
            detail3,
          ],
        );
        _detail4 = Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(detail4Title),
              Text(detail4Text),
            ],
          ),
        );
        _detailAmount = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Amount",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _historyAmount + " ETB",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );

        break;
      case MethodTransferOnePayIDB:
        Color avatarColor;
        String detail1Title;
        String detail1Text;
        if (_historyMethod == "Sent") {
          avatarColor = Theme.of(context).colorScheme.primary;
          detail1Title = "Receiver";
          detail1Text = widget.history.receiverID.toUpperCase();
        } else {
          avatarColor = Colors.green;
          detail1Title = "Sender";
          detail1Text = widget.history.senderID.toUpperCase();
        }

        _detailsWidget = Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: CircleAvatar(
                radius: 5,
                backgroundColor: avatarColor,
              ),
            ),
            Text(_historyMethod),
          ],
        );
        _detail1 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              detail1Title,
            ),
            Text(detail1Text),
          ],
        );
        _detail2 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Received at"),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(DateFormat("EEE, MMM d, yyyy")
                    .format(widget.history.receivedAt)),
                Text(
                  DateFormat(" hh:mm aaa").format(widget.history.receivedAt),
                  style: TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        );
        _detail3 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Transaction type",
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(CustomIcons.onepay_logo),
                Text(" ID Transfer"),
              ],
            ),
          ],
        );
        _detail4 = null;
        _detail5 = null;
        _detailAmount = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Amount",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _historyAmount + " ETB",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );

        break;
      case MethodPaymentQRCodeB:
        bool rotate;
        if (widget.history.senderID == widget.user.userID) {
          rotate = true;

          _detail1 = Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Paid by",
              ),
              Text(widget.history.receiverID.toUpperCase()),
            ],
          );
          _detail4 = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Transaction code",
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(CustomIcons.barcode),
                    Text(widget.history.code),
                  ],
                ),
              ],
            ),
          );
        } else {
          rotate = false;

          _detail1 = Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Paid to",
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CustomIcons.barcode),
                  Text(widget.history.code),
                ],
              ),
            ],
          );
          _detail4 = Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Code owner"),
                Text(widget.history.senderID.toUpperCase()),
              ],
            ),
          );
        }

        _detailsWidget = Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Transform.rotate(
                angle: rotate ? pi : 0,
                child: Icon(
                  CustomIcons.left_arrow,
                  color: Colors.orange,
                  size: 10,
                ),
              ),
            ),
            Text(_historyMethod),
          ],
        );
        _detail2 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Paid at"),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(DateFormat("EEE, MMM d, yyyy")
                    .format(widget.history.receivedAt)),
                Text(
                  DateFormat(" hh:mm aaa").format(widget.history.receivedAt),
                  style: TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        );
        _detail3 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Transaction type"),
            Text("Payment"),
          ],
        );
        _detail5 = null;
        _detailAmount = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Amount",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _historyAmount + " ETB",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );

        break;
      case MethodWithdrawnB:
        _detailsWidget = Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Transform.rotate(
                angle: pi,
                child: Icon(
                  CustomIcons.up_arrow,
                  color: Colors.redAccent,
                  size: 10,
                ),
              ),
            ),
            Text(_historyMethod),
          ],
        );
        _detail1 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Withdrawn to",
            ),
            Text("(External) " + widget.history.receiverID.toUpperCase()),
          ],
        );
        _detail2 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Withdrawn at",
            ),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(DateFormat("EEE, MMM d, yyyy")
                    .format(widget.history.receivedAt)),
                Text(
                  DateFormat(" hh:mm aaa").format(widget.history.receivedAt),
                  style: TextStyle(fontSize: 9),
                ),
              ],
            )
          ],
        );
        _detail3 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Transaction type"),
            Text("Withdraw"),
          ],
        );
        _detail4 = null;
        _detail5 = null;
        _detailAmount = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Amount",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _historyAmount + " ETB",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
        break;
      case MethodRechargedB:
        _detailsWidget = Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                CustomIcons.up_arrow,
                color: Colors.greenAccent,
                size: 10,
              ),
            ),
            Text(_historyMethod),
          ],
        );
        _detail1 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Recharged from",
            ),
            Text("(External) " + widget.history.senderID.toUpperCase()),
          ],
        );
        _detail2 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Recharged at",
            ),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  DateFormat("EEE, MMM d, yyyy")
                      .format(widget.history.receivedAt),
                ),
                Text(
                  DateFormat(" hh:mm aaa").format(widget.history.receivedAt),
                  style: TextStyle(fontSize: 9),
                ),
              ],
            )
          ],
        );
        _detail3 = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Transaction type"),
            Text("Recharge"),
          ],
        );
        _detail4 = null;
        _detail5 = null;
        _detailAmount = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Amount",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _historyAmount + " ETB",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
        break;
    }
  }

  void _setCollapsedHistoryState() {
    switch (widget.history.method) {
      case MethodTransferQRCodeB:
        if (widget.history.senderID == widget.user.userID) {
          _historyMethod = "Sent";
          _historyIcon = CircleAvatar(
            radius: 5,
            backgroundColor: Theme.of(context).colorScheme.primary,
          );
          // The main idea of send to be received so it crucial to know the received time
          _cardColor = widget.history.senderSeen ? Colors.white : _unSeenColor;
        } else {
          _historyMethod = "Received";
          _historyIcon = CircleAvatar(
            radius: 5,
            backgroundColor: Colors.green,
          );

          _cardColor =
              widget.history.receiverSeen ? Colors.white : _unSeenColor;
        }
        _collapsedHistoryTimeStamp =
            DateFormat('yyyy-MM-dd').format(widget.history.receivedAt);
        _collapsedHistoryDesc = widget.history.code;
        break;
      case MethodTransferOnePayIDB:
        if (widget.history.senderID == widget.user.userID) {
          _historyMethod = "Sent";
          _historyIcon = CircleAvatar(
            radius: 5,
            backgroundColor: Theme.of(context).colorScheme.primary,
          );

          _collapsedHistoryDesc = widget.history.receiverID.toUpperCase();
          _cardColor = widget.history.senderSeen ? Colors.white : _unSeenColor;
        } else {
          _historyMethod = "Received";
          _historyIcon = CircleAvatar(
            radius: 5,
            backgroundColor: Colors.green,
          );

          _collapsedHistoryDesc = widget.history.senderID.toUpperCase();
          _cardColor =
              widget.history.receiverSeen ? Colors.white : _unSeenColor;
        }
        _collapsedHistoryTimeStamp =
            DateFormat('yyyy-MM-dd').format(widget.history.receivedAt);

        break;
      case MethodPaymentQRCodeB:
        _historyMethod = "Paid";
        if (widget.history.senderID == widget.user.userID) {
          _historyIcon = Transform.rotate(
            angle: pi,
            child: Icon(
              CustomIcons.left_arrow,
              color: Colors.orange,
              size: 10,
            ),
          );

          _cardColor = widget.history.senderSeen ? Colors.white : _unSeenColor;
        } else {
          _historyIcon = Icon(
            CustomIcons.left_arrow,
            color: Colors.orange,
            size: 10,
          );

          _cardColor =
              widget.history.receiverSeen ? Colors.white : _unSeenColor;
        }
        _collapsedHistoryDesc = widget.history.code;
        _collapsedHistoryTimeStamp =
            DateFormat('yyyy-MM-dd').format(widget.history.receivedAt);
        break;
      case MethodWithdrawnB:
        _historyMethod = "Withdrawn";
        _historyIcon = Transform.rotate(
          angle: pi,
          child: Icon(
            CustomIcons.up_arrow,
            size: 10,
            color: Colors.redAccent,
          ),
        );
        _cardColor = widget.history.senderSeen ? Colors.white : _unSeenColor;

        _collapsedHistoryDesc = "EX-" + widget.history.receiverID;
        _collapsedHistoryTimeStamp =
            DateFormat('yyyy-MM-dd').format(widget.history.receivedAt);
        break;
      case MethodRechargedB:
        _historyMethod = "Recharged";
        _historyIcon = Icon(
          CustomIcons.up_arrow,
          size: 10,
          color: Colors.greenAccent,
        );
        _collapsedHistoryDesc = "EX-" + widget.history.senderID;
        _collapsedHistoryTimeStamp =
            DateFormat('yyyy-MM-dd').format(widget.history.receivedAt);

        _cardColor = widget.history.receiverSeen ? Colors.white : _unSeenColor;
        break;
    }

    _historyAmount =
        CurrencyInputFormatter.toCurrency(widget.history.amount.toString());
  }

  void _preformAnimation() {
    if (_collapsed) {
      _collapseAnimationController.forward();
      _expandAnimationController.reverse();
    } else {
      _collapseAnimationController.reverse();
      _expandAnimationController.forward();
    }
  }

  @override
  void initState() {
    super.initState();

    _collapseAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _expandAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));

    _collapseAnimation = CurvedAnimation(
        parent: _collapseAnimationController, curve: Curves.fastOutSlowIn);

    _expandAnimation = CurvedAnimation(
        parent: _expandAnimationController, curve: Curves.fastOutSlowIn);

    _preformAnimation();
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    _collapseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _formatCard();

    return GestureDetector(
      onTap: () {
        _collapsed = !_collapsed;
        _preformAnimation();

        this.setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.1))),
          color: _cardColor,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
          child: Column(
            children: [
              FadeTransition(
                opacity: _collapseAnimation,
                child: Visibility(
                  visible: _collapsed,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _collapsedHistoryTimeStamp,
                        style:
                            TextStyle(color: Theme.of(context).iconTheme.color),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _historyIcon,
                              SizedBox(
                                width: 5,
                              ),
                              Text(_historyMethod)
                            ],
                          ),
                          Text("Amount"),
                        ],
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_collapsedHistoryDesc),
                          Text(
                            _historyAmount + " ETB",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              FadeTransition(
                opacity: _expandAnimation,
                child: Visibility(
                  visible: !_collapsed,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Details",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _detailsWidget,
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 3, bottom: 5),
                        decoration:
                            BoxDecoration(border: Border(top: BorderSide())),
                      ),
                      _detail1,
                      SizedBox(
                        height: 5,
                      ),
                      _detail2,
                      SizedBox(
                        height: 5,
                      ),
                      _detail3,
                      SizedBox(
                        height: 5,
                      ),
                      _detail4 ?? SizedBox(),
                      _detail5 ?? SizedBox(),
                      _detailAmount,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
