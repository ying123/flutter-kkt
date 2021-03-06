import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;

class FilePage extends StatefulWidget {
  FilePage({Key key}) : super(key: key);

  @override
  _FilePageState createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  GlobalKey _globalKey = GlobalKey();
  int _counter;

  @override
  void initState() {
    super.initState();
    PermissionHandler().requestPermissions(<PermissionGroup>[
      PermissionGroup.storage, // 在这里添加需要的权限
    ]);

    _readCounter().then((int value) {
      setState(() {
        _counter = value;
      });
    });
  }

  Future<File> _getLocalFile() async {
    // get the path to the document directory.
    String dir = (await getApplicationDocumentsDirectory()).path;
    return new File('$dir/counter.txt');
  }

  Future<int> _readCounter() async {
    try {
      File file = await _getLocalFile();
      // read the variable as a string from the file.
      String contents = await file.readAsString();
      return int.parse(contents);
    } on FileSystemException {
      return 0;
    }
  }

  Future<Null> _incrementCounter() async {
    setState(() {
      _counter++;
    });
    // write the variable as a string to the file
    await (await _getLocalFile()).writeAsString('$_counter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("保存文件"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.red,
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 15),
              child: RaisedButton(
                onPressed: _saveScreen,
                child: Text("保存页面图片到相册"),
              ),
              width: 200,
              height: 44,
            ),
            Container(
              padding: EdgeInsets.only(top: 15),
              child: RaisedButton(
                onPressed: _getHttp,
                child: Text("保存网络图片到相册"),
              ),
              width: 200,
              height: 44,
            ),
            Container(
              padding: EdgeInsets.only(top: 15),
              child: RaisedButton(
                onPressed: _saveVideo,
                child: Text("保存网络视频到相册"),
              ),
              width: 200,
              height: 44,
            ),
            Container(
              child: new Center(
                child: new Text(
                    'Button tapped $_counter time${_counter == 1 ? '' : 's'}.'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }

  _saveScreen() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final result =
        await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
    print(result);
  }

  _getHttp() async {
    var response = await Dio().get(
        "https://ss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=a62e824376d98d1069d40a31113eb807/838ba61ea8d3fd1fc9c7b6853a4e251f94ca5f46.jpg",
        options: Options(responseType: ResponseType.bytes));
    final result =
        await ImageGallerySaver.saveImage(Uint8List.fromList(response.data));
    print(result);
  }

  _saveVideo() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.mp4";
    await Dio().download(
        "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4", savePath);
    final result = await ImageGallerySaver.saveFile(savePath);
    print(result);
  }
}
