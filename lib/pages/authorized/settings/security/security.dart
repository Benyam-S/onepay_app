import 'package:flutter/material.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/preferences.state.dart';
import 'package:onepay_app/models/user.preference.dart';
import 'package:onepay_app/pages/authorized/settings/security/two.step.verification.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/widgets/tile/security.dart';

class Security extends StatefulWidget {
  _Security createState() => _Security();
}

class _Security extends State<Security> {
  bool _twoStepVerificationValue = false;
  bool _twoStepVerificationProgress = false;

  bool _dataSaverState = false;
  bool _dataSaverStateProgress = false;

  Future<void> _initInAppSettings() async {
    UserPreference userPreference =
        OnePay.of(context).userPreference ?? await getLocalUserPreference();
    DataSaverState dataSaverState =
        OnePay.of(context).dataSaverState ?? await getLocalDataSaverState();

    if (dataSaverState == DataSaverState.Enabled) {
      _dataSaverState = true;
    } else {
      _dataSaverState = false;
    }

    setState(() {
      _twoStepVerificationValue = userPreference.twoStepVerification;
    });
  }

  Future<void> _onTwoStepVerificationChange(
      BuildContext context, bool value) async {
    setState(() {
      _twoStepVerificationProgress = true;
    });

    _twoStepVerificationValue =
        await onChangeTwoStepVerification(context, value);

    setState(() {
      _twoStepVerificationProgress = false;
    });
  }

  Future<void> _onDataSaverStateChange(BuildContext context, bool value) async {
    setState(() {
      _dataSaverStateProgress = true;
    });

    _dataSaverState = value;

    if (value) {
      OnePay.of(context).appStateController.add(DataSaverState.Enabled);
      await setLocalDataSaverState(DataSaverState.Enabled);
    } else {
      OnePay.of(context).appStateController.add(DataSaverState.Disabled);
      await setLocalDataSaverState(DataSaverState.Disabled);
    }

    setState(() {
      _dataSaverStateProgress = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initInAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Security and Privacy"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return ListView(
            children: [
              Container(
                child: Text(
                  "In-App Settings",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      color: Theme.of(context).iconTheme.color),
                ),
                padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
              ),
              SecurityTile(
                title: "Data Saver",
                desc:
                    "Enabling data saver will automatically close any live connection "
                    "with server. Any updates or changes to our account will be effective after reload.",
                onChange: (value) => _onDataSaverStateChange(context, value),
                value: _dataSaverState,
                isChanging: _dataSaverStateProgress,
              ),
              Container(
                child: Text(
                  "Security",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      color: Theme.of(context).iconTheme.color),
                ),
                padding: const EdgeInsets.fromLTRB(15, 20, 0, 5),
              ),
              SecurityTile(
                title: "Two step verification",
                desc: "Protect your account with two step verification,"
                    " on login a verification code will be sent to your phone number to verify your identity.",
                value: _twoStepVerificationValue,
                isChanging: _twoStepVerificationProgress,
                onChange: (value) =>
                    _onTwoStepVerificationChange(context, value),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).iconTheme.color.withOpacity(0.1),
                    ),
                    top: BorderSide(
                      color: Theme.of(context).iconTheme.color.withOpacity(0.1),
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.sessionManagement),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 20, 5, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other),
                        SizedBox(width: 10),
                        Text(
                          "Session Management",
                          style: TextStyle(fontSize: 13, fontFamily: 'Roboto'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 5),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).iconTheme.color.withOpacity(0.1),
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.changePassword),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 20, 5, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.lock),
                        SizedBox(width: 10),
                        Text(
                          "Change Password",
                          style: TextStyle(fontSize: 13, fontFamily: 'Roboto'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 5),
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              .withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => showDeleteAccountDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 20, 5, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever),
                            SizedBox(width: 10),
                            Text(
                              "Delete Account",
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Roboto',
                                color: Theme.of(context).errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      "This action is irreversible, please drain your wallet and reclaim any money token before proceeding.",
                      style: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                          fontSize: 10),
                    ),
                  )
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
