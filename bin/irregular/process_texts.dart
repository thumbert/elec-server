import 'dart:convert';
import 'dart:io' show Directory, File, Process, Platform;
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:logging/logging.dart';

/// Create a typst document from the sms-backup xml file
/// [xmlFile] is the output of the sms-backup application
void makeTypstDocument(File xmlFile, {required Directory outputDirectory}) {
  var doc = XmlDocument.parse(xmlFile.readAsStringSync());
  var texts = doc
      .getElement('smses')!
      .children
      .whereType<XmlElement>()
      .map((node) => Message.fromXml(node))
      .toList();
  texts.sortBy((Message m) => m.time);

  // add the reactions to the previous message
  texts = attachReactions(texts.toList());

  // remove duplicates (some photos appear multiple times)
  texts = texts.toSet().toList();

  var buffer = StringBuffer();
  buffer.writeln(header);
  for (var msg in texts) {
    print(msg);
    buffer.writeln(makeEntry(msg));
  }
  File('${outputDirectory.path}/texts.typ')
      .writeAsStringSync(buffer.toString());
}

/// Find reactions in the messages and attach them to the previous message.
/// There are some invisible characters in the content that need to be removed
/// to match the reaction to the correct message.  These characters are \u200A and \u200B, which are zero-width space and zero-width non-breaking space, respectively.
List<Message> attachReactions(List<Message> messages) {
  var out = <Message>[];
  final regexp = RegExp(' to “(.+?)”');
  String normalize(String s) => s.replaceAll(RegExp(r'[\u200A\u200B]'), '');
  for (var i = 0; i < messages.length; i++) {
    var msg = messages[i];
    if (regexp.hasMatch(msg.content)) {
      var match = regexp.firstMatch(msg.content);
      if (match != null) {
        var reaction = msg.content.substring(0, match.start);
        var reactedContent = match.group(1)!;
        // find the previous message with the same content
        var previousMsg = out.lastWhereOrNull(
            (m) => normalize(m.content) == normalize(reactedContent));
        print(reactedContent == out[6].content);
        if (previousMsg != null) {
          previousMsg.reaction = reaction;
          continue; // there's only one reaction to a message
        }
      }
    } else {
      out.add(msg);
    }
  }

  return out;
}

// https://www.synctech.com.au/sms-backup-restore/view-backup/
// https://www.synctech.com.au/sms-backup-restore/fields-in-xml-backup-files/
class Message {
  Message(this.time, this.authorFirstName, this.content);

  DateTime time;
  String authorFirstName;
  String content;
  Set<File> attachments = {};
  String? reaction;

  static late String dir;
  static final fmt = DateFormat('HH:mm');

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
    late String authorFirstName;
    late DateTime time;
    late String content;
    Set<File> attachments = {};

    for (XmlAttribute a in attrs) {
      if (a.name.toString() == 'date') {
        time = DateTime.fromMicrosecondsSinceEpoch(
          1000 * int.parse(a.value),
        );
      }
      if (a.name.toString() == 'msg_box') {
        if (a.value == '1') {
          authorFirstName = 'Eylia';
        } else if (a.value == '2') {
          authorFirstName = 'Adrian';
        } else {
          throw 'Unknown mms msg_box type';
        }
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
              content = sanitizeContent(a.value);
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
              var convertedFile = File(filename.replaceAll('.heic', '.webp'));
              attachments.add(convertedFile);
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

    return Message(time, authorFirstName, content)..attachments = attachments;
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
      if (a.name.toString() == 'body') content = sanitizeContent(a.value);
      if (a.name.toString() == 'type') {
        if (a.value == '1') {
          author = 'Eylia';
        } else if (a.value == '2') {
          author = 'Adrian';
        } else {
          throw 'Unknown sms type';
        }
      }
    }

    return Message(time, author, content);
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'author': authorFirstName,
        'content': content,
        'attachments': attachments.map((a) => a.path).toList(),
        'reaction': reaction,
      };

  @override
  String toString() => toJson().toString();

  @override
  bool operator ==(Object other) =>
      other is Message &&
      time == other.time &&
      authorFirstName == other.authorFirstName &&
      content == other.content &&
      // SetEquality().equals(attachments, other.attachments) &&
      reaction == other.reaction;

  @override
  int get hashCode =>
      time.hashCode ^
      authorFirstName.hashCode ^
      content.hashCode ^
      // SetEquality().hash(attachments) ^
      (reaction?.hashCode ?? 0);
}

String sanitizeContent(String content) {
  return content
      .replaceAll('*', '\\*')
      .replaceAll('@', '\\@')
      .replaceAll('\$', '\\\$')
      .replaceAll('&#10;', '\n');
}

