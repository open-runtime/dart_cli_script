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

import 'package:cli_script/src/cli_arguments.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('parsing', () {
    group('throws an error', () {
      test('for an empty string', () {
        expect(() => CliArguments.parse(''), throwsFormatException);
      });

      test('for a string containing only spaces', () {
        expect(() => CliArguments.parse('   '), throwsFormatException);
      });

      onPosixOrWithGlobTrue((glob) {
        test('for a string containing an invalid glob', () {
          expect(() => CliArguments.parse('a [', glob: glob), throwsFormatException);
        });
      });
    });

    group('a single argument', () {
      group('without quotes containing', () {
        test('normal text', () async {
          expect(await _resolve('foo'), equals(['foo']));
        });

        test('text surrounded by spaces', () async {
          expect(await _resolve('  foo    '), equals(['foo']));
        });

        test('an escaped backslash', () async {
          expect(await _resolve(r'\\'), equals([r'\']));
        });

        test('an escaped single quote', () async {
          expect(await _resolve(r"\'"), equals(["'"]));
        });

        test('an escaped double quote', () async {
          expect(await _resolve(r'\"'), equals(['"']));
        });

        test('an escaped normal letter', () async {
          expect(await _resolve(r'\a'), equals(['a']));
        });
      });

      group('with double quotes containing', () {
        test('nothing', () async {
          expect(await _resolve('""'), equals(['']));
        });

        test('spaces', () async {
          expect(await _resolve('" foo bar "'), equals([' foo bar ']));
        });

        test('a single quote', () async {
          expect(await _resolve('"\'"'), equals(["'"]));
        });

        test('an escaped double quote', () async {
          expect(await _resolve(r'"\""'), equals(['"']));
        });

        test('an escaped backslash', () async {
          expect(await _resolve(r'"\\"'), equals([r'\']));
        });
      });

      group('with single quotes containing', () {
        test('nothing', () async {
          expect(await _resolve("''"), equals(['']));
        });

        test('spaces', () async {
          expect(await _resolve("' foo bar '"), equals([' foo bar ']));
        });

        test('a double quote', () async {
          expect(await _resolve("'\"'"), equals(['"']));
        });

        test('an escaped single quote', () async {
          expect(await _resolve(r"'\''"), equals(["'"]));
        });

        test('an escaped backslash', () async {
          expect(await _resolve(r"'\\'"), equals([r'\']));
        });
      });

      test('with plain text adjacent to quotes', () async {
        expect(await _resolve("\"foo bar\"baz'bip bop'"), equals(['foo barbazbip bop']));
      });

      onWindowsOrWithGlobFalse((glob) {
        test("that's an invalid glob", () async {
          expect(await _resolve('a [', glob: glob), equals(['a', '[']));
        });
      });
    });

    group('multiple arguments', () {
      test('separated by single spaces', () async {
        expect(await _resolve('a b c d'), equals(['a', 'b', 'c', 'd']));
      });

      test('separated by multiple spaces', () async {
        expect(await _resolve('a  b   c    d  '), equals(['a', 'b', 'c', 'd']));
      });

      test('with different quoting styles', () async {
        expect(await _resolve("a \"b c\" 'd e' f\\ g"), equals(['a', 'b c', 'd e', 'f g']));
      });
    });
  });

  group('globbing', () {
    onPosixOrWithGlobTrue((glob) {
      test('lists files that match the glob', () async {
        await d.file('foo.txt').create();
        await d.file('bar.txt').create();
        await d.file('baz.zip').create();

        final args = await _resolve('ls *.txt', glob: glob);
        expect(args.first, equals('ls'));
        expect(args.sublist(1), unorderedEquals(['foo.txt', 'bar.txt']));
      });

      test('an absolute glob expands to absolute paths', () async {
        await d.file('foo.txt').create();
        await d.file('bar.txt').create();
        await d.file('baz.zip').create();

        final base = d.sandbox.replaceAll(Platform.pathSeparator, '/');
        final pattern = '${Glob.quote(base)}/*.txt';
        final args = await _resolve('ls $pattern', glob: glob);
        expect(args.first, equals('ls'));
        expect(args.sublist(1), unorderedEquals([d.path('foo.txt'), d.path('bar.txt')]));
      });

      test('ignores glob characters in quotes', () async {
        await d.file('foo.txt').create();
        await d.file('bar.txt').create();
        await d.file('baz.zip').create();
        expect(await _resolve("ls '*.txt'", glob: glob), equals(['ls', '*.txt']));
      });

      test('ignores backslash-escaped glob characters', () async {
        await d.file('foo.txt').create();
        await d.file('bar.txt').create();
        await d.file('baz.zip').create();
        expect(await _resolve(r'ls \*.txt', glob: glob), equals(['ls', '*.txt']));
      });

      test("returns plain strings for globs that don't match", () async {
        expect(await _resolve('ls *.txt', glob: glob), equals(['ls', '*.txt']));
      });

      test('absolute glob output uses platform path separators', () async {
        await d.file('foo.txt').create();
        await d.file('bar.txt').create();

        final base = d.sandbox.replaceAll(Platform.pathSeparator, '/');
        final pattern = '${Glob.quote(base)}/*.txt';
        final args = await _resolve('ls $pattern', glob: glob);
        expect(args.first, equals('ls'));
        for (final path in args.sublist(1)) {
          expect(path, matches(Platform.isWindows ? RegExp(r'^(?:[A-Za-z]:[\\/]|\\\\|//|[\\/])') : RegExp(r'^/')));
        }
        expect(args.sublist(1), unorderedEquals([d.path('foo.txt'), d.path('bar.txt')]));
      });
    });

    group('Windows-specific glob patterns', () {
      group('UNC-style absolute glob', () {
        test('returns plain pattern when UNC path does not match', () async {
          await d.file('foo.txt').create();
          const uncPattern = r'\\nonexistent\share\*.txt';
          final args = await _resolve('ls $uncPattern', glob: true);
          expect(args.first, equals('ls'));
          expect(args.sublist(1), equals([uncPattern]));
          expect(args.sublist(1).single, startsWith(r'\\'));
        }, testOn: 'windows');

        test('//server/share form returns plain pattern when no match', () async {
          await d.file('foo.txt').create();
          const uncPattern = '//server/share/*.txt';
          final args = await _resolve('ls $uncPattern', glob: true);
          expect(args.first, equals('ls'));
          expect(args.sublist(1), equals([uncPattern]));
          expect(args.sublist(1).single, startsWith('//'));
        }, testOn: 'windows');
      });

      group('drive-relative glob pattern', () {
        test('C:foo\\*.txt returns plain pattern when no match', () async {
          await d.file('foo.txt').create();
          const pattern = r'C:foo\*.txt';
          final args = await _resolve('ls $pattern', glob: true);
          expect(args.first, equals('ls'));
          expect(args.sublist(1), equals([pattern]));
        }, testOn: 'windows');

        test('C:foo/*.txt returns plain pattern when no match', () async {
          await d.file('foo.txt').create();
          const pattern = 'C:foo/*.txt';
          final args = await _resolve('ls $pattern', glob: true);
          expect(args.first, equals('ls'));
          expect(args.sublist(1), equals([pattern]));
        }, testOn: 'windows');
      });

      group('Glob.quote-style drive prefix escaping', () {
        test('C\\:\\path\\*.txt pattern normalizes and expands correctly', () async {
          await d.file('foo.txt').create();
          await d.file('bar.txt').create();

          final quotedBase = Glob.quote(d.sandbox);
          final pattern = '$quotedBase/*.txt';
          final args = await _resolve('ls $pattern', glob: true);
          expect(args.first, equals('ls'));
          expect(args.sublist(1), unorderedEquals([d.path('foo.txt'), d.path('bar.txt')]));
        }, testOn: 'windows');

        test('quoted Windows absolute path with glob is passed literally', () async {
          await d.file('foo.txt').create();
          final quotedPath = '"${d.sandbox.replaceAll(r'\', r'\\')}\\*.txt"';
          final args = await _resolve('ls $quotedPath', glob: true);
          expect(args.first, equals('ls'));
          expect(args.sublist(1).single, equals(p.join(d.sandbox, '*.txt')));
        }, testOn: 'windows');
      });

      test('UNC path with glob: false passes through literally', () async {
        const uncPattern = r'\\server\share\*.txt';
        final args = await _resolve('ls $uncPattern', glob: false);
        expect(args.first, equals('ls'));
        expect(args.sublist(1), equals([uncPattern]));
      });
    }, testOn: 'windows');

    onWindowsOrWithGlobFalse((glob) {
      test('ignores glob characters', () async {
        await d.file('foo.txt').create();
        await d.file('bar.txt').create();
        await d.file('baz.zip').create();

        expect(await _resolve('ls *.txt', glob: glob), equals(['ls', '*.txt']));
      });
    });
  });

  group('escaping', () {
    test('quotes an empty string', () {
      expect(arg(''), equals('""'));
    });

    test('passes through normal text', () {
      expect(arg('foo'), equals('foo'));
    });

    group('backslash-escapes', () {
      test('a space', () {
        expect(arg(' '), equals(r'\ '));
      });

      test('a double quote', () {
        expect(arg('"'), equals(r'\"'));
      });

      test('a single quote', () {
        expect(arg("'"), equals(r"\'"));
      });

      test('a backslash', () {
        expect(arg(r'\'), equals(r'\\'));
      });

      test('an asterisk', () {
        expect(arg('*'), equals(r'\*'));
      });

      test('a question mark', () {
        expect(arg('?'), equals(r'\?'));
      });

      test('square brackets', () {
        expect(arg('[]'), equals(r'\[\]'));
      });

      test('curly brackets', () {
        expect(arg('{}'), equals(r'\{\}'));
      });

      test('parentheses', () {
        expect(arg('()'), equals(r'\(\)'));
      });

      test('a comma', () {
        expect(arg(','), equals(r'\,'));
      });

      test('characters between normal text', () {
        expect(arg("foo bar: 'baz'"), equals(r"foo\ bar:\ \'baz\'"));
      });
    });

    test('quotes multiple arguments', () {
      expect(args(['foo', ' ', '', '*']), equals(r'foo \  "" \*'));
    });
  });
}

/// Runs [callback] in two groups: one restricted to Windows with `glob: null`,
/// and one on all OSes with `glob: false`.
void onWindowsOrWithGlobFalse(void Function(bool? glob) callback) {
  group('on Windows', () => callback(null), testOn: 'windows');
  group('with glob: false', () => callback(false));
}

/// Runs [callback] in two groups: one restricted to non-Windows OSes with
/// `glob: null`, and one on all OSes with `glob: true`.
void onPosixOrWithGlobTrue(void Function(bool? glob) callback) {
  group('on non-Windows OSes', () => callback(null), testOn: '!windows');
  group('with glob: true', () => callback(true));
}

Future<List<String>> _resolve(String executableAndArgs, {bool? glob}) async {
  final args = CliArguments.parse(executableAndArgs, glob: glob);
  return [args.executable, ...await args.arguments(root: d.sandbox)];
}
