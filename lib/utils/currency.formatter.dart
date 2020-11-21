import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = transformAmount(newValue.text);
    return newValue.copyWith(
        text: newText,
        selection: new TextSelection.collapsed(offset: newText.length));
  }

  /// toCurrency will change the provided amount to currency with decimal point included
  static String toCurrency(String amount) {
    try {
      // Removing any non currency related characters
      amount = amount.replaceAll(RegExp(r"[^0-9.,]"), "");

      // Removing comma before parsing
      if (amount.contains(",")) {
        amount = amount.replaceAll(",", "");
      }

      if (amount.contains(".")) {
        var decimalPointIndex = amount.indexOf(".");
        // Removing other decimal points
        amount = amount.replaceFirst(".", "", decimalPointIndex + 1);

        var amountDouble = double.parse(amount);

        //  Changing the the number to currency format
        FlutterMoneyFormatter formattedAmount =
            FlutterMoneyFormatter(amount: amountDouble);

        return formattedAmount.output.nonSymbol;
      }

      var amountDouble = double.parse(amount);

      //  Changing the the number to currency format
      FlutterMoneyFormatter formattedAmount =
          FlutterMoneyFormatter(amount: amountDouble);
      return formattedAmount.output.nonSymbol;
    } catch (e) {
      return amount;
    }
  }

  /// toDouble will change the provided currency amount to double in string format
  static String toDouble(String amount) {
    try {
      // Removing comma before parsing
      if (amount.contains(",")) {
        amount = amount.replaceAll(",", "");
      }

      var amountDouble = double.parse(amount);

      return amountDouble.toString();
    } catch (e) {
      return amount;
    }
  }

  /// transformAmount is a method that changes the amount to currency
  static String transformAmount(String amount) {
    try {
      // Removing any non currency related characters
      amount = amount.replaceAll(RegExp(r"[^0-9.,]"), "");

      // Removing comma before parsing
      if (amount.contains(",")) {
        amount = amount.replaceAll(",", "");
      }

      if (amount.contains(".")) {
        var decimalPointIndex = amount.indexOf(".");
        // Removing other decimal points
        amount = amount.replaceFirst(".", "", decimalPointIndex + 1);
        var decimalPointValue = amount.substring(decimalPointIndex);

        var amountDouble = double.parse(amount);

        // Including the decimal point
        if (decimalPointValue.length > 3) {
          decimalPointValue = decimalPointValue.substring(0, 3);
        }

        //  Changing the the number to currency format
        FlutterMoneyFormatter formattedAmount =
            FlutterMoneyFormatter(amount: amountDouble);

        return formattedAmount.output.withoutFractionDigits + decimalPointValue;
      }

      var amountDouble = double.parse(amount);

      //  Changing the the number to currency format
      FlutterMoneyFormatter formattedAmount =
          FlutterMoneyFormatter(amount: amountDouble);
      return formattedAmount.output.withoutFractionDigits;
    } catch (e) {
      return amount;
    }
  }
}
