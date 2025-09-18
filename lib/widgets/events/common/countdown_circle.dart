import 'dart:math' as math;
import 'package:flutter/material.dart';

class CountdownCircle extends StatelessWidget {
  final int days;
  const CountdownCircle({super.key, required this.days});
  @override
  Widget build(BuildContext context) {
    String displayText = days.toString();
    String labelText = "يوم متبقي";
    if (days == 0) {
      displayText = "🎉";
      labelText = "اليوم";
    } else if (days < 0) {
      displayText = "✓";
      labelText = "انتهت";
    } else if (days == 1) {
      labelText = "يوم واحد";
    } else if (days == 2) {
      labelText = "يومان";
    } else if (days > 2 && days < 11) {
      labelText = "أيام متبقية";
    }
    double progress = days > 0 ? math.max(0, 1 - (days / 365.0)) : 1.0;
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(days > 15
                ? Theme.of(context).primaryColor
                : (days > 5
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.red)),
          ),
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(displayText,
                  style: TextStyle(
                      fontSize: days == 0 || days < 0 ? 24 : 20,
                      fontWeight: FontWeight.bold)),
              if (days >= 0)
                Text(labelText,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center),
            ],
          ))
        ],
      ),
    );
  }
}
