import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/constants.dart';

import 'package:onepay_app/models/history.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/widgets/tile/history.dart';

class WalletHistory extends StatefulWidget {
  final StreamController<bool> unseenStreamController;

  WalletHistory(this.unseenStreamController);

  @override
  _WalletHistory createState() => _WalletHistory();
}

class _WalletHistory extends State<WalletHistory> {
  User _user;
  List<History> _histories = List<History>();
  int _currentPage = 0;
  int _pageCount = 0;
  bool _isFetching = false;
  bool _unseenFlag = false;
  ScrollController _scrollController;
  Map<String, bool> _viewBys = Map<String, bool>();

  void _checkForUnseenHistories(History history) {
    // If _unseenFlag was set
    if (_unseenFlag) {
      return;
    }

    if (history.senderID == _user.userID && !history.senderSeen) {
      _unseenFlag = true;
    } else if (history.receiverID == _user.userID && !history.receiverSeen) {
      _unseenFlag = true;
    }

    if (_unseenFlag) {
      widget.unseenStreamController.add(true);
    }
  }

  bool _canShowTransfer(History history) {
    if (history.senderID == _user.userID) {
      return _viewBys["transfer_sent"];
    } else if (history.receiverID == _user.userID) {
      return _viewBys["transfer_received"];
    }

    return false;
  }

  bool _canShowPayment(History history) {
    if (history.senderID == _user.userID) {
      return _viewBys["payment_received"];
    } else if (history.receiverID == _user.userID) {
      return _viewBys["payment_sent"];
    }

    return false;
  }

  bool _canShowWithdrawn(History history) {
    return _viewBys["withdrawn"];
  }

  bool _canShowRecharged(History history) {
    return _viewBys["recharged"];
  }

  bool _isEligible(History history) {
    switch (history.method) {
      case MethodTransferQRCodeB:
      case MethodTransferOnePayIDB:
        return _canShowTransfer(history);
      case MethodPaymentQRCodeB:
        return _canShowPayment(history);
      case MethodWithdrawnB:
        return _canShowWithdrawn(history);
      case MethodRechargedB:
        return _canShowRecharged(history);
    }

    return false;
  }

  Widget _listBuilder(BuildContext context, int index) {
    if (_user == null) {
      return null;
    }

    if (_histories.length == index) {
      return SizedBox(height: 15);
    }

    History history = _histories[index];
    ValueKey key = ValueKey(history.id);

    // Checking for unseen
    _checkForUnseenHistories(history);

    return HistoryTile(
      history,
      _user,
      key: key,
    );
  }

  void _getMoreData() {
    var currentPage = _currentPage + 1;
    if (currentPage >= _pageCount || _isFetching) {
      return;
    }

    _currentPage++;
    _makeRequest().then((successful) {
      if (!successful) _currentPage--;
    });
  }

  Future<void> _refresh() async {
    var prev = _currentPage;
    _currentPage = 0;
    await _makeRequest();
    _currentPage = prev;
    return;
  }

  void _filterAndAdd(List<History> newHistories) {
    List<History> filteredHistories = List<History>();
    newHistories.forEach((newHistory) {
      bool addFlag = true;
      _histories.forEach((history) {
        if (history.id == newHistory.id) {
          addFlag = false;
        }
      });
      if (addFlag) filteredHistories.add(newHistory);
    });

    _histories.addAll(filteredHistories);
    // Ordering in reverse order
    _histories.sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> _onSuccess(Response response) async {
    var jsonData = json.decode(response.body);
    List<dynamic> result = jsonData["Result"];
    _pageCount = jsonData["PageCount"] as int;

    List<History> histories = result.map((jsonHistory) {
      var history = History.fromJson(jsonHistory);
      return history;
    }).toList();

    OnePay.of(context).appStateController.add(histories);
    List<History> eligibleHistories = List<History>();
    histories.forEach((history) {
      if (_isEligible(history)) eligibleHistories.add(history);
    });

    _filterAndAdd(eligibleHistories);

    setState(() {});
  }

  // The Future<bool> is used to determine whether the request was successful or not
  Future<bool> _makeRequest() async {
    // Stop if there is another request being processed
    if (_isFetching) return true;

    var requester =
        HttpRequester(path: "/oauth/user/history.json?page=$_currentPage");

    try {
      _isFetching = true;
      Response response = await requester.get(context);

      if (response.statusCode == HttpStatus.ok) {
        await _onSuccess(response);
        _isFetching = false;
        return true;
      }

      _isFetching = false;
    } on AccessTokenNotFoundException {
      _isFetching = false;
      logout(context);
    } catch (e) {
      _isFetching = false;
      //  do nothing
    }

    return false;
  }

  Future<void> _initUser() async {
    _user = OnePay.of(context).currentUser;
    if (_user == null) {
      getLocalUserProfile().then((value) {
        setState(() {
          _user = value;
        });
      });
    }
  }

  Future<void> _initViewBys() async {
    Map<String, bool> viewBys = await getLocalViewBys();

    setState(() {
      _viewBys = {
        "transfer_sent": viewBys["transfer_sent"],
        "transfer_received": viewBys["transfer_received"],
        "payment_sent": viewBys["payment_sent"],
        "payment_received": viewBys["payment_received"],
        "recharged": viewBys["recharged"],
        "withdrawn": viewBys["withdrawn"]
      };
    });
  }

  void _connectivityChecker() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        _refresh();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _connectivityChecker();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initUser();
    _initViewBys().then((_) {
      List<History> eligibleHistories = List<History>();
      OnePay.of(context).histories.forEach((history) {
        if (_isEligible(history)) eligibleHistories.add(history);
      });

      _filterAndAdd(eligibleHistories);
      _makeRequest();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.position.maxScrollExtent == 0) {
        _getMoreData();
      }
    });

