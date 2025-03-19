import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart' as services;
import 'package:todo_app/app.dart' as app;

void main() async {
  mat.WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await services.SystemChrome.setPreferredOrientations([
    services.DeviceOrientation.portraitUp,
    services.DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  services.SystemChrome.setSystemUIOverlayStyle(
    const services.SystemUiOverlayStyle(
      statusBarColor: mat.Colors.transparent,
      statusBarIconBrightness: services.Brightness.dark,
      statusBarBrightness: services.Brightness.light,
    ),
  );
  
  runApp(const app.TodoApp());
}