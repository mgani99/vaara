
import 'package:flutter/material.dart';

import 'constants.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.grey.shade300,
    primary: Colors.grey.shade200,
    secondary: Colors.grey.shade400,
    inversePrimary: Colors.grey.shade800,

  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Colors.grey[800],
    displayColor: Colors.black,
  ),
  inputDecorationTheme: lightInputDecorationTheme,
);

const InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
  fillColor: lightGreyColor,
  filled: true,
  hintStyle: TextStyle(color: greyColor),
  border: outlineInputBorder,
  enabledBorder: outlineInputBorder,
  focusedBorder: focusedOutlineInputBorder,
  errorBorder: errorOutlineInputBorder,
);