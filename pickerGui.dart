import 'dart:io';

import 'package:flutter/material.dart';

import 'file_picker.dart';

class FilePicker extends StatelessWidget {
  final String fileNameToSave;
  final void Function(String selectedFile) onFileSelected;

  FilePicker(
      {Key? key, this.fileNameToSave = "test", required this.onFileSelected})
      : super(key: key);
  @override
  Widget build(BuildContext cntxt) {
    return MaterialApp(
      title: "FilePicker",
      home: Picker(
          fileNameToSave: fileNameToSave, onFileSelected: onFileSelected),
    );
  }
}

class Picker extends StatefulWidget {
  final String fileNameToSave;
  final void Function(String selectedFile) onFileSelected;

  Picker({required this.fileNameToSave, required this.onFileSelected});

  @override
  State<Picker> createState() {
    return _Picker(
        fileNameToSave: fileNameToSave, onFileSelected: onFileSelected);
  }
}

class _Picker extends State<Picker> {
  FilePath current = FilePath(FilePath.home(), []);
  Future<String>? responseFuture;
  List<Widget> widgets = [];
  final String fileNameToSave;
  final void Function(String selectedFile) onFileSelected;

  _Picker({required this.fileNameToSave, required this.onFileSelected}) {
    responseFuture = current.list();
    print(current);
    print(current.dirlist);
  }

  List<Widget> folders() {
    widgets = [
      Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
              child: ElevatedButton(
            onPressed: () => {
              setState(() => {
                    print("To Home $current"),
                    current = FilePath(FilePath.home(), []),
                    responseFuture = current.list(),
                    folders()
                  })
            },
            child: Text("Home"),
          )),
          Flexible(
              child: ElevatedButton(
            onPressed: () => {
              setState(() => {
                    current.previous(),
                    responseFuture = current.list(),
                    folders()
                  })
            },
            child: Text("Previous"),
          )),
          Flexible(child: Text("$current")),
          Flexible(
              child: ElevatedButton(
            onPressed: () {
              setState(() {
                current.back();
                responseFuture = current.list();
              });
            },
            child: Text("Back"),
          )),
          Flexible(
              child: ElevatedButton(
            onPressed: () => {
              setState(() => {
                    current.selected(fileNameToSave),
                    print("Selected $current"),
                    print("Downlaoding Toooo  $current $fileNameToSave"),
                    onFileSelected(current.choice),
                  })
            },
            child: Text("Select"),
          ))
        ],
      )
    ];
    current.dirlist
        .sort((a, b) => b.path.toString().compareTo(a.path.toString()));
    current.dirlist.sort((a, b) {
      if (a is File && b is File) {
        return 0;
      } else if (a is File && b is Directory) {
        return 1;
      }
      return -1;
    });
    for (var lis in current.dirlist) {
      Color getColor(Set<MaterialState> states) {
        const Set<MaterialState> interactiveStates = <MaterialState>{
          MaterialState.pressed,
          MaterialState.hovered,
          MaterialState.focused,
        };
        if (states.any(interactiveStates.contains)) {
          return Colors.red;
        }
        if (lis is Directory) {
          return Colors.blue;
        } else {
          return Colors.blueGrey;
        }
      }

      widgets.add(ElevatedButton(
          onPressed: () {
            setState(() {
              if (lis is Directory) {
                current.follow(
                    lis.uri.pathSegments.lastWhere((x) => x.length > 1));
              } else {
                current.selected(
                    lis.uri.pathSegments.lastWhere((x) => x.length > 1));
                print("Downlaoding Toooo  $current");
                onFileSelected(current.choice);
              }
              print("Pressd and Got this $current");
              responseFuture = current.list();
              folders();
            });
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith(getColor)),
          child: Text(lis.uri.pathSegments.lastWhere((x) => x.length > 1))));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('FilePicker'),
        ),
        body: Center(
          child: FutureBuilder<String>(
            future: responseFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                folders();
                return (CustomScrollView(slivers: [
                  SliverFixedExtentList(
                    itemExtent: 50.0,
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return widgets[index];
                      },
                      childCount: widgets.length,
                    ),
                  )
                ]));
              } else {
                return Container();
              }
            },
          ),
        ));
  }
}
