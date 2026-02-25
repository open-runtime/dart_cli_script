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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cli_script/cli_script.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'fake_stream_consumer.dart';
import 'util.dart';

void main() {
  group('exit code', () {
    test('is available via the exitCode getter', () {
      expect(mainScript('exitCode = 123;').exitCode, completion(equals(123)));
    });

    test('.success returns true for exit code 0', () {
      expect(mainScript('exitCode = 0;').success, completion(isTrue));
    });

    test('.success returns false for non-zero exit code', () {
      expect(mainScript('exitCode = 1;').success, completion(isFalse));
    });

    test(".done doesn't throw for exit code 0", () {
      expect(mainScript('exitCode = 0;').done, completes);
    });

    test('.done throws a ScriptException for non-zero exit code', () {
      expect(mainScript('exitCode = 234;').done, throwsScriptException(234));
    });

    test("is non-zero for a script that can't be found", () async {
      final script = Script('non-existent-executable');
      expect(script.success, completion(isFalse));
    });
  });

  stdoutOrStderr('stdout', (script) => script.stdout);
  stdoutOrStderr('stderr', (script) => script.stderr);

  test('an error while spawning is printed to stderr', () {
    final script = Script('non-existent-executable');
    expect(script.exitCode, completion(equals(257)));
    expect(
      script.stderr.lines,
      emitsInOrder([
        'Error in non-existent-executable:',
        predicate<String>(
          (line) => line.startsWith('ProcessException:') && line.trim().length > 'ProcessException:'.length,
        ),
      ]),
    );
  });

  group('stdin', () {
    test("passes data to the process's stdin", () {
      final script = mainScript('exitCode = int.parse(stdin.readLineSync()!);');
      script.stdin.writeln('42');
      expect(script.exitCode, completion(equals(42)));
    });

    test("passes a done event to the process's stdin", () {
      final script = mainScript('print(stdin.readLineSync());');
      script.stdin.close();
      expect(script.stdout.lines, emits('null'));
    });
  });

  group('> adds output to a consumer', () {
    test('that listens immediately', () async {
      final controller = StreamController<List<int>>();
      expect(mainScript("print('hello!');") > controller, completes);
      expect(controller.stream.lines, emits('hello!'));
    });

    // This mimics the behavior of [File.openWrite], which doesn't call
    // [Stream.listen] until the file is actually open.
    test('that waits to listen', () async {
      await (mainScript("print('hello!');") >
          FakeStreamConsumer(
            expectAsync1((stream) async {
              await pumpEventQueue();
              expect(stream.lines, emits('hello!'));
            }),
          ));
    });
  });

  group('subprocess environment', () {
    test('defaults to the parent environment', () async {
      final subprocessEnv = await _getSubprocessEnvironment();
      if (Platform.isWindows) {
        // Windows env keys are case-insensitive; compare case-insensitively.
        expect(subprocessEnv.length, equals(Platform.environment.length));
        for (final e in Platform.environment.entries) {
          final key = subprocessEnv.keys.firstWhere(
            (k) => k.toUpperCase() == e.key.toUpperCase(),
            orElse: () => throw StateError('Key ${e.key} not found in subprocess env'),
          );
          expect(subprocessEnv[key], equals(e.value));
        }
      } else {
        expect(subprocessEnv, equals(Platform.environment));
      }
    });

    test('includes modifications to env', () async {
      final varName = uid();
      env[varName] = 'value';
      final subprocessEnv = await _getSubprocessEnvironment();
      expect(_lookupEnvValue(subprocessEnv, varName), equals('value'));
    });

    test('includes scoped modifications to env', () async {
      final varName = uid();
      await withEnv(() async {
        final subprocessEnv = await _getSubprocessEnvironment();
        expect(_lookupEnvValue(subprocessEnv, varName), equals('value'));
      }, {varName: 'value'});
    });

    test('includes values from the environment parameter', () async {
      final varName = uid();
      final subprocessEnv = await _getSubprocessEnvironment(environment: {varName: 'value'});
      expect(_lookupEnvValue(subprocessEnv, varName), equals('value'));
    });

    test('the environment parameter overrides env', () async {
      final varName = uid();
      env[varName] = 'outer value';
      final subprocessEnv = await _getSubprocessEnvironment(environment: {varName: 'inner value'});
      expect(_lookupEnvValue(subprocessEnv, varName), equals('inner value'));
    });

    group('with includeParentEnvironment: false', () {
      // It would be nice to test that the environment is fully empty in the
      // subprocess, but some environment variables unavoidably exist when
      // spawning a process (at least on Linux).

      test('ignores env', () async {
        final varName = uid();
        env[varName] = 'value';
        final subprocessEnv = await _getSubprocessEnvironment(includeParentEnvironment: false);
        expect(_containsEnvKey(subprocessEnv, varName), isFalse);
      });

      test('uses the environment parameter', () async {
        final varName = uid();
        final subprocessEnv = await _getSubprocessEnvironment(
          environment: {varName: 'value'},
          includeParentEnvironment: false,
        );
        expect(_lookupEnvValue(subprocessEnv, varName), equals('value'));
      });

      test('includes minimum Windows system environment needed to spawn', () async {
        final subprocessEnv = await _getSubprocessEnvironment(includeParentEnvironment: false);
        final systemRoot = Platform.environment['SystemRoot'] ?? Platform.environment['SYSTEMROOT'];
        final winDir = Platform.environment['WINDIR'];
        if (systemRoot == null || systemRoot.isEmpty || winDir == null || winDir.isEmpty) {
          markTestSkipped('SystemRoot or WINDIR not available in parent environment');
        }
        expect(_lookupEnvValue(subprocessEnv, 'SystemRoot'), equals(systemRoot));
        expect(_lookupEnvValue(subprocessEnv, 'WINDIR'), equals(winDir));
      }, testOn: 'windows');

      test('with runInShell: true does not add PATH or COMSPEC when includeParentEnvironment: false', () async {
        // When runInShell is true, the process is invoked via the system shell
        // (cmd.exe on Windows). The implementation only adds SystemRoot and
        // WINDIR to the minimal base env; PATH and COMSPEC are not added.
        // This documents that shell-invoked subprocesses with an empty env
        // will NOT inherit PATH/COMSPEC from the parent.
        final systemRoot = Platform.environment['SystemRoot'] ?? Platform.environment['SYSTEMROOT'];
        final winDir = Platform.environment['WINDIR'];
        if (systemRoot == null || systemRoot.isEmpty || winDir == null || winDir.isEmpty) {
          markTestSkipped('SystemRoot or WINDIR not available in parent environment');
        }
        final subprocessEnv = await _getSubprocessEnvironment(includeParentEnvironment: false, runInShell: true);
        expect(_containsEnvKey(subprocessEnv, 'PATH'), isFalse);
        expect(_containsEnvKey(subprocessEnv, 'COMSPEC'), isFalse);
        // Positive assertions: SystemRoot and WINDIR must be present when
        // available in the parent (required for spawning on Windows).
        expect(_lookupEnvValue(subprocessEnv, 'SystemRoot'), equals(systemRoot));
        expect(_lookupEnvValue(subprocessEnv, 'WINDIR'), equals(winDir));
      }, testOn: 'windows');

      test('Windows env key collision: case variants in overrides collapse to single value', () async {
        // Exercise the case-collision path: pass both case variants of a key.
        // Use the same value for both so the outcome is deterministic and does
        // not rely on _lookupEnvValue first/last ambiguity or OS duplicate-key
        // ordering.
        const value = 'collision_test_value';
        final subprocessEnv = await _getSubprocessEnvironment(
          includeParentEnvironment: false,
          environment: {'SystemRoot': value, 'SYSTEMROOT': value},
        );
        expect(_lookupEnvValue(subprocessEnv, 'SystemRoot'), equals(value));
      }, testOn: 'windows');

      test('environment parameter is merged with Windows base env (SystemRoot, WINDIR)', () async {
        // When includeParentEnvironment is false, custom env vars are merged
        // with the Windows base (SystemRoot, WINDIR). Both must be present.
        final systemRoot = Platform.environment['SystemRoot'] ?? Platform.environment['SYSTEMROOT'];
        final winDir = Platform.environment['WINDIR'];
        if (systemRoot == null || systemRoot.isEmpty || winDir == null || winDir.isEmpty) {
          markTestSkipped('SystemRoot or WINDIR not available in parent environment');
        }
        final varName = uid();
        final subprocessEnv = await _getSubprocessEnvironment(
          includeParentEnvironment: false,
          environment: {varName: 'custom'},
        );
        expect(_lookupEnvValue(subprocessEnv, varName), equals('custom'));
        expect(_lookupEnvValue(subprocessEnv, 'SystemRoot'), equals(systemRoot));
        expect(_lookupEnvValue(subprocessEnv, 'WINDIR'), equals(winDir));
      }, testOn: 'windows');
    });
  });

  group('output', () {
    test("returns the script's output without a trailing newline", () {
      expect(mainScript("print('hello!');").output, completion(equals('hello!')));
    });

    test('completes with a ScriptException if the script fails', () {
      expect(mainScript("print('hello!'); exitCode = 12;").output, throwsScriptException(12));
    });
  });

  group('outputBytes', () {
    test("returns the script's output as bytes", () {
      expect(
        mainScript("print('hello!');").outputBytes,
        completion(equals(utf8.encode('hello!${Platform.lineTerminator}'))),
      );
    });

    test('completes with a ScriptException if the script fails', () {
      expect(mainScript("print('hello!'); exitCode = 12;").outputBytes, throwsScriptException(12));
    });
  });

  group('lines', () {
    test("returns the script's stdout lines", () {
      expect(mainScript(r"print('hello\nthere!');").lines, emitsInOrder(['hello', 'there!', emitsDone]));
    });

    test('emits a ScriptException if the script fails', () {
      expect(mainScript("print('hello!'); exitCode = 12;").lines, emitsThrough(emitsError(isScriptException(12))));
    });
  });
}

