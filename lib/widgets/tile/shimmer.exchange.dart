import 'package:flutter/material.dart';
import 'package:onepay_app/utils/custom_icons.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerExchangeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 200,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300],
          highlightColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FractionallySizedBox(
                widthFactor: 1,
                child: Container(height: 10, color: Colors.grey[300]),
              ),
              FractionallySizedBox(
                widthFactor: 0.75,
                child: Container(height: 10, color: Colors.grey[300]),
              ),
              Align(
                child: Icon(
                  CustomIcons.profits,
                  color: Colors.grey[300],
                  size: 55,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Container(height: 10, color: Colors.grey[300]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
