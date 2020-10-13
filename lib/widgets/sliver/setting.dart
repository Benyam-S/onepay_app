import 'dart:math';

import 'package:flutter/material.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:recase/recase.dart';

class SettingAppBar extends SliverPersistentHeaderDelegate {
  final Future<User> user;
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
    return 1.0 - max(0.0, offSet) / maxExtent;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return shrinkOffset > 150
        ? AppBar(title: Text("Settings"))
        : FutureBuilder<User>(
            future: user,
            builder: (context, snapshot) {
              String firstName = "";
              String lastName = "";
              String id = "";
              if (snapshot.hasData) {
                firstName = ReCase(snapshot.data.firstName).sentenceCase;
                lastName = ReCase(snapshot.data.lastName).sentenceCase;
                id = snapshot.data.userID.toUpperCase();
              }

              return Container(
                color: Theme.of(context).colorScheme.primaryVariant,
                child: Stack(
                  children: [
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
            });
  }

  @override
  double get maxExtent => 230;

  @override
  double get minExtent => _appBarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
