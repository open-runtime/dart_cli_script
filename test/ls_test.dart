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

import 'package:cli_script/cli_script.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('ls()', () {
    test('lists files that match the glob', () async {
      await d.file('foo.txt').create();
      await d.file('bar.txt').create();
      await d.file('baz.zip').create();

      expect(
        ls('*.txt', root: d.sandbox),
        emitsInOrder([
          emitsInAnyOrder(['foo.txt', 'bar.txt']),
          emitsDone,
        ]),
      );
    });

    test('an absolute glob expands to absolute paths', () async {
      await d.file('foo.txt').create();
      await d.file('bar.txt').create();
      await d.file('baz.zip').create();

      expect(
        ls(p.join(Glob.quote(d.sandbox), '*.txt'), root: d.sandbox),
        emitsInOrder([
          emitsInAnyOrder([d.path('foo.txt'), d.path('bar.txt')]),
          emitsDone,
        ]),
      );
    });

    // UNC paths (\\server\share\...) require a real network share to match files.
    // These tests verify ls() completes without crashing when given UNC-like
    // patterns. With no real share, the glob yields no matches. Windows-only.
    test('UNC-like absolute pattern (backslash) is handled without crashing', () async {
      expect(ls(r'\\server\share\*.txt', root: d.sandbox).toList(), completion(isEmpty));
    }, testOn: 'windows');

    test('UNC-like absolute pattern (forward slash) is handled without crashing', () async {
      expect(ls('//server/share/*.txt', root: d.sandbox).toList(), completion(isEmpty));
    }, testOn: 'windows');

    // Drive-relative C:foo (no slash after colon) is NOT absolute in Windows path
    // semantics. The glob package treats it as a relative pattern and joins with
    // root; the resulting path does not resolve to root/foo (sandbox/foo). We
    // create sandbox/foo to guard against regressions (if C:foo incorrectly
    // resolved to sandbox/foo, we would get matches). Forward slash required;
    // C:foo\*.txt would escape the asterisk. Windows-only for determinism.
    test('drive-relative C:foo/*.txt yields no matches under root', () async {
      await d.dir('foo').create();
      await d.file('foo/a.txt').create();

      expect(ls('C:foo/*.txt', root: d.sandbox).toList(), completion(isEmpty));
    }, testOn: 'windows');

    // C:foo\*.txt with backslash: \* escapes the asterisk in glob syntax, so the
    // pattern matches literal "*.txt" filenames only. No such files exist.
    test('C:foo\\*.txt backslash escapes asterisk, matches literal *.txt filename only', () async {
      expect(ls(r'C:foo\*.txt', root: d.sandbox).toList(), completion(isEmpty));
    }, testOn: 'windows');

    // Glob.quote() escapes colons (C\:) and backslashes. When such a pattern is
    // passed to ls(), it is normalized (unescaped, separators converted) and
    // treated as absolute. We assert the expanded results are absolute paths.
    // This tests our normalization of Glob.quote-style patterns, not shell or
    // quoting semantics. Windows-only for determinism.
    test('Glob.quote-style escaped absolute pattern normalizes to absolute paths', () async {
      await d.file('foo.txt').create();
      await d.file('bar.txt').create();

      // Simulate shell-quoted absolute path: escaped colon + backslashes
      final quotedRoot = Glob.quote(d.sandbox);
      final pattern = '$quotedRoot\\*.txt';

      expect(
        ls(pattern, root: d.sandbox),
        emitsInOrder([
          emitsInAnyOrder([d.path('foo.txt'), d.path('bar.txt')]),
          emitsDone,
        ]),
      );
    }, testOn: 'windows');
  });
}
