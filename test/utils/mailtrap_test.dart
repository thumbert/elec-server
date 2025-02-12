import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/src/utils/mailtrap.dart';

void main() async {
  dotenv.load('.env/prod.env');

  final to = dotenv.env['EMAIL_SUPPORT']!;
  final from = dotenv.env['EMAIL_FROM']!;
  final subject = 'Hello';
  final body = 'Break the ice!';

  var res = await sendEmail(to: [to], from: from, subject: subject, body: body);
  print(res.statusCode);
  print(res.body);
}
