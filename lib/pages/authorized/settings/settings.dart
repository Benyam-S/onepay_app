import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/widgets/sliver/setting.dart';
import 'package:onepay_app/widgets/tile/setting.dart';

class Settings extends StatefulWidget {
  _Settings createState() => _Settings();
}

class _Settings extends State<Settings> {
  User _user;

  void _initUser() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initUser();

    OnePay.of(context).userStream.listen((user) {
      if (mounted) {
        setState(() {
          _user = (user as User);
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
          child: CustomScrollView(
            key: PageStorageKey("Settings"),
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
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.accounts),
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
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.recharge),
                      ),
                      SettingTile(
                        "Withdraw",
                        CustomIcons.withdraw,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.withdraw),
                      ),
                      SettingTile(
                        "Profile",
                        CustomIcons.profile_1,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.profile),
                      ),
                      SettingTile(
                        "Security & Privacy",
                        CustomIcons.shield_half,
                      ),
                      SettingTile(
                        "Logout",
                        CustomIcons.powerOff,
                        onTap: () => showLogOutDialog(context),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
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
