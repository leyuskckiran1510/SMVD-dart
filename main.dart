// import 'package:flutter/material.dart';
import 'dart:io';
import 'parser.dart' as parser;

void main() async {
  String url = await parser.Parse("awd").link();
  print(url);
  // exit(0);
  // return;
}
