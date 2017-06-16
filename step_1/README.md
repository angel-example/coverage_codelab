# Step 1 - Project Setup
In this step, we install our dependencies, create our application
skeleton, and define our model classes.

## Contents
* [Initializing a Project](#initializing-a-project)
* [Dependencies](#dependencies)
* [Models and Services](#models)
* [Wire it Up](#wire-it-up)
* [Up Next...](#up-next)

# Initializing a Project
This codelab assumes that you have the
[Dart SDK](https://dartlang.org) installed.

We will use a tool called the [Angel CLI](https://github.com/angel-dart/cli) to scaffold our application,
so let's install it:

```bash
pub global activate angel_cli
```

Let's use the newly-installed `angel` executable to create a project called `dartcov`:

```bash
# Creates a directory named 'dartcov' and clones an application template.
angel init dartcov
```

When prompted, choose `Light (Minimal starting point for new users)`.

## Dependencies
Now, head over to the `dartcov` directory, and take a peek at the `pubspec.yaml` file:

```yaml
description: "An easily-extensible web server framework in Dart."
homepage: "https://github.com/angel-dart/angel"
name: "dartcov"
publish_to: "none"
dependencies: 
  angel_common: "^1.0.0"
dev_dependencies: 
  angel_hot: "^1.0.0"
  angel_test: "^1.0.0"
  test: "^0.12.0"
environment: 
  sdk: ">=1.19.0"
```

There are three Angel-specific Dart packages installed:
* `package:angel_common` - This is a master package that bundles together the most commonly-used Angel functionality,
such as a static server, a reverse proxy, and response compression.
* `package:angel_hot` - This is one of the newer features in the Angel framework. It exposes a `HotReloader` class
that hot-reloads our server on file changes in development. The boilerplate we cloned already contains logic to use this
functionality.
* `package:angel_test` - This package includes several testing helpers that make unit-testing Angel applications using
`package:test` much easier.

Let's add a few more dependencies:
```yaml
dependencies:
  angel_file_service: ^1.0.0
  coverage: ^0.7.2
  lcov: ^1.0.0
dev_dependencies:
  browser: ^0.10.0
  dart_to_js_script_rewriter: ^1.0.0
transformers:
  - dart_to_js_script_rewriter
```
We use `package:browser` and `dart_to_js_script_rewriter` to point users'
browsers to the correct URL of our main client-side Dart script.

`package:coverage` and `package:lcov` will be used to collect and parse
code coverage from the Dart VM.

`package:angel_file_service` provides a `JsonFileService` class that we
can use to persist data generated in our application to a JSON file
on disk. In real life, you'd want to use a database, but for the sake of
the tutorial, we won't assume the reader has any specific database
installed on their system. Consider adding the following your
`.gitignore`:

```gitignore
# Ignore generated JSON databases
*_db.json
```

Now, run `pub get` to install copies of these libraries to your
project.

## Models
In this early stage of our application, we'll only have one model class,
and a very simple one at that: `Repo`. This model will represent the URL of a Git
repository, the relative path to a test script, an integer representing the number of lines covered, and a boolean value representing whether coverage has been collected yet for
the repository.

Let's use the Angel CLI to generate both a model class and a
[service](https://github.com/angel-dart/angel/wiki/Service-Basics) file:

```bash
angel service
```

When prompted for the name of the service, type `Repo`. Next, choose `In-memory File Service`.
Finally, choose `Yes` when asked to create a `TypedService`.

We'll see three new files:
* `lib/src/services/repo.dart` - Configures our application to interact with a JSON database stored in a file named `repos_db.json`.
* `lib/src/models/repo.dart` - A model class named `Repo`.
* `lib/src/models/models.dart` - Exports all model files. In this case, just `repo.dart`.

First, let's modify the model file to reflect on our earlier specification. Open
`lib/src/services/repo.dart` and change it to the following:

```dart
library dartcov.models.repo;

import 'package:angel_framework/common.dart';

class Repo extends Model {
  @override
  String id;

  String gitUrl, testScript;

  int linesCovered;

  bool coverageHasBeenCollected;

  @override
  DateTime createdAt, updatedAt;

  Repo(
      {this.id,
      this.gitUrl,
      this.testScript,
      this.linesCovered: -1,
      this.coverageHasBeenCollected: false,
      this.createdAt,
      this.updatedAt});
}
```

Next, let's take a look at our generated service file. For now, we won't need to change it.
Open `lib/src/services/repo.dart`:

```dart
import 'package:angel_common/angel_common.dart';
import 'dart:io';
import 'package:angel_file_service/angel_file_service.dart';
import '../models/repo.dart';
export '../models/repo.dart';

AngelConfigurer configureServer() {
  return (Angel app) async {
    app.use('/api/repos',
        new TypedService<Repo>(new JsonFileService(new File('repos_db.json'))));
  };
}
```

`configureServer` is a function that returns an `AngelConfigurer`, otherwise known as
an Angel [plug-in](https://github.com/angel-dart/angel/wiki/Using-Plug-ins). Angel is
extremely extensible, and plug-ins can be used to add additional functionality to any
application instance.

In this case, we create a `JsonFileService` that reads and writes JSON data within a file
called `repos_db.json`. Then, we wrap it within a `TypedService`, which uses reflection
to serialize and deserialize data into instances of `Repo`. At a later stage in this lab,
we will remove the `TypedService` to improve application performance, and replace it
with something else.

Lastly, we mount the service at the path `/api/repos`. The effect of this is that
Angel creates a REST API rooted at `/api/repos` that queries our `TypedService` (which
in turn queries our `JsonFileService`).

Read more here:
* https://github.com/angel-dart/angel/wiki/Service-Basics
* https://medium.com/the-angel-framework/instant-rest-apis-and-more-an-introduction-to-angel-services-b843f3187f67

## Wire It Up

However, if we run the server now, visiting `/api/repos` will throw a 404. This
is because we haven't run the `configureServer` plug-in! Fortunately, it only takes
one call to do this. Open `lib/dartcov.dart`.

First, import our `repo.dart` file:

```dart
import 'src/services/repo.dart` as repo;
```

Next, in the `createServer` function, right under the `print` call, add a call
to `app.configure`:

```dart
Future<Angel> createServer() async {
  /// Generates and configures an Angel server.
  var app = new Angel();

  // Loads app configuration from 'config/'.
  // It supports loading from YAML files, and also supports loading a `.env` file.
  //
  // https://github.com/angel-dart/configuration
  await app.configure(loadConfigurationFile());

  // All loaded configuration will be added to `app.properties`.
  print('Loaded configuration: ${app.properties}');

  /**
   * HERE IS THE CODE WE ADD:
   */

  // Run the plug-in that attaches our `/api/repos` service.
  await app.configure(repo.configureServer());

  /**
   * The code that follows has been omitted...
   */
}
```

Now, all we need to do is start our server. Pass the `--observe` flag to the Dart VM
to enable hot reloading:

```bash
dart --observe bin/server.dart
```

We've got a server up and running that will auto-reload on file changes.
Visit the following pages:
* http://localhost:3000 - Basic landing page.
* http://localhost:3000/api/repos - Prints JSON. This is our REST API!
* http://localhost:3000/non-existent - Should redirect you to a "Not Found" page.

# Up Next
Congratulations! You've just initialized an Angel project, generated model files,
and even added a REST API to it! Feel empowered?

Move on [Step 2](../step2/README.md), where we start writing some actual business logic.