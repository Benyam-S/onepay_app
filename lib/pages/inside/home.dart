import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/pages/inside/send/send.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';

class Home extends StatefulWidget {
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  int _currentIndex = 1;
  String _appBarTitle = "";
  Widget _currentSection;
  List<Widget> _listOfSections;

  @override
  void initState() {
    super.initState();

    _listOfSections = [
      Container(),
      Send(),
      Container(),
      Container(),
      Container()
    ];
    _currentSection = _listOfSections[_currentIndex];
  }

  void changeSection(int index) {
    setState(() {
      _currentIndex = index;
      _currentSection = _listOfSections[_currentIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        _appBarTitle = "OnePay";
        break;
      case 1:
        _appBarTitle = "Send";
        break;
      case 2:
        _appBarTitle = "Receive";
        break;
      case 3:
        _appBarTitle = "Wallet";
        break;
      case 4:
        _appBarTitle = "Settings";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
      ),
      body: _currentSection,
      backgroundColor: Theme.of(context).backgroundColor,
      bottomNavigationBar: FFNavigationBar(
        theme: FFNavigationBarTheme(
            barBackgroundColor: Colors.white,
            selectedItemBackgroundColor:
                Theme.of(context).colorScheme.primaryVariant,
            selectedItemIconColor: Colors.white,
            selectedItemLabelColor:
                Theme.of(context).colorScheme.primaryVariant,
            unselectedItemIconColor: Theme.of(context).colorScheme.surface,
            unselectedItemLabelColor: Theme.of(context).colorScheme.surface,
            selectedItemTextStyle: TextStyle(fontSize: 11),
            unselectedItemTextStyle: TextStyle(fontSize: 9)),
        selectedIndex: _currentIndex,
        onSelectTab: (index) => changeSection(index),
        items: [
          FFNavigationBarItem(
            iconData: Icons.show_chart,
            label: 'Exchange',
          ),
          FFNavigationBarItem(
            iconData: CustomIcons.paper_plane,
            label: 'Send',
          ),
          FFNavigationBarItem(
            iconData: CustomIcons.save_money_filled,
            label: 'Receive',
          ),
          FFNavigationBarItem(
            iconData: Icons.account_balance_wallet,
            label: 'Wallet',
          ),
          FFNavigationBarItem(
            iconData: CustomIcons.gear,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
