import 'dart:io';
import 'package:dartcov/dartcov.dart';
import 'package:angel_common/angel_common.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = await createServer();
    client = await connectTo(app);
  });

  tearDown(() async {
    await client.close();
    app = null;
  });

  test('index via REST', () async {
    var response = await client.get('/api/repos');
    expect(response, hasStatus(HttpStatus.OK));
  });

  test('Index repos', () async {
    var repos = await client.service('api/repos').index();
    print(repos);
  });
}