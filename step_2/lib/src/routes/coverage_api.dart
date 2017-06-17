import 'dart:convert';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import '../models/repo.dart';

final Directory CLONE_DIR = new Directory('.cloned');

final Validator COVERAGE_API_REQUEST = new Validator({
  'git_url*': [
    isNonEmptyString,
    isNot(anyOf(startsWith('..'), startsWith('/')))
  ],
  'test_script*': isNonEmptyString
});

/// Attaches our /api/coverage route.
AngelConfigurer attachCoverageApi() {
  return (Angel app) async {
    app
        // Transform our validator into a middleware that ensures
        // our main handler (the function below) will only ever
        // see valid, safe-to-process data.
        .chain(validate(COVERAGE_API_REQUEST))
        // Respond to a POST request to /api/coverage only.
        .post('/api/coverage', (RequestContext req, Logger logger) async {
      String gitUrl = req.body['git_url'], testScript = req.body['test_script'];
      var repoName = p.basenameWithoutExtension(gitUrl);

      // Create our .cloned dir if it doesn't exist
      if (!await CLONE_DIR.exists()) await CLONE_DIR.create(recursive: true);

      // Start `git`, and stream output to the logger.
      logger.fine('Cloning $gitUrl...');
      var git = await Process.start('git', ['clone', '--depth', '1', gitUrl],
          workingDirectory: CLONE_DIR.absolute.path);
      git
        ..stdout.transform(UTF8.decoder).listen(logger.fine)
        ..stderr.transform(UTF8.decoder).listen(logger.warning);

      // Wait for Git to quit. If it takes more than minute, give up.
      var exitCode = await git.exitCode
          .timeout(new Duration(minutes: 1), onTimeout: () => -1);

      if (exitCode != 0) {
        // If git failed, let's tell the user we couldn't run coverage...
        throw new AngelHttpException.notProcessable(
            message: 'Git with exit code $exitCode while cloning $gitUrl.');
      }

      // If we succeeded, let's get a reference to the cloned repo's root.
      var clonedRepo = new Directory.fromUri(CLONE_DIR.uri.resolve(repoName));

      // 
    });
  };
}
