import 'package:flutter/material.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';
import 'package:onepay_app/widgets/tile/security.dart';

class Security extends StatefulWidget {
  _Security createState() => _Security();
}

class _Security extends State<Security> {
  Future<void> _onChange() async {
    await Future.delayed(Duration(seconds: 2));
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
              SecurityTile(
                title: "Two step verification",
                desc: "Protect your account with two step verification,"
                    " on login a verification code will be sent to your phone number to verify your identity.",
                onChange: _onChange,
              ),
              SecurityTile(
                title: "Notification",
                desc:
                    "Allow OnePay to forward notification when your account state"
                    " changes even if the application is closed.",
                onChange: _onChange,
              ),
              Card(
                shape: ContinuousRectangleBorder(),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.sessionManagement),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 18, 5, 18),
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
              Card(
                shape: ContinuousRectangleBorder(),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.changePassword),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 18, 5, 18),
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
                  Card(
                    shape: ContinuousRectangleBorder(),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => showDeleteAccountDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 18, 5, 18),
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
