import 'package:flutter/material.dart';

class SecurityTile extends StatefulWidget {
  final String title;
  final String desc;
  final Future<void> Function() onChange;

  SecurityTile({this.title, this.desc, this.onChange});

  @override
  _SecurityTile createState() => _SecurityTile();
}

class _SecurityTile extends State<SecurityTile> {
  bool _value = false;
  bool _isChanging = false;

  void _onChange(bool value) async {
    setState(() {
      _isChanging = true;
    });

    await widget.onChange();

    setState(() {
      _value = value;
      _isChanging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Card(
              shape: ContinuousRectangleBorder(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 5, 5, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title ?? "",
                      style: TextStyle(fontSize: 13, fontFamily: 'Roboto'),
                    ),
                    Row(
                      children: [
                        Visibility(
                          visible: _isChanging,
                          child: Container(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        Switch(
                          value: _value,
                          onChanged: _isChanging ? null : _onChange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                widget.desc ?? "",
                style: TextStyle(
                    color: Theme.of(context).iconTheme.color, fontSize: 10),
              ),
            )
          ],
        )
      ],
    );
  }
}
