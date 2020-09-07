import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:onepay_app/pages/inside/send/via.qrcode.dart';

class Send extends StatefulWidget {
  _Send createState() => _Send();
}

class _Send extends State<Send> with TickerProviderStateMixin {
  TabController _tabController;
  int _startIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController =
        TabController(vsync: this, length: 3, initialIndex: _startIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(25, 20, 25, 30),
          child: Container(
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: Theme.of(context).colorScheme.primaryVariant)),
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 0,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryVariant,
              ),
              onTap: (index) => this.setState(() {
                _startIndex = index;
              }),
              tabs: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          color: Theme.of(context).colorScheme.primaryVariant,
                          width: 0.5),
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
                          color: Theme.of(context).colorScheme.primaryVariant,
                          width: 0.5),
                      right: BorderSide(
                          color: Theme.of(context).colorScheme.primaryVariant,
                          width: 0.5),
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
                          color: Theme.of(context).colorScheme.primaryVariant,
                          width: 0.5),
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
              ViaQRCode(),
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
