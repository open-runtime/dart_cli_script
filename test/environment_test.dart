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

import 'package:cli_script/cli_script.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  group('env', () {
    test('is equal to Platform.environment by default', () {
      if (Platform.isWindows) {
        // Windows env keys are case-insensitive; env canonicalizes keys.
        expect(env.length, equals(Platform.environment.length));
        for (final e in Platform.environment.entries) {
          expect(env[e.key], equals(e.value));
        }
      } else {
        expect(env, equals(Platform.environment));
      }
    });

    test('can set new variables', () {
      final varName = uid();
      env[varName] = 'value';
      expect(env, containsPair(varName, 'value'));
    });

    group(
      'with a non-empty environment',
      () {
        test('can override existing variables', () {
          final varName = Platform.environment.keys.first;
          env[varName] = 'new special fancy value';
          expect(env, containsPair(varName, 'new special fancy value'));
        });

        test('can remove existing variables', () {
          final varName = Platform.environment.keys.last;
          env.remove(varName);
          expect(env, isNot(contains(varName)));
        });
      },
      skip: Platform.environment.isEmpty ? 'These tests require at least one environment variable to be set' : null,
    );
  });

  group('withEnv', () {
    group('with an empty environment', () {
      test("returns the callback's return value", () {
        expect(withEnv(() => 42, {}), equals(42));
      });

      test('copies the outer environment', () {
        final outerEnv = Map.of(env);
        withEnv(expectAsync0(() => expect(env, equals(outerEnv))), {});
      });

      test("inner modifications don't modify the outer environment", () {
        final varName = uid();
        withEnv(
          expectAsync0(() {
            env[varName] = 'value';
            expect(env, containsPair(varName, 'value'));
          }),
          {},
        );
        expect(env, isNot(contains(varName)));
      });

      test('with includeParentEnvironment: false creates an empty environment', () {
        withEnv(expectAsync0(() => expect(env, isEmpty)), {}, includeParentEnvironment: false);
      });
    });

    test('overrides outer variables', () {
      final varName = uid();
      env[varName] = 'outer value';
      withEnv(expectAsync0(() => expect(env, containsPair(varName, 'inner value'))), {varName: 'inner value'});
      expect(env, containsPair(varName, 'outer value'));
    });

    test('removes outer variables with value null', () {
      final varName = uid();
      env[varName] = 'outer value';
      withEnv(expectAsync0(() => expect(env, isNot(contains(varName)))), {varName: null});
      expect(env, containsPair(varName, 'outer value'));
    });

    test('replaces the outer environment with includeParentEnvironment: false', () {
      withEnv(expectAsync0(() => expect(env, equals({'FOO': 'bar'}))), {'FOO': 'bar'}, includeParentEnvironment: false);
    });
  });

  group('on Windows', () {
    test('environment variables are accessed case-insensitively', () {
      final varName = uid();
      env[varName] = 'value';
      expect(env, containsPair(varName.toUpperCase(), 'value'));
    });

    test('environment variables are removed case-insensitively', () {
      final varName = uid();
      env[varName] = 'value';
      env.remove(varName.toUpperCase());
      expect(env, isNot(contains(varName)));
      expect(env, isNot(contains(varName.toUpperCase())));
    });

    test('environment variables are overridden case-insensitively', () {
      final varName = uid();
      env[varName] = 'outer value';
      env.remove(varName.toUpperCase());
      withEnv(expectAsync0(() => expect(env, containsPair(varName, 'inner value'))), {
        varName.toUpperCase(): 'inner value',
      });
    });
  }, testOn: 'windows');
}
