import 'package:flutter/material.dart';
import 'dart:io';

import '../models/color.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../global.dart' as global;

class BackgroundPicker extends StatefulWidget {
  const BackgroundPicker({Key? key, required this.trackIndex})
      : super(key: key);
  final int trackIndex;

  @override
  State<BackgroundPicker> createState() => _BackgroundPickerState();
}

class _BackgroundPickerState extends State<BackgroundPicker> {
  List<PickerFile> _fileList = [];
  final String _startPath = '/storage/emulated/0';
  final List<String> _prevPathStack = [];
  late String _currentPath;

  @override
  void initState() {
    super.initState();
    setFileList(_startPath);
  }

  void setFileList(String dirPath) async {
    _fileList = [];
    Directory selectedDirectory = Directory(dirPath);
    List<FileSystemEntity> selectedDirectoryFile =
        selectedDirectory.listSync(recursive: false);
    for (FileSystemEntity file in selectedDirectoryFile) {
      String path = file.path;
      bool isDirectory = FileSystemEntity.isDirectorySync(path);
      String extension = path.split('.').last;
      if (isDirectory ||
          global.backgroundAllowedExtensions.contains(extension)) {
        String name = path.split('/').last;
        _fileList.add(PickerFile(
          name: name,
          path: path,
          extension: extension,
          isDirectory: isDirectory,
        ));
      }
    }
    _fileList.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return b.isDirectory.toString().compareTo(a.isDirectory.toString());
      } else {
        return a.name.compareTo(b.name);
      }
    });
    _currentPath = dirPath;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        backgroundColor: ColorPalette.darkWine,
        leading: ButtonFactory.iconButton(
          icon: const Icon(Icons.arrow_back),
          iconColor: ColorPalette.lightGrey,
          outline: false,
          onPressed: _prevPathStack.isNotEmpty
              ? () {
                  setFileList(_prevPathStack.removeLast());
                }
              : null,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: _fileList.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      _prevPathStack.add(_currentPath);
                      if (_fileList[index].isDirectory) {
                        setFileList(_fileList[index].path);
                      } else {
                        Navigator.pop(context, _fileList[index].path);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: _fileList[index].isDirectory
                              ? const Card(
                                  color: ColorPalette.darkGrey,
                                  child: Center(
                                    child: Icon(
                                      Icons.folder,
                                      size: 40.0,
                                      color: ColorPalette.lightGrey,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: FileImage(
                                          File(_fileList[index].path)),
                                    ),
                                  ),
                                ),
                        ),
                        TextFactory.text(_fileList[index].name,
                            fontSize: 10, color: ColorPalette.white),
                      ],
                    ),
                  );
                },
              ),
            ),
            ButtonFactory.textButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                text: 'cancel',
                fontSize: 24),
          ],
        ),
      ),
    );
  }
}

class PickerFile {
  PickerFile(
      {required this.name,
      required this.path,
      required this.extension,
      required this.isDirectory});
  final String name;
  final String path;
  final String extension;
  final bool isDirectory;
}
