import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:onepay_app/pages/inside/send/via.qrcode.dart';

class Send extends StatefulWidget {
  Send({Key key}) : super(key: key);

  _Send createState() => _Send();
}

class _Send extends State<Send> with TickerProviderStateMixin {
  TabController _tabController;
  int _startIndex = 0;
  // This stream controller is used to notify the tabs when the tab change
  StreamController<bool> _clearErrorStreamController;

  @override
  void initState() {
    super.initState();

    _tabController =
        TabController(vsync: this, length: 3, initialIndex: _startIndex);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      _clearErrorStreamController.add(true);
    });

    _clearErrorStreamController = StreamController.broadcast();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clearErrorStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(25, 20, 25, 30),
          child: Container(
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Theme.of(context).primaryColor)),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 0,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              onTap: (index) => this.setState(() {
                _startIndex = index;
              }),
              tabs: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          color: Theme.of(context).primaryColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tab(
                        child: Text("Qr Code"),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: Theme.of(context).primaryColor, width: 0.5),
                      right: BorderSide(
                          color: Theme.of(context).primaryColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tab(
                        child: Text("OnePay ID"),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: Theme.of(context).primaryColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tab(
                        child: Text("Payment"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ViaQRCode(
                clearErrorStream: _clearErrorStreamController.stream,
              ),
              Center(
                child: Text("Container 2"),
              ),
              Center(
                child: Text("Container 3"),
              )
            ],
          ),
        )
      ],
    );
  }
}
