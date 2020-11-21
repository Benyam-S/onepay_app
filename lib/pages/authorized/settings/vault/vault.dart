import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/models/constants.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/money.token.dart';
import 'package:onepay_app/utils/currency.formatter.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/tile/money.token.dart';

class MoneyVault extends StatefulWidget {
  _MoneyVault createState() => _MoneyVault();
}

class _MoneyVault extends State<MoneyVault> {
  ScrollController _scrollController;
  bool _isCheckable = false;
  List<MoneyToken> _moneyTokenList = List<MoneyToken>();
  Map<String, bool> _checkList = Map<String, bool>();
  bool _isAllSelected = false;
  double _reclaimAmount = 0;
  int _selectedCount = 0;
  GlobalKey _globalKey = GlobalKey();
  Size _moneyTokenTileSize;

  void _filterAndAdd(MoneyToken moneyToken) {
    bool addFlag = true;
    _moneyTokenList.forEach((filteredMoneyToken) {
      if (filteredMoneyToken.code == moneyToken.code) {
        addFlag = false;
        return;
      }
    });

    if (addFlag) {
      _moneyTokenList.add(moneyToken);
    }
  }

  void _deleteMoneyToken(MoneyToken moneyToken) {
    setState(() {
      _checkList.remove(moneyToken.code);
      _moneyTokenList.removeWhere((deleteMoneyToken) {
        if (deleteMoneyToken.code == moneyToken.code) return true;
        return false;
      });
    });
  }

  void _refreshMoneyToken(MoneyToken moneyToken) {
    setState(() {
      int _refreshedMoneyTokenIndex;
      for (var i = 0; i < _moneyTokenList.length; i++) {
        if (_moneyTokenList[i].code == moneyToken.code) {
          _refreshedMoneyTokenIndex = i;
          break;
        }
      }

      if (_refreshedMoneyTokenIndex != null)
        _moneyTokenList[_refreshedMoneyTokenIndex] = moneyToken;
    });
  }

  String _getSelectedCodes() {
    String codes = "";
    _checkList.forEach((key, value) {
      if (value) {
        codes += key + " ";
      }
    });

    return codes;
  }

  List<MoneyToken> _getSelectedMoneyTokens() {
    List<MoneyToken> selected = List<MoneyToken>();
    _moneyTokenList.forEach((moneyToken) {
      if (_checkList[moneyToken.code]) {
        selected.add(moneyToken);
      }
    });

    return selected;
  }