/// Create the typst entry for a message.
///
String makeEntry(Message msg) {
  var out = '';
  if (DateTime(msg.time.year, msg.time.month, msg.time.day) != currentDate) {
    currentDate = DateTime(msg.time.year, msg.time.month, msg.time.day);
    out =
        '#text(fill: gray, baseline: 6pt)[${DateFormat.EEEE().format(currentDate)} · ${DateFormat.yMMMMd('en_US').format(currentDate)}]\n';
  }
  var reaction = makeReaction(msg);

  if (msg.authorFirstName == 'Adrian') {
    if (msg.attachments.isEmpty) {
      out = '''$out
#text(fill: white)[
  #block(
    fill: blue,
    radius: 8pt,
    inset: 8pt,
    breakable: false,
    width: 85%,
  )[
    ${msg.content}
    #v(-4pt)
    #align(right)[ #text(0.8em, fill: luma(250))[${Message.fmt.format(msg.time)}] ]
  ]
]
$reaction
''';
    } else {
      var attachmentsStr = makeAttachments(msg.attachments.toList());
      out = '''$out
#text(fill: white)[
  #block(
    fill: blue,
    radius: 8pt,
    inset: 8pt,
    breakable: false,
    width: 85%,
  )[
    $attachmentsStr
    #v(-4pt)
    #align(right)[ #text(0.8em, fill: luma(250))[${Message.fmt.format(msg.time)}] ]
  ]
]
$reaction
''';
    }
  } else if (msg.authorFirstName == 'Eylia') {
    if (msg.attachments.isEmpty) {
      out = '''$out
#align(right)[
  #block(
    fill: luma(230),
    radius: 8pt,
    inset: 8pt,
    breakable: false,
    width: 85%,
  )[
    #align(left)[
      ${msg.content}
    ]
    #v(-4pt)
    #text(0.8em, fill: luma(100))[${Message.fmt.format(msg.time)}]
  ]
$reaction
]
''';
    } else {
      var attachmentsStr = makeAttachments(msg.attachments.toList());
      out = '''$out
#align(right)[
  #block(
    fill: luma(230),
    radius: 8pt,
    inset: 8pt,
    breakable: false,
    width: 85%,
  )[
    #align(left)[
      $attachmentsStr
    ]
    #v(-4pt)
    #text(0.8em, fill: luma(100))[${Message.fmt.format(msg.time)}]
  ]
$reaction
]
''';
    }
  } else {
    throw 'Unknown author';
  }
  return out;
}

String makeAttachments(List<File> attachments) {
  if (attachments.isEmpty) {
    return '';
  }
  return attachments.map((a) {
    if (a.path.endsWith('.mp3') || a.path.endsWith('.mp4')) {
      return a.path;
    } else {
      return '#image("assets/${a.path.split('/').last}", width: 85%)';
    }
  }).join('\n#v(4pt)\n');
}

String makeReaction(Message msg) {
  if (msg.reaction == null) {
    return '';
  }
  if (msg.authorFirstName == 'Adrian') {
    return '''
#v(-20pt)
#align(right)[
  #block(
    radius: 999pt,
    inset: 4pt,
    width: 25%,
  )[
    #align(left)[#text(1.15em)[ ​${msg.reaction!}]]
  ]
]
''';
  } else if (msg.authorFirstName == 'Eylia') {
    return '''
  #v(-20pt)
  #block(
      radius: 999pt,
      inset: 4pt,
      width: 83%,
  )[
      #align(left)[ #text(1.15em)[​${msg.reaction!}]]
  ]
''';
  } else {
    throw 'Unknown author';
  }
}

const String header = '''
#set page(paper: "us-letter")
#set page(columns: 2)
#set text(font: ("Noto Sans", "Noto Color Emoji"), size: 9pt)
#set page(margin: (top: 2cm, bottom: 2cm, left: 1.5cm, right: 1.5cm))

#place(
  top + center,
  float: true,
  scope: "parent",
  clearance: 30pt,
  dy: 100pt,
)[
    #text(8em, weight: "bold", font: "Tangerine")[First steps]
    #block(width: 60%)[
        #text[The unauthorized release of the early texts between Lady Eylia and her errant knight, Adrian, chronicling their budding romance through dance classes and weekend walks]
    ]
    #image("assets/front_page.png", width: 50%)
]

#set columns(gutter: 24pt)
#set page(background: line(angle: 90deg, length: 87%, stroke: 0.2pt + luma(200)))
#set page(numbering: "1")
#counter(page).update(1)
''';

DateTime currentDate = DateTime(2020);

// Need to install exiftool to read mp3, mp4 metadata
//   sudo apt install exiftool
void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  final logger = Logger('texts');

  final home = Platform.environment['HOME']!;
  final file =
      File('$home/Downloads/Archive/typst/texts/sms-20251215113039.xml');
  final outputDir = Directory('$home/Downloads/Archive/typst/texts');
  Message.dir = outputDir.path;

  makeTypstDocument(file, outputDirectory: outputDir);
  logger.info('Typst file created at ${outputDir.path}/texts.typ');
}

// void processXmlFile(File xmlFile) {
//   var doc = XmlDocument.parse(xmlFile.readAsStringSync());
//   var texts = doc
//       .getElement('smses')!
//       .children
//       .whereType<XmlElement>()
//       .take(700)
//       .map((node) => Message.fromXml(node))
//       .toList();
//   texts.sortBy((Message m) => m.time);
//   for (var msg in texts) {
//     print(msg);
//   }
// }
