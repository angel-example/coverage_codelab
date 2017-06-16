library dartcov;

import 'dart:async';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'src/services/repo.dart' as repo;

/// Generates and configures an Angel server.
Future<Angel> createServer() async {
  var app = new Angel();

  // Loads app configuration from 'config/'.
  // It supports loading from YAML files, and also supports loading a `.env` file.
  //
  // https://github.com/angel-dart/configuration
  await app.configure(loadConfigurationFile());

  // All loaded configuration will be added to `app.properties`.
  print('Loaded configuration: ${app.properties}');

  // Run the plug-in that attaches our `/api/repos` service.
  await app.configure(repo.configureServer());

  // This is a simple route.
  //
  // Read more about routing and request handling:
  // * https://github.com/angel-dart/angel/wiki/Basic-Routing
  // * https://github.com/angel-dart/angel/wiki/Requests-&-Responses
  // * https://github.com/angel-dart/angel/wiki/Request-Lifecycle
  app.get('/greet/:name', (String name) => 'Hello, $name!');

  // Sets up a static server (with caching support).
  // Defaults to serving out of 'web/'.
  // In production mode, it'll try to serve out of `build/web/`.
  //
  // https://github.com/angel-dart/static
  await app.configure(new CachingVirtualDirectory());

  // Routes in `app.after` will only run if the request was not terminated by a prior handler.
  // Usually, this is a situation in which you'll want to throw a 404 error.
  // On 404's, let's redirect the user to a pretty error page.
  app.after.add((req) {
    print('wtf: ${req.uri}');
    return true;
  });
  app.after.add((ResponseContext res) => res.redirect('/not-found.html'));

  // Enable GZIP and DEFLATE compression (conserves bandwidth)
  // https://github.com/angel-dart/compress
  app.responseFinalizers.addAll([gzip(), deflate()]);

  // Logs requests and errors to both console, and a file named `log.txt`.
  // https://github.com/angel-dart/diagnostics
  await app.configure(logRequests(new File('log.txt')));

  return app;
}