  Future<void> _handleResponse(
      BuildContext context,
      Future<Response> Function() requester,
      Function(Response response) onSuccess,
      Function(Response response) onError) async {
    try {
      var response = await requester();

      // Removing loadingDialog
      Navigator.of(context).pop();

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        onSuccess(response);
      } else {
        onError(response);
      }
    } on SocketException {
      // Removing loadingDialog
      Navigator.of(context).pop();

      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      // Removing loadingDialog
      Navigator.of(context).pop();

      showServerError(context, SomethingWentWrongError);
    }
  }

  /* ----------------------------------- REMOVE MONEY TOKENS ----------------------------------- */

  void _onRemoveSelectedSuccess(Response response) {
    showSuccessDialog(context,
        "You have successfully removed $_selectedCount payment token${_selectedCount > 1 ? "s" : ""}.");
    _getSelectedMoneyTokens().forEach((moneyToken) {
      _deleteMoneyToken(moneyToken);
    });
    _restCheckList();
  }

  void _onRemoveSelectedError(Response response) {
    if (response.statusCode == HttpStatus.conflict) {
      Map<String, dynamic> jsonData = json.decode(response.body);

      int removedCount = 0;

      _getSelectedMoneyTokens().forEach((moneyToken) {
        bool claimedFlag = true;
        jsonData.forEach((key, value) {
          if (moneyToken.code == key) {
            claimedFlag = false;
            return;
          }
        });

        if (claimedFlag) {
          removedCount++;
          _deleteMoneyToken(moneyToken);
        }
      });

      _restCheckList();

      showDialog(
        context: context,
        barrierDismissible: true,
        child: AlertDialog(
          content: Text(
              "Unable to fully remove the selected payment money tokens! Out of the selected $_selectedCount "
              "payment money token${_selectedCount > 1 ? "s" : ""} "
              "$removedCount has been removed."),
          actions: [
            CupertinoButton(
              child: Text("Cancel",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  )),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }

  Future<Response> _makeRemoveSelectedRequest() {
    var requester = HttpRequester(path: "/oauth/user/moneytoken/remove.json");
    return requester.post(context, {"codes": _getSelectedCodes()});
  }

  Future<void> _removeSelected(BuildContext context) async {
    Navigator.pop(context);
    showLoaderDialog(context);
    await _handleResponse(context, _makeRemoveSelectedRequest,
        _onRemoveSelectedSuccess, _onRemoveSelectedError);
  }

  void _onRemoveSelectedTap(BuildContext context) {
    if (_selectedCount <= 0) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      child: AlertDialog(
        content: Text(
            "Do you wish to remove the selected $_selectedCount payment money token${_selectedCount > 1 ? "s" : ""}."),
        actions: [
          CupertinoButton(
            child: Text("Ok",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                )),
            onPressed: () => _removeSelected(context),
          ),
          CupertinoButton(
            child: Text("Cancel",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                )),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  /* ----------------------------------- REFRESH MONEY TOKENS ----------------------------------- */

  void _onRefreshSelectedSuccess(Response response) {
    List<dynamic> jsonData = json.decode(response.body);
    jsonData.forEach((element) {
      MoneyToken refreshedMoneyToken = MoneyToken.fromJson(element);
      _refreshMoneyToken(refreshedMoneyToken);
    });

    _restCheckList();
  }

  void _onRefreshSelectedError(Response response) {
    if (response.statusCode == HttpStatus.conflict) {
      var jsonData = json.decode(response.body);
      List<dynamic> refreshJsonData = jsonData["Refreshed"];

      refreshJsonData.forEach((element) {
        MoneyToken refreshedMoneyToken = MoneyToken.fromJson(element);
        _refreshMoneyToken(refreshedMoneyToken);
      });

      _restCheckList();
    }
  }

  Future<Response> _makeRefreshSelectedRequest() {
    var requester = HttpRequester(path: "/oauth/user/moneytoken/refresh.json");
    return requester.put(context, {"codes": _getSelectedCodes()});
  }

  Future<void> _refreshSelected(BuildContext context) async {
    showLoaderDialog(context);
    await _handleResponse(context, _makeRefreshSelectedRequest,
        _onRefreshSelectedSuccess, _onRefreshSelectedError);
  }

  void _onRefreshSelectedTap(BuildContext context) {
    if (_selectedCount <= 0) {
      return;
    }

    _refreshSelected(context);
  }

  /* ----------------------------------- RECLAIM MONEY TOKENS ----------------------------------- */

  void _onReclaimSelectedSuccess(Response response) {
    showSuccessDialog(context,
        "You have successfully reclaimed ${CurrencyInputFormatter.toCurrency(_reclaimAmount.toString())} ETB.");
    _getSelectedMoneyTokens().forEach((moneyToken) {
      _deleteMoneyToken(moneyToken);
    });
    _restCheckList();
  }

  void _onReclaimSelectedError(Response response) {
    if (response.statusCode == HttpStatus.conflict) {
      Map<String, dynamic> jsonData = json.decode(response.body);

      int claimedCount = 0;
      double reclaimedAmount = 0;
      double unclaimedAmount = 0;

      _getSelectedMoneyTokens().forEach((moneyToken) {
        bool claimedFlag = true;
        jsonData.forEach((key, value) {
          if (moneyToken.code == key) {
            claimedFlag = false;
            unclaimedAmount += moneyToken.amount;
            return;
          }
        });

        if (claimedFlag) {
          claimedCount++;
          reclaimedAmount += moneyToken.amount;
          _deleteMoneyToken(moneyToken);
        }
      });

      _restCheckList();

      showDialog(
        context: context,
        barrierDismissible: true,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Unable to fully reclaim the selected transfer money tokens! Out of the selected $_selectedCount "
                  "transfer money token${_selectedCount > 1 ? "s" : ""} "
                  "$claimedCount has been reclaimed."),
              SizedBox(height: 15),
              Text(
                  "Reclaimed amount: ${CurrencyInputFormatter.toCurrency(reclaimedAmount.toString())} ETB"),
              SizedBox(height: 5),
              Text(
                  "Unclaimed amount: ${CurrencyInputFormatter.toCurrency(unclaimedAmount.toString())} ETB"),
            ],
          ),
          actions: [
            CupertinoButton(
              child: Text("Cancel",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  )),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }

  Future<Response> _makeReclaimSelectedRequest() {
    var requester = HttpRequester(path: "/oauth/user/moneytoken/reclaim.json");
    return requester.put(context, {"codes": _getSelectedCodes()});
  }

  Future<void> _reclaimSelected(BuildContext context) async {
    Navigator.pop(context);
    showLoaderDialog(context);
    await _handleResponse(context, _makeReclaimSelectedRequest,
        _onReclaimSelectedSuccess, _onReclaimSelectedError);
  }

  void _onReclaimSelectedTap(BuildContext context) {
    _reclaimAmount = 0;

    if (_selectedCount <= 0) {
      return;
    }

    _moneyTokenList.forEach((moneyToken) {
      if (_checkList[moneyToken.code]) {
        _reclaimAmount += moneyToken.amount;
      }
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      child: AlertDialog(
        content: Text(
            "Do you wish to reclaim ${CurrencyInputFormatter.toCurrency(_reclaimAmount.toString())} ETB "
            "collected from the selected $_selectedCount transfer money token${_selectedCount > 1 ? "s" : ""}."),
        actions: [
          CupertinoButton(
            child: Text("Ok",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                )),
            onPressed: () => _reclaimSelected(context),
          ),
          CupertinoButton(
            child: Text("Cancel",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                )),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  /* ----------------------------------- GET MONEY TOKENS ----------------------------------- */

  void _onGetMoneyTokensSuccess(Response response) {
    setState(() {
      List<dynamic> jsonData = json.decode(response.body);
      jsonData.forEach((json) {
        MoneyToken moneyToken = MoneyToken.fromJson(json);
        _filterAndAdd(moneyToken);
        _checkList[moneyToken.code] = false;
      });
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _getMoneyTokenTileSize());

    _restCheckList();
  }

  Future<void> _makeGetMoneyTokensRequest() async {
    var requester = HttpRequester(path: "/oauth/user/moneytoken.json");
    try {
      Response response = await requester.get(context);

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onGetMoneyTokensSuccess(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}

    _moneyTokenList.sort((a, b) {
      return a.expirationDate.compareTo(b.expirationDate);
    });
  }

  Future<void> _refresh() async {
    _isAllSelected = false;
    await _makeGetMoneyTokensRequest();
  }

  void _connectivityChecker() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        _refresh();
      }
    });
  }

  void _onLongPress() {
    _isCheckable = !_isCheckable;
    _restCheckList();
    setState(() {});
  }

  void _onCheckboxTap(String code, bool value) {
    if (value) {
      _selectedCount++;
    } else {
      _selectedCount--;
    }

    _checkList[code] = value;
    setState(() {});
  }

  void _restCheckList() {
    _selectedCount = 0;
    _checkList.forEach((key, value) {
      _checkList[key] = false;
    });
  }

  void _onSelectMenuItem(value, BuildContext context) {
    switch (value) {
      case "select":
        setState(() {
          _restCheckList();
          _isCheckable = true;
        });
        break;
      case "deselect":
        setState(() {
          _restCheckList();
          _isCheckable = false;
        });
        break;

      case "selectPaymentTokens":
        _selectedCount = 0;
        _moneyTokenList.forEach((moneyToken) {
          if (moneyToken.method == MethodPaymentQRCodeB) {
            _checkList[moneyToken.code] = true;
            _selectedCount++;
          } else {
            _checkList[moneyToken.code] = false;
          }
        });
        setState(() {
          _isCheckable = true;
        });

        var index = _moneyTokenList.indexWhere((moneyToken) {
          if (moneyToken.method == MethodPaymentQRCodeB) {
            return true;
          }
          return false;
        });

        double scrollOffset = index * _moneyTokenTileSize?.height ?? 0;
        _scrollController.animateTo(scrollOffset,
            duration: Duration(milliseconds: 500), curve: Curves.ease);
        break;

      case "selectTransferTokens":
        _selectedCount = 0;
        _moneyTokenList.forEach((moneyToken) {
          if (moneyToken.method == MethodTransferQRCodeB) {
            _checkList[moneyToken.code] = true;
            _selectedCount++;
          } else {
            _checkList[moneyToken.code] = false;
          }
        });
        setState(() {
          _isCheckable = true;
        });

        var index = _moneyTokenList.indexWhere((moneyToken) {
          if (moneyToken.method == MethodTransferQRCodeB) {
            return true;
          }
          return false;
        });

        double scrollOffset = index * _moneyTokenTileSize?.height ?? 0;
        _scrollController.animateTo(scrollOffset,
            duration: Duration(milliseconds: 500), curve: Curves.ease);

        break;

      case "reclaimSelected":
        _onReclaimSelectedTap(context);
        break;

      case "removeSelected":
        _onRemoveSelectedTap(context);
        break;

      case "refreshSelected":
        _onRefreshSelectedTap(context);
        break;
    }
  }

  List<Widget> _generateActionButtons() {
    List<Widget> actionButtons = List<Widget>();
    if (_isCheckable) {
      actionButtons.add(
        IconButton(
          icon: Icon(
            Icons.select_all,
            color: Colors.white,
          ),
          onPressed: () {
            _isAllSelected = !_isAllSelected;
            _selectedCount = 0;
            setState(() {
              _checkList.forEach((key, value) {
                _checkList[key] = _isAllSelected;
                if (_isAllSelected) _selectedCount++;
              });
            });
          },
        ),
      );

      bool showReclaimButton = false;
      bool showRemoveButton = false;

      _moneyTokenList.forEach((moneyToken) {
        if (_checkList[moneyToken.code] &&
            moneyToken.method == MethodPaymentQRCodeB) {
          showRemoveButton = true;
        } else if (_checkList[moneyToken.code] &&
            moneyToken.method == MethodTransferQRCodeB) {
          showReclaimButton = true;
        }
      });

      if (showRemoveButton || showReclaimButton) {
        actionButtons.add(
          Builder(builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () => _onRefreshSelectedTap(context),
            );
          }),
        );
      }

      if (showReclaimButton && !showRemoveButton) {
        actionButtons.add(
          Builder(builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.file_download,
                color: Colors.white,
              ),
              onPressed: () => _onReclaimSelectedTap(context),
            );
          }),
        );
      } else if (showRemoveButton && !showReclaimButton) {
        actionButtons.add(
          Builder(builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: () => _onRemoveSelectedTap(context),
            );
          }),
        );
      }
    }

    actionButtons.add(
      Builder(builder: (context) {
        return IconButton(
          icon: PopupMenuButton(
            child: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            padding: EdgeInsets.zero,
            tooltip: "Options",
            onSelected: (value) => _onSelectMenuItem(value, context),
            itemBuilder: _generatePopUpItems,
          ),
        );
      }),
    );

    return actionButtons;
  }

  List<PopupMenuEntry<dynamic>> _generatePopUpItems(BuildContext context) {
    List<PopupMenuEntry<dynamic>> popUpItems = List<PopupMenuEntry<dynamic>>();

    if (_isCheckable) {
      popUpItems.add(PopupMenuItem(
        value: "deselect",
        child: Text("Deselect"),
        height: 35,
        enabled: _moneyTokenList.length > 0,
      ));
    } else {
      popUpItems.add(PopupMenuItem(
        value: "select",
        child: Text("Select"),
        height: 35,
        enabled: _moneyTokenList.length > 0,
      ));
    }

    bool showReclaimMenu = false;
    bool showRemoveMenu = false;

    _moneyTokenList.forEach((moneyToken) {
      if (_checkList[moneyToken.code] &&
          moneyToken.method == MethodPaymentQRCodeB) {
        showRemoveMenu = true;
      } else if (_checkList[moneyToken.code] &&
          moneyToken.method == MethodTransferQRCodeB) {
        showReclaimMenu = true;
      }
    });

    if (showReclaimMenu && !showRemoveMenu) {
      popUpItems.add(PopupMenuItem(
        value: "reclaimSelected",
        child: Text("Reclaim Selected"),
        height: 35,
      ));
    } else if (showRemoveMenu && !showReclaimMenu) {
      popUpItems.add(PopupMenuItem(
        value: "removeSelected",
        child: Text("Remove Selected"),
        height: 35,
      ));
    }

    if (showRemoveMenu || showReclaimMenu) {
      popUpItems.add(PopupMenuItem(
        value: "refreshSelected",
        child: Text("Refresh Selected"),
        height: 35,
      ));
    }

    popUpItems.add(PopupMenuItem(
      value: "selectTransferTokens",
      child: Row(
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text("Select All"),
          SizedBox(width: 8),
          Text(
            "S",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
        ],
      ),
      height: 35,
      enabled: _moneyTokenList.length > 0,
    ));
    popUpItems.add(PopupMenuItem(
      value: "selectPaymentTokens",
      child: Row(
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text("Select All"),
          SizedBox(width: 8),
          Text(
            "P",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
        ],
      ),
      height: 35,
      enabled: _moneyTokenList.length > 0,
    ));

    return popUpItems;
  }

  void _getMoneyTokenTileSize() {
    RenderBox cardBox = _globalKey.currentContext?.findRenderObject();
    _moneyTokenTileSize = cardBox?.size;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _makeGetMoneyTokensRequest();
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _connectivityChecker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vault"),
        actions: _generateActionButtons(),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 3, right: 3, top: 5),
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _moneyTokenList.length == 0
              ? Stack(
                  children: [
                    ListView(), // This ListView is used for showing the refreshIndicator
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
                                color: Theme.of(context).iconTheme.color),
                          )
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _moneyTokenList.length,
                  itemBuilder: (context, index) {
                    return MoneyTokenTile(
                      _moneyTokenList[index],
                      key: index == 0
                          ? _globalKey
                          : ValueKey(_moneyTokenList[index].code),
                      value: _checkList[_moneyTokenList[index].code],
                      isCheckable: _isCheckable,
                      onLongPress: _onLongPress,
                      onCheckboxTap: _onCheckboxTap,
                      remove: _deleteMoneyToken,
                      refresh: _refreshMoneyToken,
                    );
                  }),
        ),
      ),
    );
  }
}
