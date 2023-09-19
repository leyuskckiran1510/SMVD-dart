import 'dart:developer';
import 'picker_gui.dart';
import 'parser.dart' as parser;
import 'package:flutter/material.dart';

//var log = print;
var print = log;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Leyuskc Video Downloader',
      home: MyCustomForm(),
      color: Color.fromARGB(1, 1, 1, 1),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final myController = TextEditingController();
  Future<dynamic>? responseFuture;
  String? loadingMessage;
  String downLoadState = "Wrong Url";
  parser.Run parserInstance = parser.Run();
  String? selectedVideo;
  String? selectedAudio;

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  Future<String> responseStatus(String url) async {
    try {
      print("(responseStatus) Staring Link Parsing... ");
      parserInstance = parser.Run();
      await parserInstance.determine(url);
      print("(responseStatus) Link Parsing Completed ... ");
      print("${parserInstance.urls['urls']['videos'][0]}");
      if (parserInstance.urls.containsKey("urls")) {
        downLoadState = 'Downlaod';
        selectedVideo = parserInstance.urls["urls"]["videos"][0]['url'];
        selectedAudio = parserInstance.urls["urls"]["audios"][0]['url'];
        print("${parserInstance.urls["urls"]}");
      } else if (parserInstance.urls.containsKey("error")) {
        downLoadState = "Error";
        await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => AlertDialog(
              title: const Text("!!!!Error!!!!"),
              content: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(parserInstance.urls["error"]),
              ),
            ),
          ),
        );

        parserInstance.urls["urls"] = {
          "videos": [
            {"url": ".", "quality": "${parserInstance.urls['error']}"},
          ],
          "audios": [
            {"url": "audio1", "quality": "${parserInstance.urls['error']}"},
          ],
        };
      }
    } catch (e) {
      return "Error $e";
    }
    return "Sucess";
  }

  Future<void> filePicker(String downloadUrl, String ext) async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => FilePicker(
          onFileSelected: (selectedFile) async {
            parserInstance.downloadUrl = downloadUrl;
            parserInstance.saveFileName = selectedFile;
            Navigator.of(context).pop();
          },
          fileNameToSave: "${parserInstance.urls["urls"]["title"]}.$ext",
        ),
      ),
    );
    setState(() {
      responseFuture = parserInstance.download();
      loadingMessage = loadingMessageByPlatform();
    });
  }

  String loadingMessageByPlatform() {
    switch (parserInstance.urls["of"]) {
      case "youtube":
        return "You are trying to download youtube video and youtube takes ages to download for no reason will speed it up in next update";
      case "tiktok":
        return "You are trying to download tiktok video, it should not take more then 2-3 seconds ";
      case "facebook":
        return "You are trying to download facebook video, it should not take more then 2-3 seconds for short content and 1min max for video upto 20minutes ";
      case "instagram":
        return "You are trying to download instagram video, it should not take more then 2-3 seconds for short content and 1min max for video upto 20minutes ";
      case "reddit":
        return "You are trying to download reddit video, it should not take more then 2-3 seconds for short content and 1min max for video upto 20minutes ";
      case "twitter":
        String st = """
        ╔═════════════════════════════════════╗
        ║ Twitter Is not implemnted For Now   ║
        ╚═════════════════════════════════════╝
        """;
        throw st;
      // return await twitter(temp)!;
      default:
        return "Unknown PlatForm....";
    }
  }

  Future<String> startDownload() async {
    try {
      if (selectedVideo != null && selectedVideo!.isNotEmpty) {
        if (parserInstance.saveFileName == "final.mp4") {
          await filePicker(selectedVideo!, "mp4");
        } else {
          parserInstance.downloadUrl = selectedVideo;
          await parserInstance.download();
        }
        selectedVideo = "";
      }
      if (selectedAudio != null && selectedAudio!.isNotEmpty) {
        print("(startDownload) Starting Audio Download.. for $selectedAudio");
        if (parserInstance.saveFileName == "final.mp4") {
          await filePicker(selectedAudio!, "mp3");
        } else {
          parserInstance.saveFileName =
              "${parserInstance.saveFileName.split(".")[0]}.mp3";
          parserInstance.downloadUrl = selectedAudio;
          await parserInstance.download();
        }
        print("(startDownload) Audio Downloade Complete ..");
        selectedAudio = "";
      } else {
        print("(startDownload) No Url selected..");
      }
      parserInstance.urls["urls"] = {};
      return "Sucess";
    } catch (e) {
      print("(startDownload) Got A error $e");
      parserInstance.urls["urls"] = {};
      return "Error $e";
    }
  }

  List<DropdownMenuItem<String>> genDropDownItems(String dataKey) {
    List<DropdownMenuItem<String>> items = [];
    List<dynamic> visited = [];
    for (var elems in parserInstance.urls["urls"][dataKey]) {
      if (!visited.contains(elems['url'])) {
        visited.add(elems['url']);
        print(
            "( $dataKey DropDown )Making Drop Down for ${elems['url']} and ${elems['quality']}");
        items.add(DropdownMenuItem<String>(
          value: elems['url'],
          child: Text(elems['quality']),
        ));
      }
    }
    if (items.isEmpty) {
      items.add(
          const DropdownMenuItem<String>(value: 'empty', child: Text('empty')));
    }

    return items;
  }

  List<Widget> genDropDown() {
    List<Widget> lis = [];
    if (parserInstance.urls["urls"]["videos"] != null &&
        parserInstance.urls["urls"]["videos"].isNotEmpty) {
      lis.add(DropdownButton<String>(
        value: selectedVideo,
        hint: const Text('Select Video'),
        onChanged: (String? newValue) {
          setState(() {
            selectedVideo = newValue;
          });
        },
        items: genDropDownItems("videos"),
      ));
      lis.add(const SizedBox(height: 20));
    } else {
      selectedVideo = "";
    }
    if (parserInstance.urls["urls"]["audios"] != null &&
        parserInstance.urls["urls"]["audios"].isNotEmpty) {
      lis.add(DropdownButton<String>(
        value: selectedAudio,
        hint: const Text('Select Audio'),
        onChanged: (String? newValue) {
          setState(() {
            selectedAudio = newValue;
          });
        },
        items: genDropDownItems("audios"),
      ));
      lis.add(const SizedBox(height: 20));
    } else {
      selectedAudio = "";
    }

    lis.add(ElevatedButton(
      onPressed: () {
        setState(() {
          responseFuture = startDownload();
          myController.text = "";
          downLoadState = "initiated";
          loadingMessage = "Download Starting..";
        });
      },
      child: Text(downLoadState),
    ));

    return lis;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Media Video Downloader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Instagram|TikTok|Youtube|FaceBook|Reddit',
                style: TextStyle(
                  fontSize: 22,
                  foreground: Paint()
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 1
                    ..color = Colors.blue[700]!,
                )),
            const SizedBox(height: 50),
            TextFormField(
              controller: myController,
              decoration: const InputDecoration(labelText: 'Enter URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (responseFuture != null) {
                    responseFuture!.timeout(const Duration(seconds: 0),
                        onTimeout: () => "timeout");
                  }
                  responseFuture = responseStatus(myController.text);
                  loadingMessage = "Finding downlaodable files";
                });
              },
              child: const Text('Show Result'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<dynamic>(
              future: responseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      CircularProgressIndicator(
                          semanticsLabel: loadingMessage,
                          value:
                              (snapshot.data is double) ? snapshot.data : null),
                      const SizedBox(height: 10),
                      Text(loadingMessage!),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData && downLoadState != "lol") {
                  return AlertDialog(
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: genDropDown(),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(0xff, 0xcf, 0xcf, 0xcf),
    );
  }
}
