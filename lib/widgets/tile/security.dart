import 'package:flutter/material.dart';

class SecurityTile extends StatelessWidget {
  final String title;
  final String desc;
  final bool value;
  final bool isChanging;
  final bool disabled;
  final Function(bool) onChange;

  SecurityTile(
      {this.title,
      this.desc,
      @required this.value,
      @required this.isChanging,
      this.disabled,
      @required this.onChange});

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
                      title ?? "",
                      style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          color: (disabled ?? false)
                              ? Theme.of(context).iconTheme.color
                              : Colors.black),
                    ),
                    Row(
                      children: [
                        Visibility(
                          visible: isChanging ?? false,
                          child: Container(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        Switch(
                          value: value ?? false,
                          onChanged:
                              (isChanging ?? false) || (disabled ?? false)
                                  ? null
                                  : onChange,
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
                desc ?? "",
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
