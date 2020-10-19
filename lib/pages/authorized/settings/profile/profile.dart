import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/user.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/routes.dart';
import 'package:onepay_app/utils/show.dialog.dart';

class Profile extends StatefulWidget {
  _Profile createState() => _Profile();
}

class _Profile extends State<Profile> {
  User _user;
  String _phoneNumber;
  bool _isAuthorized = false;

  final _initPhoneNumberFormatter = FlutterLibphonenumber().init();

  void _localizingData() {
    if (_user != null) {
      // Localizing phone number
      _initPhoneNumberFormatter.then((_) {
        try {
          Future<Map<String, dynamic>> fParsed =
              FlutterLibphonenumber().parse(_user.onlyPhoneNumber);
          fParsed.then((parsed) {
            if (mounted)
              setState(() {
                _phoneNumber = parsed["national"] as String;
              });
          });
        } catch (e) {
          setState(() {});
        }
      });
    }
  }

  void _initUserProfile() async {
    _user = OnePay.of(context).currentUser ?? await getLocalUserProfile();
    _phoneNumber = _user?.onlyPhoneNumber;
    _localizingData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _initUserProfile();

    OnePay.of(context).userStream.listen((user) {
      if (mounted) {
        // Don't need to set state since set state is called in _localizing data
        _user = user as User;
        _phoneNumber = _user?.onlyPhoneNumber;
        _localizingData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: ListView(
        physics: RangeMaintainingScrollPhysics(),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 5),
            shape: ContinuousRectangleBorder(),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.updateBasicInfo);
              },
              child: Container(
                color: Theme.of(context).backgroundColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: Row(
                  children: [
                    Icon(Icons.contacts),
                    SizedBox(width: 10),
                    Text(
                      "Basic Information",
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          color: Theme.of(context).iconTheme.color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 5),
            shape: ContinuousRectangleBorder(),
            child: InkWell(
              onTap: () {
                if (_isAuthorized) {
                  Navigator.of(context).pushNamed(AppRoutes.updatePhoneNumber);
                } else {
                  showPasswordAuthorizationDialog(context, () {
                    _isAuthorized = true;
                    Navigator.of(context)
                        .pushNamed(AppRoutes.updatePhoneNumber);
                  });
                }
              },
              child: Container(
                color: Theme.of(context).backgroundColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_iphone),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Phone Number",
                          style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              color: Theme.of(context).iconTheme.color),
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Text(_phoneNumber ?? "",
                            style: TextStyle(
                                // fontFamily: 'Roboto',
                                color: Theme.of(context).iconTheme.color))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 5),
            shape: ContinuousRectangleBorder(),
            child: InkWell(
              onTap: () {
                if (_isAuthorized) {
                  Navigator.of(context).pushNamed(AppRoutes.updateEmail);
                } else {
                  showPasswordAuthorizationDialog(context, () {
                    _isAuthorized = true;
                    Navigator.of(context).pushNamed(AppRoutes.updateEmail);
                  });
                }
              },
              child: Container(
                color: Theme.of(context).backgroundColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: Row(
                  children: [
                    Icon(Icons.email),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email",
                          style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              color: Theme.of(context).iconTheme.color),
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Text(_user?.email ?? "",
                            style: TextStyle(
                                // fontFamily: 'Roboto',
                                color: Theme.of(context).iconTheme.color))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
