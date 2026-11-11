import 'dart:io';

const _base = 'https://raw.githubusercontent.com/openmaptiles/fonts/master/noto-sans';

final _files = <String, String>{
  'NotoSans-Regular.ttf': '$_base/NotoSans-Regular.ttf',
  'NotoSans-Medium.ttf': '$_base/NotoSans-Medium.ttf',
  'NotoSans-SemiBold.ttf': '$_base/NotoSans-SemiBold.ttf',
  'NotoSans-Bold.ttf': '$_base/NotoSans-Bold.ttf',
};

bool _isTtf(List<int> bytes) {
  if (bytes.length < 4) return false;
  // TrueType: 0x00010000, OpenType/CFF: 'OTTO'
  return (bytes[0] == 0 && bytes[1] == 0x01 && bytes[2] == 0 && bytes[3] == 0) ||
      (bytes[0] == 0x4f && bytes[1] == 0x54 && bytes[2] == 0x54 && bytes[3] == 0x4f);
}

Future<void> main() async {
  final dir = Directory('assets/fonts');
  await dir.create(recursive: true);
  final client = HttpClient();
  for (final name in _files.keys) {
    final url = _files[name]!;
    final file = File('${dir.path}/$name');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      stderr.writeln('$name: status=${response.statusCode} size=${bytes.length} '
          'isTtf=${_isTtf(bytes)} firstBytes=${bytes.take(4)}');
      if (response.statusCode == 200 && _isTtf(bytes)) {
        await file.writeAsBytes(bytes);
        stderr.writeln('  SAVED $name');
      } else {
        stderr.writeln('  SKIPPED $name (not a valid TTF or not found)');
      }
    } catch (e) {
      stderr.writeln('$name: ERROR $e');
    }
  }
  client.close();
}