/// Defines tests for either stdout or for stderr.
void stdoutOrStderr(String name, Stream<List<int>> Function(Script script) stream) {
  group(name, () {
    test('forwards $name from the subprocess and closes', () {
      expect(stream(mainScript("$name.writeln('Hello!');")).lines, emitsInOrder(['Hello!', emitsDone]));
    });

    test('closes after emitting nothing', () {
      expect(stream(mainScript('')).lines, emitsDone);
    });

    test('closes for a script that fails to start', () {
      // Run in a capture block to ignore extra stderr from the process failing
      // to start.
      Script.capture((_) {
        final script = Script('non-existent-executable');
        expect(script.done, throwsA(anything));
        expect(stream(script), emitsThrough(emitsDone));
      }).stderr.drain<void>();
    });

    test('emits non-text values', () {
      // Try emitting null bytes and invalid UTF8 sequences to make sure
      // nothing's forcing this to be interpreted as text.
      expect(stream(mainScript('$name.add([0, 0, 0xC3, 0x28]);')), emits([0, 0, 0xC3, 0x28]));
    });

    test("can't be listened after a macrotask has elapsed", () async {
      final script = mainScript('');
      expect(script.done, completes);
      await pumpEventQueue();

      // We can't use expect(..., throwsStateError) here because of
      // dart-lang/sdk#45815.
      runZonedGuarded(
        () => stream(script).listen(null),
        expectAsync2((error, stackTrace) => expect(error, isStateError)),
      );
    });
  });
}

