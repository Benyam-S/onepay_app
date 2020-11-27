import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onepay_app/models/currency.rate.dart';
import 'package:onepay_app/utils/currency.formatter.dart';

class CurrencyExchangeTile extends StatelessWidget {
  final CurrencyRate data;

  CurrencyExchangeTile(this.data);

  String _getDate(DateTime date) {
    String value = "";
    switch (date.weekday) {
      case 1:
        value = "Mon";
        break;
      case 2:
        value = "Tue";
        break;
      case 3:
        value = "Wen";
        break;
      case 4:
        value = "Thur";
        break;
      case 5:
        value = "Fri";
        break;
      case 6:
        value = "Sat";
        break;
      case 7:
        value = "Sun";
        break;
    }

    return value;
  }

  double _getMin(List<double> values) {
    double min = values[0];

    values.forEach((element) {
      if (element < min) {
        min = element;
      }
    });

    return min;
  }

  double _getMax(List<double> values) {
    double max = values[0];

    values.forEach((element) {
      if (element > max) {
        max = element;
      }
    });

    return max;
  }

  double _getDifference(List<double> values) {
    double last = values.last;
    double prev = values[values.length - 2];

    return last - prev;
  }

  @override
  Widget build(BuildContext context) {
    double index = 0;
    double change = _getDifference(data.values);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                ),
                minY: _getMin(data.values) - 2,
                maxY: _getMax(data.values) + 2,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.values
                        .map((value) => FlSpot(index++, value))
                        .toList(),
                    isCurved: true,
                    barWidth: 1,
                    colors: [Colors.grey[300]],
                    belowBarData: BarAreaData(
                      show: true,
                      colors: [data.color.withOpacity(0.4)],
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: SideTitles(
                    showTitles: false,
                    reservedSize: 30,
                    getTitles: (value) {
                      return '${CurrencyInputFormatter.toCurrency(value.toString())}';
                    },
                  ),
                  bottomTitles: SideTitles(
                    showTitles: false,
                    reservedSize: 0,
                    textStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontFamily: 'Roboto'),
                    getTitles: (value) {
                      return _getDate(data.dates[value.toInt()]);
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                  drawVerticalLine: false,
                  verticalInterval: 0.5,
                  horizontalInterval: 0.5,
                ),
                borderData: FlBorderData(
                  show: false,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${data.fromName}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              maxRadius: 5,
                              backgroundColor: data.color,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "${data.fromSymbol}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${CurrencyInputFormatter.toCurrency(data.currentValue.toString())} ${data.toSymbol}",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${change.abs().toStringAsFixed(change.truncateToDouble() == change ? 0 : 3)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: change > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            Icon(
                              change > 0
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: change > 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
