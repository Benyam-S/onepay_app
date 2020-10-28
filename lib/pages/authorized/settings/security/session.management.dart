import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onepay_app/main.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/session.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/localdata.handler.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:onepay_app/widgets/tile/session.dart';
import 'package:recase/recase.dart';

class SessionManagement extends StatefulWidget {
  _SessionManagement createState() => _SessionManagement();
}

class _SessionManagement extends State<SessionManagement> {
  Future<Session> _currentSessionF;
  String _currentAccessToken;
  List<Session> _activeSessions = List<Session>();
  GlobalKey<SliverAnimatedListState> _globalKey = GlobalKey();
  bool _terminatingAll = false;
  StreamController _setTerminateAllController;

  void _filterAndAdd(Session session) {
    if (_currentAccessToken == session.id) {
      _currentSessionF = Future<Session>.value(session);
      return;
    }

    bool addFlag = true;
    for (int i = 0; i < _activeSessions.length; i++) {
      if (_activeSessions[i].id == session.id) {
        _activeSessions[i] = session;
        addFlag = false;
        break;
      }
    }

    if (addFlag) {
      // Sorting based on time
      // Based on the concept of the previous list is sorted, so just find the first element less than the current
      int index = _activeSessions.length;
      for (int j = 0; j < _activeSessions.length; j++) {
        if (session.updatedAt.isAfter(_activeSessions[j].updatedAt)) {
          index = j;
          break;
        }
      }

      _activeSessions.insert(index, session);
      _globalKey.currentState?.insertItem(
        index,
        duration: Duration(milliseconds: 400),
      );
    }
  }

  void _removeSession(String id) {
    int index = _activeSessions.indexWhere((session) {
          if (session.id == id) return true;
          return false;
        }) ??
        0;

    Session removedSession = _activeSessions.removeAt(index);

    if (_activeSessions.length == 0) {
      setState(() {});
    } else {
      _globalKey.currentState.removeItem(
        index,
        (context, animation) => SlideTransition(
          position: animation.drive(Tween(begin: Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeIn))),
          child: SessionTile(
            removedSession,
            key: ValueKey(removedSession.id),
            remove: _removeSession,
            isCurrent: false,
          ),
        ),
        duration: Duration(milliseconds: 400),
      );
    }
  }

  Future<void> _onGetActiveSessionsSuccess(Response response) async {
    _currentAccessToken = OnePay.of(context).accessToken?.accessToken ??
        (await getLocalAccessToken())?.accessToken;

    List<dynamic> jsonData = json.decode(response.body);
    jsonData.forEach((json) {
      Session session = Session.fromJson(json);
      _filterAndAdd(session);
    });

    setState(() {});
  }

  Future<void> _getActiveSessions() async {
    var requester = HttpRequester(path: "/oauth/user/session.json");
    try {
      Response response = await requester.get(context);

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        await _onGetActiveSessionsSuccess(response);
      }
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {}
  }

  void _onTerminateSessionsSuccess(BuildContext context, Response response) {
    List<dynamic> deactivatedSessions = json.decode(response.body);

    deactivatedSessions.forEach((deactivatedSession) {
      _removeSession(deactivatedSession);
    });
  }

  void _onTerminateSessionsError(BuildContext context, Response response) {
    if (response.statusCode == HttpStatus.conflict) {
      var jsonData = json.decode(response.body);
      List<dynamic> deactivatedSessions = jsonData['DeactivatedSessions'];

      deactivatedSessions.forEach((deactivatedSession) {
        _removeSession(deactivatedSession);
      });

      showServerError(
          context, ReCase("unable to terminate some sessions").sentenceCase);
    } else {
      showServerError(
          context, ReCase("unable to terminate sessions").sentenceCase);
    }
  }

  Future<void> _makeTerminateSessionsRequest(
      BuildContext context, String sessions) async {
    var requester = HttpRequester(path: "/oauth/user/session.json");
    try {
      Response response = await requester.put(context, {"ids": sessions});

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onTerminateSessionsSuccess(context, response);
      } else {
        _onTerminateSessionsError(context, response);
      }
    } on SocketException {
      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      showServerError(context, SomethingWentWrongError);
    }
  }

  void _terminateAllOtherSessions(BuildContext context) async {
    String sessions = "";
    _activeSessions.forEach((session) {
      sessions += session.id + " ";
    });

    void terminate() async {
      setState(() {
        _terminatingAll = true;
        _setTerminateAllController.add(true);
      });
      await _makeTerminateSessionsRequest(context, sessions);
      setState(() {
        _terminatingAll = false;
        _setTerminateAllController.add(false);
      });
    }

    showDialog(
      context: context,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to terminate the rest ${_activeSessions.length} sessions?",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CupertinoButton(
                  child: Text(
                    "Ok",
                    style: TextStyle(fontSize: 14),
                  ),
                  minSize: 0,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).pop();
                    terminate();
                  },
                ),
                CupertinoButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: 14),
                  ),
                  minSize: 0,
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await _getActiveSessions();
  }

  void _connectivityChecker() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        _getActiveSessions();
      }
    });
  }

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    _setTerminateAllController = StreamController.broadcast();
    _connectivityChecker();
  }

  @override
  void dispose() {
    _setTerminateAllController.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _getActiveSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sessions")),
      body: Builder(
        builder: (context) {
          return FutureBuilder<Session>(
              future: _currentSessionF,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Session currentSession = snapshot.data;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                child: Text(
                                  "Current Session",
                                  style: TextStyle(
                                      fontSize: 13, fontFamily: 'Roboto'),
                                ),
                              ),
                              SessionTile(
                                currentSession,
                                key: ValueKey(currentSession.id),
                                isCurrent: true,
                                remove: _removeSession,
                              ),
                              Visibility(
                                visible: _activeSessions.length > 0,
                                child: Card(
                                  shape: ContinuousRectangleBorder(),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: _terminatingAll
                                        ? null
                                        : () =>
                                            _terminateAllOtherSessions(context),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 15),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            "Terminate All Other Sessions",
                                            style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                    .errorColor),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                              "Logs out all devices except from this one")
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                child: Text(
                                  "Active Sessions",
                                  style: TextStyle(
                                      fontSize: 13, fontFamily: 'Roboto'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _activeSessions.length > 0
                            ? SliverAnimatedList(
                                key: _globalKey,
                                initialItemCount: _activeSessions.length,
                                itemBuilder: (context, index, animation) {
                                  return SlideTransition(
                                    position: animation.drive(Tween(
                                            begin: Offset(-1, 0),
                                            end: Offset.zero)
                                        .chain(
                                            CurveTween(curve: Curves.easeIn))),
                                    child: SessionTile(
                                      _activeSessions[index],
                                      key: ValueKey(_activeSessions[index].id),
                                      remove: _removeSession,
                                      isCurrent: false,
                                      setTerminating:
                                          _setTerminateAllController.stream,
                                    ),
                                  );
                                },
                              )
                            : SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(CustomIcons.box, size: 80),
                                      SizedBox(height: 10),
                                      Text(
                                        "Nothing to show yet!",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color),
                                      )
                                    ],
                                  ),
                                ),
                              )
                      ],
                    ),
                  );
                }

                return Center(
                  child: Container(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(),
                  ),
                );
              });
        },
      ),
    );
  }
}
