import 'dart:io';

class FilePath {
  String path;
  List<FileSystemEntity> dirlist;
  String choice = "video.mp4";
  String? last;
  FilePath(this.path, this.dirlist) {
    path = Directory(path).absolute.path;
    last = path;
  }

  @override
  String toString() {
    return path;
  }

  void selected(String file) {
    choice = "$path${Platform.pathSeparator}$file";
  }

  static String home() {
    if (Platform.isLinux || Platform.isMacOS) {
      return Platform.environment['HOME']!;
    } else if (Platform.isWindows) {
      return Platform.environment['UserProfile']!;
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/';
    } else if (Platform.isIOS) {
      return "/";
    }
    return "ok";
  }

  void back() {
    if (last != path) {
      last = path;
    }
    path = Directory(path).parent.absolute.path;
  }

  Future<String> list() async {
    dirlist = await Directory(path).list(recursive: false).toList();
    return "ok";
  }

  void show() {
    dirlist.forEach((x) => {
          print(x),
          print(x.uri.pathSegments.lastWhere((x) => x.length > 1)),
        });
  }

  void previous() {
    path = last!;
  }

  void follow(String folder) {
    if (last != path) {
      last = path;
    }
    path = "$path${Platform.pathSeparator}$folder";
  }
}

main() async {
  FilePath p = FilePath(".", []);
  await p.list();
  print(FilePath.home());
}
