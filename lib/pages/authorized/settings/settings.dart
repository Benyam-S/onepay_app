import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class _Settings extends State<Settings> {
  Future<User> _initUser() async {
    return OnePay.of(context).currentUser ?? await getLocalUserProfile();
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
                  delegate: SettingAppBar(user: _initUser()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      SettingTile("Manage Accounts", CustomIcons.debit_card),
                      SettingTile(
                        "Money Vault",
                        CustomIcons.vault_big,
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.moneyVault),
                      ),
                      SettingTile("Recharge", CustomIcons.museum),
                      SettingTile("Withdraw", CustomIcons.withdraw),
                      SettingTile("Profile", CustomIcons.user),
                      SettingTile("Security & Privacy", CustomIcons.shield),
                      SettingTile("Logout", CustomIcons.logout),
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
