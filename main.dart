// import 'package:flutter/material.dart';
import 'dart:io';

import 'parser.dart' as parser;

void main() async {
  List<String> urlList = [
    "https://youtu.be/hcsX5Qd2GLo",
    "https://www.tiktok.com/@miraculous_bogaboo000/video/7249121848166731013?is_from_webapp=1",
    "https://www.facebook.com/watch/?v=632518552179712",
    "https://www.instagram.com/reel/CpKyiMhpM6M/?utm_source=ig_web_button_share_sheet",
    "https://www.reddit.com/r/dankvideos/comments/15prvpl/think_about_what_you_do_twice/?context=3",
    "https://www.reddit.com/r/dankvideos/comments/15p9oqg/blind/?utm_source=share&utm_medium=web2x&context=3",
    "https://twitter.com/Purple_Elf/status/1689765212117696512",
  ];
  Map urls = await parser.Parse().linkGen(urlList[urlList.length-1]);
  print(urls);
  exit(0);
  return;
}
