import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<Response> sendEmail(
    {required List<String> to,
    required String from,
    required String subject,
    required String body,
    List<String>? cc,
    List<File>? attachments}) async {
  final client = Client();
  final apiUrl = Uri.parse("https://send.api.mailtrap.io/api/send");
  final apiKey = dotenv.env['MAILTRAP_API_KEY']!;

  final message = json.encode({
    'from': {'email': from},
    'to': to.map((e) => {'email': e}).toList(),
    'subject': subject,
    'text': body,
  });

  final response = await client.post(apiUrl,
      headers: {'Content-Type': 'application/json', 'Api-Token': apiKey},
      body: message);

  return response;
}
