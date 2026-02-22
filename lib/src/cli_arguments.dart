// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:charcode/charcode.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:string_scanner/string_scanner.dart';

/// CLI arguments parsed from a `executableAndArgs` string.
class CliArguments {
  /// Parses [argString], a shell-style string of space-separated arguments,
  /// into a list of separate arguments.
  ///
  /// If [glob] is `true`, this will parse arguments (outside of quotes) as
  /// [Glob]s and resolve those globs when [arguments] is called. It defaults to
  /// `false` on Windows, since the Windows convention is to let each program
  /// handle its own glob expansion.
  ///
  /// Throws a [FormatException] if [argString] is malformed.
  factory CliArguments.parse(String argString, {bool? glob}) {
    glob ??= !Platform.isWindows;

    final scanner = StringScanner(argString);

    _consumeSpaces(scanner);
    if (scanner.isDone) scanner.error('Expected at least one argument.');

    final executable = _scanArg(scanner, glob: false)._plain;
    _consumeSpaces(scanner);

    final args = <_Argument>[];
    while (!scanner.isDone) {
      args.add(_scanArg(scanner, glob: glob));
      _consumeSpaces(scanner);
    }

    return CliArguments._(executable, args);
  }

  CliArguments._(this.executable, this._arguments);

  /// The executable to run.
  final String executable;

  /// The arguments to the executable, with globs not yet resolved.
  final List<_Argument> _arguments;

  /// Consumes zero or more spaces.
  static void _consumeSpaces(StringScanner scanner) {
    while (scanner.scanChar($space)) {}
  }

  /// Scans a single argument.
  static _Argument _scanArg(StringScanner scanner, {required bool glob}) {
    final plainBuffer = StringBuffer();
    final globBuffer = glob ? StringBuffer() : null;
    var isGlobActive = false;
    while (true) {
      final next = scanner.peekChar();
      if (next == $space || next == null) {
        final glob = isGlobActive ? globBuffer?.toString() : null;
        return _Argument(plainBuffer.toString(), glob == null ? null : Glob(glob));
      } else if (next == $double_quote || next == $single_quote) {
        scanner.readChar();

        final text = _scanUntil(scanner, next);
        plainBuffer.write(text);
        globBuffer?.write(Glob.quote(text));

        scanner.readChar();
      } else if (next == $backslash) {
        scanner.readChar();
        final char = scanner.readChar();
        plainBuffer.writeCharCode(char);

        globBuffer?.writeCharCode($backslash);
        globBuffer?.writeCharCode(char);
      } else {
        final char = scanner.readChar();
        plainBuffer.writeCharCode(char);
        globBuffer?.writeCharCode(char);
        isGlobActive =
            glob &&
            (isGlobActive ||
                char == $asterisk ||
                char == $question ||
                char == $lbracket ||
                char == $lbrace ||
                char == $lparen);
      }
    }
  }

  /// Scans text until the scanner reaches [endChar].
  ///
  /// Does not consume [endChar]. Throws a [FormatException] if the string ends
  /// before an [endChar] is found.
  static String _scanUntil(StringScanner scanner, int endChar) {
    final buffer = StringBuffer();
    while (true) {
      final next = scanner.peekChar();
      if (next == null) {
        scanner.expectChar(endChar);
      } else if (next == endChar) {
        return buffer.toString();
      } else if (next == $backslash) {
        scanner.readChar();
        buffer.writeCharCode(scanner.readChar());
      } else {
        buffer.writeCharCode(scanner.readChar());
      }
    }
  }

  /// Returns the arguments to pass to the executable.
  ///
  /// If the arguments include [Glob]s, they will be resolved to concrete file
  /// paths (relative to [root], which defaults to the current directory) before
  /// being returned.
  Future<List<String>> arguments({String? root}) async => [
    for (final argument in _arguments) ...await argument.resolve(root: root),
  ];
}

/// An argument parsed from a `executableAndArgs` string.
class _Argument {
  _Argument(this._plain, this._glob);

  /// The plain text of the argument, to be used if globbing is disabled or if
  /// [_glob] matches no files.
  final String _plain;

  /// The glob for the argument.
  ///
  /// If this is non-`null`, the files it matches are used as the arguments in
  /// place of [_plain]. If it matches no files, [_plain] is used instead.
  final Glob? _glob;

  /// Returns the files matched by this argument's [Glob] if it has one and if
  /// it matches at least one file, or the plain argument string otherwise.
  ///
  /// The [root] is used as the root directory of the glob.
  Future<List<String>> resolve({String? root}) async {
    final glob = _glob;
    if (glob != null) {
      final absolute = p.isAbsolute(glob.pattern);
      final globbed = [
        await for (final entity in glob.list(root: root)) absolute ? entity.path : p.relative(entity.path, from: root),
      ];
      if (globbed.isNotEmpty) return globbed;
    }
    return [_plain];
  }
}

/// Converts [argument] to a string and escapes it so it's parsed as a single
/// argument with no glob expansion by [Script] and related functions.
///
/// For example, `run("cp -r ${arg(source)} build/")`.
String arg(Object argument) {
  final string = argument.toString();
  if (string.isEmpty) return '""';

  final buffer = StringBuffer();
  for (var i = 0; i < string.length; i++) {
    final codeUnit = string.codeUnitAt(i);
    if (codeUnit == $space ||
        codeUnit == $double_quote ||
        codeUnit == $single_quote ||
        codeUnit == $backslash ||
        codeUnit == $asterisk ||
        codeUnit == $question ||
        codeUnit == $lbracket ||
        codeUnit == $rbracket ||
        codeUnit == $lbrace ||
        codeUnit == $rbrace ||
        codeUnit == $lparen ||
        codeUnit == $rparen ||
        codeUnit == $comma) {
      buffer.writeCharCode($backslash);
    }
    buffer.writeCharCode(codeUnit);
  }
  return buffer.toString();
}

/// Converts all elements of [arguments] to strings and escapes them so they're
/// parsed as separate arguments with no glob expansion by [Script] and
/// related functions.
///
/// For example, `run("cp -r ${args(directories)} build/")`.
String args(Iterable<Object> arguments) => arguments.map(arg).join(' ');