    return StreamBuilder(
        stream: OnePay.of(context).historyStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<History> histories = snapshot.data;

            List<History> eligibleHistories = List<History>();
            histories.forEach((history) {
              if (_isEligible(history)) eligibleHistories.add(history);
            });

            _filterAndAdd(eligibleHistories);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "History",
                        style: TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                      ),
                      PopupMenuButton(
                        child: Icon(Icons.more_vert),
                        padding: EdgeInsets.zero,
                        tooltip: "View By",
                        onSelected: (value) {
                          switch (value) {
                            case "transfer_sent":
                              _viewBys["transfer_sent"] =
                                  !_viewBys["transfer_sent"];
                              break;
                            case "transfer_received":
                              _viewBys["transfer_received"] =
                                  !_viewBys["transfer_received"];
                              break;
                            case "payment_sent":
                              _viewBys["payment_sent"] =
                                  !_viewBys["payment_sent"];
                              break;
                            case "payment_received":
                              _viewBys["payment_received"] =
                                  !_viewBys["payment_received"];
                              break;
                            case "withdrawn":
                              _viewBys["withdrawn"] = !_viewBys["withdrawn"];
                              break;
                            case "recharged":
                              _viewBys["recharged"] = !_viewBys["recharged"];
                              break;
                          }

                          void reOrder() async {
                            _histories = List<History>();
                            OnePay.of(context).histories.forEach((history) {
                              if (_isEligible(history)) _histories.add(history);
                            });
                          }

                          reOrder();
                          setLocalViewBys(_viewBys);
                          setState(() {});
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            CheckedPopupMenuItem(
                              child: Text("Sent"),
                              value: "transfer_sent",
                              checked: _viewBys["transfer_sent"],
                            ),
                            CheckedPopupMenuItem(
                              child: Text("Received"),
                              value: "transfer_received",
                              checked: _viewBys["transfer_received"],
                            ),
                            CheckedPopupMenuItem(
                              child: Text("Payment Sent"),
                              value: "payment_sent",
                              checked: _viewBys["payment_sent"],
                            ),
                            CheckedPopupMenuItem(
                              child: Text("Payment Received"),
                              value: "payment_received",
                              checked: _viewBys["payment_received"],
                            ),
                            CheckedPopupMenuItem(
                              child: Text("Withdrawn"),
                              value: "withdrawn",
                              checked: _viewBys["withdrawn"],
                            ),
                            CheckedPopupMenuItem(
                              child: Text("Recharged"),
                              value: "recharged",
                              checked: _viewBys["recharged"],
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _histories.length == 0
                        ? Stack(
                            children: [
                              ListView(), // This ListView is used for showing the refreshIndicator
                              SizedBox(
                                height: 0,
                                width: 0,
                                child: ListView(
                                  controller: _scrollController,
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(CustomIcons.box, size: 80),
                                    SizedBox(height: 10),
                                    Text(
                                      "Nothing to show yet!",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .iconTheme
                                              .color),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            key: PageStorageKey(0),
                            controller: _scrollController,
                            itemCount: _histories.length + 1,
                            itemBuilder: _listBuilder,
                          ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
