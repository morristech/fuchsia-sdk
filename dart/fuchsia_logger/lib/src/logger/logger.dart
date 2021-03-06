// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';

import '../internal/_log_writer.dart';

const _warningMessage =
    '\n========================== WARNING ================================\n'
    '| log called before setupLogger() was called.                     |\n'
    '| All log message will still be sent to the fuchsia system logger |\n'
    '| but some log messages may be missed if they were emitted by     |\n'
    '| third_party libraries. To avoid this make sure you call         |\n'
    '| setupLogger() in your main method before any other calls.       |\n'
    '===================================================================\n';

/// The logger instance in which logs will be written.
///
/// This logger will connect to the Fuchsia system logger when running
/// on a Fuchsia device and will write to stdout when not.
/// When running on a Fuchsia device logs can be viewed by running
/// `fx syslog`.
Logger log = () {
  _connectToLogWriterIfNeeded();
  print(_warningMessage);

  return Logger.root;
}();

LogWriter _logWriter;

/// Sets up the default logger for the current Dart application.
///
/// Every Dart application should call this [setupLogger] function in their main
/// before calling the actual log statements.
///
/// The provided [name] will be used for displaying the scope, and this name
/// will default to the last segment (i.e. basename) of the application url.
///
/// If [level] is provided, only the log messages of which level is greater than
/// equal to the provided [level] will be shown. If not provided, it defaults to
/// [Level.INFO].
///
/// If [globalTags] is provided, these tags will be added to each message logged
/// via this logger.
///
/// By default, the caller code location is automatically added in checked mode
/// and not in production mode, because it is relatively expensive to calculate
/// the code location. If [forceShowCodeLocation] is set to true, the location
/// will be added in production mode as well.
void setupLogger({
  String name,
  Level level,
  List<String> globalTags,
  bool forceShowCodeLocation,
}) {
  // set the log variable to the root logger and set the level to that
  // specified by level. We do this so subsequent calls to the log method
  // will not run the default setup method.
  log = Logger.root..level = level ?? Level.INFO;

  // connect to the logger writer here. If log has already been called this
  // method will be a noop. At this point, _logWriter will not be null
  _connectToLogWriterIfNeeded();

  // We need to provide a name for the logger in the form of a tag because
  // we are not using hierarchical logging.
  final loggerName = name ??
      Platform.script?.pathSegments?.lastWhere((_) => true, orElse: () => '');

  // Tags get appended to each log statement. We put the name, if present
  // as the first tag so it makes it easier to identify.
  final List<String> tags = (loggerName.isNotEmpty ? [name] : [])
    ..addAll(globalTags ?? const []);

  bool inCheckedMode = false;
  assert(() {
    inCheckedMode = true;
    return true;
  }());

  _logWriter
    ..globalTags = tags
    ..forceShowCodeLocation = forceShowCodeLocation ?? inCheckedMode;
}

void _connectToLogWriterIfNeeded({
  String name,
  Level level,
}) {
  if (_logWriter != null) {
    // we have already connected so there is nothing we need to do
    return;
  }

  if (Platform.isFuchsia) {
    // _logWriter = FuchsiaLogWriter(logger: Logger.root);
    // TODO(MS-2257) connect to fuchsia logger when implemented.
    _logWriter = StdoutLogWriter(logger: Logger.root);
  } else {
    _logWriter = StdoutLogWriter(logger: Logger.root);
  }
}
