import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Function onTap;

  SettingTile(this.title, this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: ContinuousRectangleBorder(),
      margin: const EdgeInsets.only(bottom: 3.6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                this.title,
                style: TextStyle(fontSize: 13, fontFamily: 'Roboto'),
              ),
              Icon(
                this.icon,
                size: 30,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
