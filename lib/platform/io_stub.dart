// coverage:ignore-file
import 'package:flutter/material.dart';

Future<String> documentsDir() async => '';

bool fileExists(String path) => false;

Future<String?> copyPhoto(String sourcePath, String destDir) async => null;

Widget photoWidget(String path) =>
    const Icon(Icons.flag_outlined, color: Colors.amber);
