import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/currency.rate.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/wallet.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/sliver/currency.exchange.dart';
import 'package:onepay_app/widgets/tile/currency.exchange.dart';
import 'package:onepay_app/widgets/tile/shimmer.exchange.dart';

class Home extends StatefulWidget {
  final ScrollController scrollController;

  Home(this.scrollController);

  _Home createState() => _Home();
}

class _Home extends State<Home> {
  Wallet _wallet;
  bool _loading = true;
  bool _cOe = false;
  int _itemCount = 4;
  List<CurrencyRate> _currencyRates = List<CurrencyRate>();
  List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.pink,
    Colors.teal
  ];

  ScrollController _scrollController;

  Future<void> _onSuccess(Response response) async {
    List<dynamic> jsonData = json.decode(response.body);
    int colorIndex = 0;
    jsonData.forEach((element) {
      CurrencyRate currencyRate = CurrencyRate.fromJson(element);
      if (colorIndex > 4) colorIndex = 0;
      currencyRate.color = _availableColors[colorIndex];
      colorIndex++;
      _currencyRates.add(currencyRate);
    });

    OnePay.of(context).currencyRates = [];
    OnePay.of(context).currencyRates.addAll(_currencyRates);
    setLocalCurrencyRates(_currencyRates);

    setState(() {
      _loading = false;
      _itemCount = _currencyRates.length;
    });
  }

  Future<void> _makeRequest() async {
    var requester = HttpRequester(path: "/oauth/currency/rates/ETB.json");

    try {
      Response response = await requester.get(context);

      if (response.statusCode == HttpStatus.ok) {
        await _onSuccess(response);
      } else {
        showServerError(context, SomethingWentWrongError);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}
  }

  Future<void> _refresh() async {
    await _makeRequest();
    return;
  }

  Widget _loadingShimmerBuilder(BuildContext context, int index) {
    return ShimmerExchangeTile();
  }

  Widget _loadedDataBuilder(BuildContext context, int index) {
    return CurrencyExchangeTile(_currencyRates[index]);
  }

  Future<void> _collapse() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(175,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
    });
  }

  Future<void> _expand() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_cOe) return false;

    if (_scrollController.offset > 42 &&
        _scrollController.offset < 175 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        notification is ScrollEndNotification) {
      _cOe = true;
      _collapse().then((value) => _cOe = false);

      return false;
    }

    if (_scrollController.offset < 175 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        notification is ScrollEndNotification) {
      _cOe = true;
      _expand().then((value) => _cOe = false);

      return false;
    }

    return false;
  }

  void _initUserWallet() async {
    _wallet = OnePay.of(context).userWallet ?? await getLocalUserWallet();

    setState(() {});
  }

  void _initCurrencyRates() async {
    if (OnePay.of(context).currencyRates.length == 0) {
      _currencyRates = await getRecentLocalCurrencyRates();
      if (_currencyRates.length > 0) {
        OnePay.of(context).currencyRates = [];
        OnePay.of(context).currencyRates.addAll(_currencyRates);
      }
    } else {
      _currencyRates = OnePay.of(context).currencyRates;
    }

    int colorIndex = 0;
    _currencyRates.forEach((currencyRate) {
      if (colorIndex > 4) colorIndex = 0;
      currencyRate.color = _availableColors[colorIndex];
      colorIndex++;
    });

    if (_currencyRates.length == 0) {
      _makeRequest();
    } else {
      setState(() {
        _loading = false;
        _itemCount = _currencyRates.length;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initUserWallet();
    _initCurrencyRates();

    OnePay.of(context).walletStream.listen((wallet) {
      if (mounted) {
        setState(() {
          _wallet = (wallet as Wallet);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryVariant,
      child: SafeArea(
        child: Container(
          color: Theme.of(context).backgroundColor,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                key: PageStorageKey("Exchange"),
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 6),
                    sliver: SliverPersistentHeader(
                      pinned: true,
                      delegate: CurrencyExchangeAppBar(
                        wallet: _wallet,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 13),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                          _loading
                              ? _loadingShimmerBuilder
                              : _loadedDataBuilder,
                          childCount: _itemCount),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
