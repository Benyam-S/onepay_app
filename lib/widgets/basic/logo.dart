import 'package:flutter/material.dart';
import 'package:onepay_app/utils/custom_icons_icons.dart';

class OPLogoAW extends AnimatedWidget {
  final Animation<double> rotateController;
  final Animation<double> fadeController;
  final Animation<double> sizeController;
  final Function rotate;

  OPLogoAW(
      {Key key,
      @required this.rotateController,
      @required this.fadeController,
      @required this.sizeController,
      this.rotate})
      : super(key: key, listenable: sizeController);

  @override
  Widget build(BuildContext context) {
    Animation<double> sizeAnimation = this.listenable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          child: FadeTransition(
            opacity: fadeController,
            child: RotationTransition(
              alignment: Alignment.center,
              turns: rotateController,
              child: Icon(
                CustomIcons.circled_0,
                color: Colors.white,
                size: 140 * sizeAnimation.value,
              ),
            ),
          ),
          onTap: rotate,
        ),
        FadeTransition(
          opacity: fadeController,
          child: Text(
            "OnePay",
            style: TextStyle(
              fontFamily: "Raleway",
              fontWeight: FontWeight.w700,
              fontSize: 35 * sizeAnimation.value,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
