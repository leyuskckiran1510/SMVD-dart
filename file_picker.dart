import 'dart:convert';
import 'dart:io';


class Path{
    String path;
    List<String> list;
    Path(this.path,this.list);
}

class Picker{

    String root = Directory.current as String;
    static bool chdir(String path){
        return true;
    }
    static Future<Path> follow(String root,String folder){
        String path="";
        if(Platform.isWindows){
            path = "$root\\$folder";
        }
        else{
            path = "$root/$folder";
        }
        return list(path);
    }

    static Future<Path> back(String root){
        String path="";
        if(Platform.isWindows){
            var temp = root.split("\\");
            if(temp.length-2 > 2) {
              path = temp.sublist(0,temp.length-2).join("\\");
            }
        }
        else{
            var temp = root.split("/");
            if(temp.length-2 > 2) {
              path = temp.sublist(0,temp.length-2).join("/");
            }
        }
        return list(path);
    }

    static Future<Path> list(String path) async {
        List<String> outputLines = [];

        Process process = await Process.start('ls', [path]);

        process.stdout.transform(utf8.decoder).listen((data) {
          outputLines.addAll(data.split('\n'));
        });

        process.stderr.transform(utf8.decoder).listen((data) {
        });
        int exitCode = await process.exitCode;
        return Path(path,exitCode==0?outputLines:[]);
      }


}

String? input({String c=""}){
    stdout.write("$c:- ");
    return stdin.readLineSync();

}


main()async {
    Path p = Path(".",[]);
    while (true){
        String? line = input(c:"Input The file path ");
        if(line! =="exit") break;
        p =(await Picker.list(line));
        print(p);

    }
}