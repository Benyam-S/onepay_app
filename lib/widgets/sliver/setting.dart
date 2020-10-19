import 'dart:math';

import 'package:flutter/material.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:recase/recase.dart';

class SettingAppBar extends SliverPersistentHeaderDelegate {
  final User user;
  double _appBarHeight = AppBar().preferredSize.height;
  double _titleFontSize = 17;
  double _descFontSize = 10;
  double _iconSize = 50;

  SettingAppBar({this.user});

  double _getTitleSize(double offSet) {
    return (1.0 - max(0.0, (offSet - minExtent)) / (maxExtent - minExtent)) *
        _titleFontSize;
  }

  double _getDescSize(double offSet) {
    return (1.0 - max(0.0, (offSet - minExtent)) / (maxExtent - minExtent)) *
        _descFontSize;
  }

  double _getIconSize(double offSet) {
    return (1.0 - max(0.0, (offSet - minExtent)) / (maxExtent - minExtent)) *
        _iconSize;
  }

  double _getContainerOpacity(double offSet) {
    if (offSet > 150) return 0;
    return 1.0 - max(0.0, offSet) / maxExtent;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    String firstName = user?.firstName?.sentenceCase ?? "";
    String lastName = user?.lastName?.sentenceCase ?? "";
    String id = user?.userID?.toUpperCase() ?? "";

    return Container(
      color: Theme.of(context).colorScheme.primaryVariant,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              title: shrinkOffset > 150 ? Text("Settings") : null,
              elevation: 0,
              actions: [
                IconButton(
                  icon: PopupMenuButton(
                    child: Icon(Icons.more_vert, color: Colors.white),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      switch (value) {
                        case "logout":
                          showLogOutDialog(context);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          child: Padding(
                            child: Text("Logout"),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          value: "logout",
                          height: 0,
                        ),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Opacity(
              opacity: _getContainerOpacity(shrinkOffset),
              child: Icon(
                CustomIcons.onepay_logo_filled,
                color: Colors.white,
                size: _getIconSize(shrinkOffset),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Opacity(
              opacity: _getContainerOpacity(shrinkOffset),
              child: Padding(
                padding: const EdgeInsets.only(left: 15, bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(firstName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: _getTitleSize(shrinkOffset),
                                fontFamily: 'Roboto')),
                        SizedBox(width: 5),
                        Text(lastName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: _getTitleSize(shrinkOffset),
                                fontFamily: 'Roboto')),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(id.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: _getDescSize(shrinkOffset))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 230;

  @override
  double get minExtent => _appBarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
