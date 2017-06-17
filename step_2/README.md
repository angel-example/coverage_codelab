# Step 2 - Base API, Validation, and Client Skeleton
In this step, we will move further:
* We'll set up an API to compute coverage of a remote Git repo
* We create a validation schema and apply it to user input
* We write a minimal Web client that accesses our API

## Contents
* [Coverage API](#coverage-api)
  * [Request Bodies](#request-bodies)
  * [Validating User Input](#validating-user-input)
  * [Collecting Coverage](#collecting-coverage)]
  * [Sending a Response](#sending-a-response)
* [Proxying `pub serve`](#reverse-proxy)
* [Web Client](#web-client)
* [Up Next...](#up-next)

## Coverage API
We currently have most of our application's routes (other than `lib/src/services/repo.dart`)
in one file, `lib/dartcov.dart`. The next route we will add is rather lengthy, and has
nothing to do with the general-purpose routes we have thusfar defined, so let's put it in
its own file. Create a file called `lib/src/routes/coverage_api.dart`. The name of the file
is unimportant, but make sure it has this content:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import '../models/repo.dart';

AngelConfigurer attachCoverageApi() {
  return (Angel app) async {
    app.post('/api/coverage', (RequestContext req) async {
      // TODO: Add code here...
    });
  };
}
```

This function returns an `AngelConfigurer`, a Dart typedef that represents an Angel
*plug-in*. As mentioned earlier, plug-ins let you attach new functionality to a server
instance. We can use them to separate unrelated routes. This will keep our codebase clean,
and save us quite a few headaches.

While we technically could have just defined `attachCoverageApi` as a single function that
accepts `Angel app` as its only input, the convention for Angel plug-ins is to take the form
of a pure function, or a class (preferably a function). This way, additional parameters can be
passed to the outer function, and Angel only has to worry about executing the inner functionality. Hooray for organization!

The call to `app.post` registers a single route. When users request a page from our application,
Angel combines the appropriate routes into a linear chain of request handlers. A *request handler* in Angel
is an abstract concept: it just refers to a way to respond to a request. All Dart objects (functions included)
are request handlers. Depending on what kind of object a request handler is, Angel will treat it differently.
In this case, though, we are just using a function that takes a `RequestContext` as its only parameter.

You can read more here:
* https://github.com/angel-dart/angel/wiki/Basic-Routing
* https://github.com/angel-dart/angel/wiki/Requests-&-Responses

A route's path (in this case `/api/coverage`) lets you specify when to run specific functionality.
By calling `app.post('/api/coverage', ...)`, we are effectively that we only want our function to be
executed only when all of the following conditions are true:
* The request's HTTP method is `POST`
* The user is requesting the URI `/api/coverage` (trailing and leading slashes are ignored)

We'll want to clone all repositories into a common parent directory. Let's use a folder named
`.cloned`:

```dart
final Directory CLONE_DIR = new Directory('.cloned');

/// Attaches our /api/coverage route.
AngelConfigurer attachCoverageApi() {
  return (Angel app) async {
      // ...
  }
```

### Request Bodies
For this API, we expect the user to do the following to compute coverage for a repository:
1. Send a `POST` request to `/api/coverage`.
2. The request body must contain the URL of the Git repository.
3. The request body must also contain the relative path of the test script to run. This must not
start with `/` or `..`, as it would then be an absolute path, or reference files outside
of the directory on the system (security risk). Ex. `test/all_test.dart`.

On the server, we will clone the provided repository, and then collect coverage on it by
invoking the Dart executable and pointing it to the test script.
Technically, this is insecure, as the script is not run in any type of sandbox. However,
sandboxing is far outside of the scope of this codelab.

We'll need to obtain the Git URL and test script from the request body. Angel can parse
bodies of the following content types out-of-the-box.
* `application/json`
* `application/x-www-form-urlencoded`
* `multipart/form-data`

Other content types can be hacked in as well, but that also is out of the scope this codelab.
To access the request body, we can access `req.body`. Assign two variables to the values of
data parsed from the request body:

```dart
app.post('/api/coverage', (RequestContext req) async {
    String gitUrl = req.body['git_url'], testScript = req.body['test_script'];
});
```

### Validating User Input
At this point, our API has some holes that could potentially cause a
`500 Internal Server Error`, or open our server up to attack from malicious users. We cannot
afford to leave any security flaws unfixed!

The most obvious security holes here can be patched up with a little validation.

`package:angel_validate` provides a cross-platform solution for data validation. Use it to ensure
the integrity of *all* data that touches your server. In general, we should never trust user input.

Validation schemas are defined via the `Validator` class, and are powered by `package:matcher`,
which also is the engine that drives Dart's official `package:test` library.

Right above our `attachCoverageApi` function, let's define a validator for our `/api/coverage` endpoint:

```dart
final Validator COVERAGE_API_REQUEST = new Validator({
  'git_url*': [
    isNonEmptyString,
    isNot(anyOf(startsWith('..'), startsWith('/')))
  ],
  'test_script*': isNonEmptyString
});
```

This schema declares the following:
1. Both `git_url` and `test_script` must be present (they are required inputs). This is denoted by the
asterisk (`*`).
2. Both `git_url` and `test_script` must be strings, **AND** they must not be empty.
3. `git_url` cannot start with `..`, and it also cannot start with `/`.


We can obtain a `ValidationResult` on arbitrary data by calling `COVERAGE_API_REQUEST.check(...)`.
If validation succeeds, then it will spit out valid data only. Extraneous keys will be omitted.

For example, if the user sent valid input, but also sent `foo=bar&evil=malicious_code`, the output
data would only contain `git_url` and `test_script`. The reason for this is the "never trust user input!"
principle.

If you don't want to bother with a `ValidationResult`, you can call `COVERAGE_API_REQUEST.enforce(...)`,
which will either return validated data, or throw an exception immediately.

Read more here:
* https://github.com/angel-dart/validate

On the server-side, we can transform validators into middleware that filter the request body.
If the data is invalid, then a `400 Bad Request` error will be thrown. If the data *is* valid,
then `req.body` will be cleaned and only contain `git_url` and `test_script`.

Invoke the function `validate(...)` to transform a validator into an Angel middleware. Then, we can
use `app.chain(...)` to attach it to a single route, or to a group of routes. Check this out:

```dart
app.chain(validate(COVERAGE_API_REQUEST)).post('/api/coverage',
    (RequestContext req) async {
    String gitUrl = req.body['git_url'], testScript = req.body['test_script'];
});
```

There are other ways to define middleware, but `app.chain(...)` is the easiest. With this new
set-up, request bodies are *always* validated against `COVERAGE_API_REQUEST` before being sent
to our function. Thus, our main request handler will only ever see valid data.

The [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns) principle really is a blessing when it comes to writing servers.
Now our business logic is separate from our validation logic, and the two *never have to be mixed*. Ever.

### Collecting Coverage
Now, let's actually write the logic to clone a repo, and collect coverage.

First, let's edit our request handler to also accept a `Logger` as an input.
Angel's dependency injection will automatically provide us with an instance.
In a later section of this codelab, we will go into depth on how Angel's dependency injection system works.
For now, just know the `Logger` passed to our request handler will print nicely to our console in color,
and to a file named `log.txt`.

```dart
app.chain(validate(COVERAGE_API_REQUEST)).post('/api/coverage',
    (RequestContext req, Logger logger) async {
    String gitUrl = req.body['git_url'], testScript = req.body['test_script'];
});
```

Next, we'll want to clone the desired repository in our `.cloned` directory.
We use `Process.start` to call `git`, and we stream its output to the injected
`Logger`:

```dart
```

### Sending a Response
Lastly, let's create an instance of `Repo` describing the results of the
coverage computation, and send it to the user:

```dart
```

We don't have serialize the `Repo` before sending it; Angel will automatically
serialize it to JSON and send it to the user (you can override this if necessary).
Later in this codelab, we'll set our project up to automatically add serialization
code that improves our API response time.

# Up Next
