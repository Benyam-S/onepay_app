import 'package:flutter/material.dart';

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
          child: RotationTransition(
            alignment: Alignment.center,
            turns: rotateController,
            child: Image.asset(
              "assets/images/circled_o_white.png",
              width: 140 * sizeAnimation.value,
              height: 140 * sizeAnimation.value,
            ),
          ),
          onTap: rotate,
        ),
        FadeTransition(
          opacity: fadeController,
          child: Text(
            "OnePay",
            style: TextStyle(
              fontFamily: "ComicSans",
              fontWeight: FontWeight.w700,
              fontSize: 40 * sizeAnimation.value,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
