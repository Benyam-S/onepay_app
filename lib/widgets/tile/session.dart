import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:onepay_app/models/errors.dart';
import 'package:onepay_app/models/session.dart';
import 'package:onepay_app/utils/exceptions.dart';
import 'package:onepay_app/utils/logout.dart';
import 'package:onepay_app/utils/request.maker.dart';
import 'package:onepay_app/utils/response.dart';
import 'package:onepay_app/utils/show.snackbar.dart';
import 'package:recase/recase.dart';

class SessionTile extends StatefulWidget {
  final Key key;
  final Session session;
  final bool isCurrent;
  final Function(String) remove;
  final Stream setTerminating;

  SessionTile(this.session,
      {this.key, this.isCurrent, @required this.remove, this.setTerminating});

  _SessionTile createState() => _SessionTile();
}

class _SessionTile extends State<SessionTile> {
  bool _isTerminating = false;

  void _onSuccess(Response response) {
    widget.remove(widget.session.id);
  }

  Future<void> _makeTerminateSessionRequest() async {
    var requester = HttpRequester(path: "/oauth/user/session.json");
    try {
      Response response =
          await requester.put(context, {"ids": widget.session.id});

      if (!isResponseAuthorized(context, response)) {
        return;
      }

      if (response.statusCode == HttpStatus.ok) {
        _onSuccess(response);
      } else {
        showServerError(
            context, ReCase("unable to terminate session").sentenceCase);
      }
    } on SocketException {
      showUnableToConnectError(context);
    } on AccessTokenNotFoundException {
      logout(context);
    } catch (e) {
      showServerError(context, SomethingWentWrongError);
    }
  }

  void _terminateSession() async {
    Navigator.of(context).pop();
    setState(() {
      _isTerminating = true;
    });

    await _makeTerminateSessionRequest();

    setState(() {
      _isTerminating = false;
    });
  }

  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        builder: (context) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 5),
                    widget.isCurrent ?? false
                        ? Text(
                            "Current Session Detail",
                            style:
                                TextStyle(fontFamily: 'Roboto', fontSize: 12),
                          )
                        : Text(
                            "Terminate this session?",
                            style:
                                TextStyle(fontFamily: 'Roboto', fontSize: 12),
                          ),
                    SizedBox(height: 5),
                    Text(
                      widget.session?.applicationName ?? "",
                      softWrap: true,
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      widget.session?.targetDevice ?? "",
                      softWrap: true,
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Logged in: ${DateFormat('yyyy-MM-dd hh:mm aaa').format(widget.session?.createdAt) ?? ""}",
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Last seen: ${DateFormat('yyyy-MM-dd hh:mm aaa').format(widget.session?.updatedAt) ?? ""} ",
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      widget.session?.ipAddress,
                      style:
                          TextStyle(color: Theme.of(context).iconTheme.color),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                widget.isCurrent ?? false
                    ? SizedBox()
                    : InkWell(
                        onTap: _terminateSession,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 15, top: 15),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color: Theme.of(context).errorColor,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Terminate session",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: Theme.of(context).errorColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15, top: 15),
                    child: Row(
                      children: [
                        Icon(Icons.cancel),
                        SizedBox(width: 5),
                        Text(
                          "Cancel",
                          style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
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

    widget.setTerminating?.listen((event) {
      setState(() {
        if (event != null) {
          _isTerminating = event as bool;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayTime = widget.isCurrent ?? false
        ? DateFormat('yyyy-MM-dd hh:mm aaa')
                .format(widget.session?.createdAt) ??
            ""
        : DateFormat('yyyy-MM-dd hh:mm aaa')
                .format(widget.session?.updatedAt) ??
            "";

    return Card(
      key: widget.key,
      shape: ContinuousRectangleBorder(),
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      child: InkWell(
        onTap: _isTerminating ? null : _showBottomSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.session?.applicationName ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontFamily: 'Roboto'),
                  ),
                  Visibility(
                    visible: _isTerminating,
                    child: Container(
                      height: 10,
                      width: 10,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Text(
                widget.session?.applicationName ?? "",
                softWrap: true,
              ),
              Text(
                widget.session?.targetDevice ?? "",
                softWrap: true,
              ),
              SizedBox(height: 5),
              widget.isCurrent ?? false
                  ? Text("Logged in: $displayTime")
                  : Text("Last seen: $displayTime"),
              SizedBox(height: 3),
              Text(
                widget.session?.ipAddress,
                style: TextStyle(color: Theme.of(context).iconTheme.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
