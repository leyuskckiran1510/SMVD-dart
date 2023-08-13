import 'package:flutter/material.dart';
import 'parser.dart' as parser;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Leyuskc Video Downloader',
      home: MyCustomForm(),
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
  Future<String>? responseFuture;
  String downLoadState = "Error";
  Map data = {
    "videos": [
      {"url": "", "quality": "Failed TO Parse"},
    ],
    "audios": [
      {"url": "audio1", "quality": "high"},
    ],
  };
  String? selectedVideo;
  String? selectedAudio;

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  Future<String> responseStatus(String url) async {
    try{
        print("(responseStatus) Staring Link Parsing... ");
        Map urls = await parser.Parse().linkGen(url);
        print("(responseStatus) Link Parsing Completed ... ");
        if(!data.containsKey("error")){
            data = urls["urls"];
            downLoadState = 'Downlaod';
        }
        else{
            data = {
            "videos": [
             {"url": ".", "quality": "${data['error']}"},
                ],
             "audios": [
                {"url": "audio1", "quality": "${data['error']}"},
    ],
  };
        }
    }
    catch(e){
        return "Error $e";
    }
    return "Sucess";
  }

  Future<String> startDownload() async{
    try{
        print("(startDownload) Stating Video Download..");
        await parser.Run().download("video.mp4",selectedVideo!);
        print("(startDownload) Video Downloade Complete ..");
        print("(startDownload) Stating Audio Download..");
        await parser.Run().download("audio.mp4",selectedAudio!);
        print("(startDownload) Audio Downloade Complete ..");
        return "Sucess";
    }
    catch(e){
        return "Error $e";
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Screen Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: myController,
              decoration: const InputDecoration(labelText: 'Enter URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  responseFuture = responseStatus(myController.text);
                });
              },
              child: const Text('Show Result'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: responseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return AlertDialog(
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        DropdownButton<String>(
                          value: selectedVideo,
                          hint: const Text('Select Video'),
                          onChanged: (String? newValue){
                            setState(() {
                              selectedVideo = newValue;
                            });
                          },
                          items: data['videos']
                              .map<DropdownMenuItem<String>>(
                                (dynamic video) =>
                                    DropdownMenuItem<String>(
                                  value: video['url'],
                                  child: Text(video['quality']),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        DropdownButton<String>(
                          value: selectedAudio,
                          hint: const Text('Select Audio'),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedAudio = newValue;
                            });
                          },
                          items: data['audios']
                              .map<DropdownMenuItem<String>>(
                                (dynamic audio) =>
                                    DropdownMenuItem<String>(
                                  value: audio['url'],
                                  child: Text(audio['quality']),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height:20),
                        ElevatedButton(
                            onPressed: () {
                                setState(() {
                                  responseFuture = startDownload();
                                });
                            },
                            child: Text(downLoadState),
                        )
                      ],
                    ),
                  );
                } else {
                  return Container(); // Placeholder when no data or error
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