/// Runs a Dart subprocess and returns the value of `Process.environment` in
/// that subprocess.
Future<Map<String, String>> _getSubprocessEnvironment({
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
}) async {
  if (runInShell) {
    final scriptPath = d.path('env_shell_${uid()}.dart');
    File(scriptPath).writeAsStringSync('''
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  stdout.writeln(json.encode(Platform.environment));
}
''');
    final script = Script(
      arg(Platform.resolvedExecutable),
      args: [...Platform.executableArguments, scriptPath],
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
    final jsonStr = await script.stdout.text;
    await script.done;
    return (json.decode(jsonStr) as Map).cast<String, String>();
  }
  return (json.decode(
            await mainScript(
              'stdout.writeln(json.encode(Platform.environment));',
              environment: environment,
              includeParentEnvironment: includeParentEnvironment,
            ).stdout.text,
          )
          as Map)
      .cast<String, String>();
}

/// Looks up an env value; on Windows uses case-insensitive matching because
/// the OS treats env keys case-insensitively.
String? _lookupEnvValue(Map<String, String> map, String key) {
  if (!Platform.isWindows) return map[key];
  for (final entry in map.entries) {
    if (entry.key.toUpperCase() == key.toUpperCase()) return entry.value;
  }
  return null;
}

/// Checks for env key presence; on Windows uses case-insensitive matching
/// because the OS treats env keys case-insensitively.
bool _containsEnvKey(Map<String, String> map, String key) {
  if (!Platform.isWindows) return map.containsKey(key);
  return map.keys.any((k) => k.toUpperCase() == key.toUpperCase());
}
