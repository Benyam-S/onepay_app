import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/widgets/sliver/setting.dart';
import 'package:onepay_app/widgets/tile/setting.dart';

class Settings extends StatefulWidget {
  _Settings createState() => _Settings();
}

class _Settings extends State<Settings> with WidgetsBindingObserver {
  User _user;
  PermissionStatus _notificationPermissionStatus;
  bool _cOe = false;
  ScrollController _scrollController;

  Future<void> _collapse() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(150,
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

    if (_scrollController.offset > 5 &&
        _scrollController.offset < 150 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        notification is ScrollEndNotification) {
      _cOe = true;
      _collapse().then((value) => _cOe = false);

      return false;
    }

    if (_scrollController.offset < 150 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        notification is ScrollEndNotification) {
      _cOe = true;
      _expand().then((value) => _cOe = false);

      return false;
    }

    return false;
  }

  void _initSettingStates() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    _notificationPermissionStatus =
        await NotificationPermissions.getNotificationPermissionStatus();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initSettingStates();

    OnePay.of(context).userStream.listen((user) {
      if (mounted) {
        setState(() {
          _user = (user as User);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Future<PermissionStatus> notificationPermissionStatus =
        NotificationPermissions.getNotificationPermissionStatus();
    notificationPermissionStatus.then((status) {
      if (status != _notificationPermissionStatus) {
        setState(() {
          _notificationPermissionStatus = status;
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
            child: CustomScrollView(
              key: PageStorageKey("Settings"),
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 6),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: SettingAppBar(user: _user),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        SettingTile(
                          "Manage Accounts",
                          CustomIcons.debit_card,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.accounts),
                        ),
                        SettingTile(
                          "Money Vault",
                          CustomIcons.vault_big,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.moneyVault),
                        ),
                        SettingTile(
                          "Recharge",
                          CustomIcons.alert,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.recharge),
                        ),
                        SettingTile(
                          "Withdraw",
                          CustomIcons.withdraw,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.withdraw),
                        ),
                        SettingTile(
                          "Profile",
                          CustomIcons.profile_1,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.profile),
                        ),
                        SettingTile(
                          "Security & Privacy",
                          CustomIcons.shield_half,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.security),
                        ),
                        SettingTile(
                          "Notifications",
                          CustomIcons.bell,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.notification),
                          additionalIcon: _notificationPermissionStatus ==
                                      PermissionStatus.denied ||
                                  _notificationPermissionStatus ==
                                      PermissionStatus.unknown
                              ? Icon(
                                  Icons.error,
                                  color: Theme.of(context).errorColor,
                                )
                              : null,
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
