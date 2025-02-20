import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/src/utils/mailtrap.dart';
import 'package:test/test.dart';

Future<void> tests() async {
  final to = Email(dotenv.env['EMAIL_SUPPORT']!);
  final from = Email(dotenv.env['EMAIL_FROM']!);
  final subject = 'Hello';

  test('simple email', () async {
    final body = 'Break the ice!';
    var res = await sendEmail(
        to: [to], from: from, subject: subject, body: body, isHtml: false);
    print(res.statusCode);
    print(res.body);
  });
}

void main() async {
  dotenv.load('.env/prod.env');
  await tests();
}
