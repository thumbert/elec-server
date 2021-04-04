library utils.env;

class Env {
  final String mongoConnection;
  final String rootUrl;

  const Env._internal({this.mongoConnection, this.rootUrl});

  factory Env.parse(String x) {
    if (x.toLowerCase() == 'prod') {
      return prod;
    } else {
      throw ArgumentError('Unsupported env name: $x');
    }
  }

  static const prod = Env._internal(
    mongoConnection: '127.0.0.1:27017',
    rootUrl: 'http://127.0.0.1:8080',
  );


}