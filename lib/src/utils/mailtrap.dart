import 'dart:convert';

import 'package:http/http.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

extension type Email(String email) {}

enum Disposition {
  inline,
  attachment;

  @override
  String toString() {
    return switch (this) {
      Disposition.inline => 'inline',
      Disposition.attachment => 'attachment',
    };
  }
}

class Attachment {
  Attachment({
    required this.contentBase64,
    required this.filename,
    this.disposition = Disposition.attachment,
    this.mimeType,
    this.contentId,
  });

  final String contentBase64;

  /// MIME type of the content you are ataching, e.g. 'text/plain' or 'text/html'
  final String? mimeType;

  /// The attachment's filename
  final String filename;

  /// The attachment's content-disposition, specifying how you would like the
  /// attachment to be displayed. For example, “inline” results in the attached
  /// file are displayed automatically within the message while “attachment”
  /// results in the attached file require some action to be taken before it
  /// is displayed, such as opening or downloading the file.
  final Disposition disposition;

  /// The attachment's content ID. This is used when the disposition is
  /// set to “inline” and the attachment is an image, allowing the file
  /// to be displayed within the body of your email.
  final String? contentId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'content': contentBase64,
      'filename': filename,
      if (disposition != Disposition.attachment)
        'disposition': disposition.toString(),
      if (contentId != null) 'content_id': contentId, 
    };
  }
}

Future<Response> sendEmail(
    {required List<Email> to,
    required Email from,
    required String subject,
    required String body,
    required bool isHtml,
    List<Email>? cc,
    List<Email>? bcc,
    Email? replyTo,
    List<Attachment>? attachments}) async {
  final client = Client();
  final apiUrl = Uri.parse("https://send.api.mailtrap.io/api/send");
  final apiKey = dotenv.env['MAILTRAP_API_KEY']!;

  final message = json.encode({
    'from': {'email': from},
    'to': to.map((e) => {'email': e}).toList(),
    'subject': subject,
    if (isHtml) 'html': body,
    if (!isHtml) 'text': body,
  });

  final response = await client.post(apiUrl,
      headers: {'Content-Type': 'application/json', 'Api-Token': apiKey},
      body: message);

  return response;
}
