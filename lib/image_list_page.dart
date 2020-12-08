import 'dart:io';

import 'package:flutter/material.dart';

class ImageListPage extends StatelessWidget {
  final List<String> imagePath;

  ImageListPage({this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: childList(),
      ),
    );
  }

  List<Widget> childList() {
    return imagePath?.map((e) {
      return ListTile(
        leading: Image(
          image: FileImage(File(e)),
        ),
        title: Text(e),
      );
    })?.toList();
  }
}
