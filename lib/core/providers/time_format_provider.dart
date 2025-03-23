import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimeFormat {
  european, // 24-hour format
  american, // 12-hour format
}

class TimeFormatProvider extends ChangeNotifier {
  static const String _timeFormatKey = 'time_format_key';
  
  TimeFormat _timeFormat = TimeFormat.european;
  
  TimeFormat get timeFormat => _timeFormat;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFormat = prefs.getString(_timeFormatKey);
    
    if (storedFormat != null) {
      _timeFormat = storedFormat == TimeFormat.european.toString() 
        ? TimeFormat.european 
        : TimeFormat.american;
    }
    
    notifyListeners();
  }
  
  Future<void> setTimeFormat(TimeFormat format) async {
    if (_timeFormat == format) return;
    
    _timeFormat = format;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeFormatKey, format.toString());
    
    notifyListeners();
  }
  
  bool get isEuropean => _timeFormat == TimeFormat.european;
}