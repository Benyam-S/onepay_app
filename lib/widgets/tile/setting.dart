import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Icon additionalIcon;
  final Function onTap;

  SettingTile(this.title, this.icon, {this.onTap, this.additionalIcon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color:
                        Theme.of(context).iconTheme.color.withOpacity(0.1)))),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  this.icon,
                  size: 30,
                  color: Colors.black,
                ),
                SizedBox(width: 15),
                Text(
                  this.title,
                  style: TextStyle(fontSize: 14, fontFamily: 'Roboto'),
                ),
              ],
            ),
            additionalIcon != null ? additionalIcon : Icon(Icons.chevron_right)
          ],
        ),
      ),
    );
  }
}
