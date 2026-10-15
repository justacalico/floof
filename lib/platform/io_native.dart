import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> documentsDir() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  } on MissingPluginException {
    return Directory.systemTemp.path;
  }
}

bool fileExists(String path) => File(path).existsSync();

Future<String?> copyPhoto(String sourcePath, String destDir) async {
  final dir = Directory(destDir);
  await dir.create(recursive: true);
  final dot = sourcePath.lastIndexOf('.');
  final ext = dot >= 0 ? sourcePath.substring(dot) : '';
  final dest =
      '${dir.path}/done_${DateTime.now().millisecondsSinceEpoch}$ext';
  await File(sourcePath).copy(dest);
  return dest;
}

Widget photoWidget(String path) => Image.file(
      File(path),
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.flag_outlined, color: Colors.amber),
    );
