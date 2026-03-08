import 'dart:io';

void main() {
  final directory = Directory('lib');
  final files = directory.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('package:tkd_brackets/')) {
      content = content.replaceAll('package:tkd_brackets/', 'package:bracket_generator/');
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
