import 'dart:convert';
import 'dart:io' show Directory, File, Process, Platform;
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// Create a typst document from the sms-backup xml file
/// [xmlFile] is the output of the sms-backup application
void makeTypstDocument(File xmlFile, {required Directory outputDirectory}) {
  var doc = XmlDocument.parse(xmlFile.readAsStringSync());
  var texts = doc
      .getElement('smses')!
      .children
      .whereType<XmlElement>()
      .take(700)
      .map((node) => Message.fromXml(node))
      .toList();
  texts.sortBy((Message m) => m.time);
  for (var msg in texts) {
    print(msg);
  }
}

// https://www.synctech.com.au/sms-backup-restore/view-backup/
// https://www.synctech.com.au/sms-backup-restore/fields-in-xml-backup-files/
class Message {
  Message(this.time, this.author, this.content);

  DateTime time;
  String author; // type = 1 is other, = 2 is me
  String content;
  List<File> attachments = [];

  static late String dir;
  static final fmt = DateFormat('dMMM, HH:mm');

  /// There are two types of messages, sms and mms.
  static Message fromXml(XmlNode xml) {
    if (xml is XmlElement && xml.name.local == 'mms') {
      return _parseMms(xml);
    } else if (xml is XmlElement && xml.name.local == 'sms') {
      return _parseSms(xml);
    } else {
      throw 'Unknown message type';
    }
  }

  static Message _parseMms(XmlNode xml) {
    List<XmlAttribute> attrs = xml.attributes;
    late String author;
    late DateTime time;
    late String content;
    List<File> attachments = [];

    for (XmlAttribute a in attrs) {
      if (a.name.toString() == 'date') {
        time = DateTime.fromMicrosecondsSinceEpoch(
          1000 * int.parse(a.value),
        );
      }
      if (a.name.toString() == 'contact_name') {
        author = a.value.split(' ').first;
      }
    }

    var parts = xml.getElement('parts');
    if (parts != null) {
      for (XmlNode part in parts.children) {
        if (part is! XmlElement) {
          continue;
        }
        final ct = part.getAttribute('ct')!;
        print('MMS part with content type: $ct');
        // check part type
        if (ct == 'audio/mpeg') {
          final filename =
              '$dir/assets/mms_${time.millisecondsSinceEpoch}_${part.getAttribute('cl')!}';
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'data') {
              String base64 = a.value;
              List<int> bytes = base64Decode(base64);
              final file = File(filename);
              file.writeAsBytesSync(bytes);
              attachments.add(file);
              content = '[Audio saved to $filename]'; // append to content
            }
          }
        } else if (ct == 'text/plain') {
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'text') {
              content = a.value.replaceAll('&#10;', '\n');
            }
          }
        } else if (ct == 'image/png') {
          // get the part sequence
          var seq = int.parse(part.getAttribute('seq')!);
          // save the content to a png file, with the timestamp of the message
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'data') {
              String base64 = a.value;
              List<int> bytes = base64Decode(base64);
              final filename =
                  '$dir/assets/mms_${time.millisecondsSinceEpoch}_$seq.png';
              final file = File(filename);
              file.writeAsBytesSync(bytes);
              attachments.add(file);
              content = '[Image saved to $filename]'; // append to content
            }
          }
        } else if (ct == 'image/jpeg') {
          // get the part sequence
          var seq = int.parse(part.getAttribute('seq')!);
          // save the content to a jpeg file, with the timestamp of the message
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'data') {
              String base64 = a.value;
              List<int> bytes = base64Decode(base64);
              final filename =
                  '$dir/assets/mms_${time.millisecondsSinceEpoch}_$seq.jpeg';
              final file = File(filename);
              file.writeAsBytesSync(bytes);
              attachments.add(file);
              content = '[Image saved to $filename]'; // append to content
            }
          }
        } else if (ct == 'application/pdf') {
          final filename = '$dir/assets/${part.getAttribute('cl')!}';
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'data') {
              String base64 = a.value;
              List<int> bytes = base64Decode(base64);
              final file = File(filename);
              file.writeAsBytesSync(bytes);
              attachments.add(file);
              content = '[PDF saved to $filename]'; // append to content
            }
          }
        } else if (ct == 'application/smil') {
          // ignore smil parts
        } else if (ct == 'image/heic') {
          final filename = '$dir/assets/${part.getAttribute('name')!}';
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'data') {
              String base64 = a.value;
              List<int> bytes = base64Decode(base64);
              final file = File(filename);
              file.writeAsBytesSync(bytes);
              attachments.add(file);
              content = '[Image saved to $filename]'; // append to content
              // convert to webp which can be used by typst
              // magick IMG_6771.heic -quality 85 IMG_6771.webp
              Process.runSync(
                  'magick',
                  [
                    filename,
                    '-quality',
                    '85',
                    filename.replaceAll('.heic', '.webp'),
                  ],
                  runInShell: true);
              Process.runSync('rm', [filename], runInShell: true);
            }
          }
        } else if (ct == 'video/mp4') {
          final filename =
              '$dir/assets/mms_${time.millisecondsSinceEpoch}_${part.getAttribute('name')!}';
          for (XmlAttribute a in part.attributes) {
            if (a.name.toString() == 'data') {
              String base64 = a.value;
              List<int> bytes = base64Decode(base64);
              final file = File(filename);
              file.writeAsBytesSync(bytes);
              attachments.add(file);
              content = '[Audio saved to $filename]'; // append to content
            }
          }
        } else {
          // Need to deal with heic images here.  Install imagemagick with heic support
          // https://dev.to/harizinside/installing-imagemagick-from-source-with-heic-support-2p8
          throw 'Unknown mms part type';
        }
      }
    }

    return Message(time, author, content)..attachments = attachments;
  }

  static Message _parseSms(XmlNode xml) {
    List<XmlAttribute> attrs = xml.attributes;
    late String author;
    late DateTime time;
    late String content;

    for (XmlAttribute a in attrs) {
      if (a.name.toString() == 'date') {
        time = DateTime.fromMicrosecondsSinceEpoch(
          1000 * int.parse(a.value),
        );
      }
      if (a.name.toString() == 'body') content = a.value;
      if (a.name.toString() == 'type') {
        if (a.value == '1') author = 'Eylia';
        if (a.value == '2') author = 'Adrian';
      }
    }

    return Message(time, author, content);
  }

  @override
  String toString() =>
      '{"time": $time, "author": $author, "content": $content}';
}

String makeEntry(Message msg) {
  if (msg.author == 'Adrian') {
    return '''
#text(fill: white)[
  #block(
    fill: blue,
    radius: 8pt,
    inset: 8pt,
    breakable: false,
  )[
    Hey — you free tonight? Thought we could
    check out that new taco place on 8th.
    #v(-6pt)
    #align(right)[ #text(0.8em, fill: luma(250))[09:12] ]
  ]
  #v(-24pt)
  #block(
    radius: 999pt,
    inset: 4pt,
  )[
    #text(1.15em)[😊]
  ]
]
''';
  }
  final timeStr = Message.fmt.format(msg.time);
  final authorStr = msg.author;
  final contentStr = msg.content.replaceAll('\n', ' ');
  return '$timeStr - $authorStr: $contentStr';
}


// Need to install exiftool to read mp3, mp4 metadata
//   sudo apt install exiftool
void main() {
  final home = Platform.environment['HOME']!;
  final file = File('$home/Downloads/sms-20251215113039.xml');
  final outputDir = Directory('$home/Downloads/texts');
  Message.dir = outputDir.path;
  makeTypstDocument(file, outputDirectory: outputDir);
}
