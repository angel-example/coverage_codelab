# coverage_codelab
[![The Angel Framework](https://angel-dart.github.io/images/logo.png)](https://angel-dart.github.io)

Learn how to build an end-to-end application using Angel on the server and client. 

[Watch the companion video on Youtube]().

By the end, you'll be an expert in using:
* The Angel CLI
* WebSockets
* Angel's task engine
* Services
* Authentication
* And much more...

# Premise
The goal of this codelab is to build an application that can collect code
coverage from Dart projects, and display badges
(i.e. ![version: v1.0.0](https://img.shields.io/badge/pub-v1.0.0-brightgreen.svg))
on-demand. Its name is `dartcov`.

In the first stages, the functionality is basic, but eventually we branch
into running labor-intensive operations in separate worker isolates, and
using WebSockets to update users in real-time, rather than keeping them
waiting on an arbitrarily-long AJAX request.

We also authenticate via Github, and run our `dartcov` service as a continuous integration software.

Multithreading is also covered, in addition to using Angel together with
`pub serve` and the Dart development compiler (`ddc`) to create a
highly-productive full-stack development experience.

# Organization
Building this application is a lengthy process, and would be too overwhelming to consume all at once.
Thus, this repo is split into multiple steps, each with its own corresponding directory. Each directory
contains a detailed `README.md` file to guide you, and all code is thoroughly commented to explain its
function, and to also link to corresponding documentation.

# Feedback
Feedback is more than welcome. If you have any questions or comments about the content of this codelab,
either contact @thosakwe or leave an issue in this repo.