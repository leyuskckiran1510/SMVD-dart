import 'dart:async';

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
  Map urlDatas={};
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
      urlDatas={};
      Map urls = await parser.Parse().linkGen(url);
      print("(responseStatus) Link Parsing Completed ... ");
      print("${urls['urls']['videos'][0]}");
      if (urls.containsKey("urls")) {
        urlDatas = urls["urls"];
        downLoadState = 'Downlaod';
        selectedVideo = urlDatas["videos"][0]['url'] ;
        selectedAudio = urlDatas["audios"][0]['url'] ;
        print("${urlDatas}");
      }
      else if(urls.containsKey("error")) {
        urlDatas = {
          "videos": [
            {"url": ".", "quality": "${urlDatas['error']}"},
          ],
          "audios": [
            {"url": "audio1", "quality": "${urlDatas['error']}"},
          ],
        };
      }
    }
    catch (e) {
      return "Error $e";
    }
    return "Sucess";
  }

  Future<String> startDownload() async {
    try
    {
      if(selectedVideo != null && selectedVideo!.isNotEmpty){
        print("(startDownload) Starting Video Download.. for $selectedVideo \n\t [+] ${urlDatas["title"]}");
        await parser.Run().download("${urlDatas["title"]}.mp4", selectedVideo!);
        print("(startDownload) Video Downloade Complete ..");
        selectedVideo = "";
      }
      if(selectedAudio != null && selectedAudio!.isNotEmpty){
        print("(startDownload) Starting Audio Download.. for $selectedAudio");
        await parser.Run().download("${urlDatas["title"]}.mp3", selectedAudio!);
        print("(startDownload) Audio Downloade Complete ..");
        selectedAudio = "";

      }
      else{
        print("(startDownload) No Url selected..");
      }
      urlDatas={};
      return "Sucess";
    }
    catch (e) {
      print("(startDownload) Got A error $e");
      urlDatas={};
      return "Error $e";
    }
  }

  List<DropdownMenuItem<String>> genDropDownItems(String dataKey){
      List<DropdownMenuItem<String>> items =[];
    List<dynamic> visited = [];
    for (var elems in urlDatas[dataKey]) {
        if(!visited.contains(elems['url'])){
            visited.add(elems['url']);
            print("( $dataKey DropDown )Making Drop Down for ${elems['url']} and ${elems['quality']}");
            items.add(DropdownMenuItem<String>(
                value: elems['url'],
                child: Text(elems['quality']),
              ));
        }
              
    }
    items.add(const DropdownMenuItem<String>(value: 'empty',child:Text('empty')));

    return items;
  }



  List<Widget> genDropDown() {
    List<Widget> lis = [];
    if (urlDatas["videos"] != null && urlDatas["videos"].isNotEmpty) {
      lis.add(DropdownButton<String>(
        value: selectedVideo,
        hint: const Text('Select Video'),
        onChanged: (String? newValue) {
          setState(() {
            selectedVideo = newValue;
          });
        },
        items: genDropDownItems("videos"),
      )
      );
      lis.add(const SizedBox(height: 20));
    }
    if (urlDatas["audios"] != null && urlDatas["audios"].isNotEmpty) {
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
    }
    lis.add(ElevatedButton(
      onPressed: () {
        setState(() {
          responseFuture = startDownload();
          myController.text = "";
          downLoadState = "lol";
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
                } else if (snapshot.hasData && downLoadState!="lol") {
                  return AlertDialog(
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: genDropDown(),
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
