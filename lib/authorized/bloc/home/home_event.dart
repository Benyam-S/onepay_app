import 'package:flutter/material.dart';
import 'package:onepay_app/authorized/bloc/common/common_event.dart';

class EGetCurrencyRates extends AuthorizedEvent {
  final BuildContext context;

  EGetCurrencyRates(this.context);
}
