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

    group('with a non-empty environment', () {
      test('can override existing variables', () {
        final varName = uid();
        withEnv(() {
          env[varName] = 'original';
          env[varName] = 'new special fancy value';
          expect(env, containsPair(varName, 'new special fancy value'));
        }, {varName: 'original'});
      });

      test('can remove existing variables', () {
        final varName = uid();
        withEnv(() {
          env[varName] = 'value';
          env.remove(varName);
          expect(env, isNot(contains(varName)));
        }, {varName: 'value'});
      });
    });
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
      final k = uid();
      withEnv(expectAsync0(() => expect(env, equals({k: 'bar'}))), {k: 'bar'}, includeParentEnvironment: false);
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

    // Explicit: on Windows, case-colliding keys in the override map canonicalize to one entry; last in iteration order wins.
    test('case-collision: synthetic keys in withEnv map canonicalize to one entry; last in iteration order wins', () {
      final k = uid();
      withEnv(
        expectAsync0(() {
          expect(env[k], equals('last'));
          expect(env[k.toUpperCase()], equals('last'));
          expect(env.length, equals(1));
        }),
        {k: 'first', k.toUpperCase(): 'last'},
        includeParentEnvironment: false,
      );
    });

    test('case-collision: inverse order confirms last-in-iteration-order wins', () {
      final k = uid();
      withEnv(
        expectAsync0(() {
          expect(env[k], equals('first'));
          expect(env[k.toUpperCase()], equals('first'));
          expect(env.length, equals(1));
        }),
        {k.toUpperCase(): 'last', k: 'first'},
        includeParentEnvironment: false,
      );
    });

    test('case-collision: direct map ops with synthetic keys overwrite same slot', () {
      final k = uid();
      withEnv(() {
        env[k] = 'lower';
        env[k.toUpperCase()] = 'upper';
        expect(env[k], equals('upper'));
        expect(env[k.toUpperCase()], equals('upper'));
        env[k] = 'final';
        expect(env[k.toUpperCase()], equals('final'));
      }, {});
    });

    test('includeParentEnvironment: false with differing key casing canonicalizes to single entry', () {
      final base = uid();
      final kLower = base;
      final kUpper = base.toUpperCase();
      final kMixed = base.isEmpty ? base : '${base[0].toUpperCase()}${base.substring(1)}';
      withEnv(
        expectAsync0(() {
          expect(env[kLower], equals('bar'));
          expect(env[kUpper], equals('bar'));
          expect(env[kMixed], equals('bar'));
          expect(env.length, equals(1));
        }),
        {kMixed: 'bar', kUpper: 'bar', kLower: 'bar'},
        includeParentEnvironment: false,
      );
    });

    test('includeParentEnvironment: false replacement when key casing differs, last in iteration order wins', () {
      final k = uid();
      withEnv(
        expectAsync0(() {
          expect(env[k], equals('z'));
          expect(env[k.toUpperCase()], equals('z'));
          expect(env.length, equals(1));
        }),
        {k: 'a', k.toUpperCase(): 'z'},
        includeParentEnvironment: false,
      );
    });

    test('includeParentEnvironment: true with case-collision in override map, last in iteration order wins', () {
      final k = uid();
      withEnv(() {
        env[k] = 'parent';
        withEnv(
          expectAsync0(() {
            expect(env[k], equals('override_last'));
            expect(env[k.toUpperCase()], equals('override_last'));
          }),
          {k: 'override_first', k.toUpperCase(): 'override_last'},
          includeParentEnvironment: true,
        );
      }, {});
    });

    test(
      'includeParentEnvironment: true with case-collision in override map, inverse order confirms last-in-iteration-order wins',
      () {
        final k = uid();
        withEnv(() {
          env[k] = 'parent';
          withEnv(
            expectAsync0(() {
              expect(env[k], equals('first'));
              expect(env[k.toUpperCase()], equals('first'));
            }),
            {k.toUpperCase(): 'last', k: 'first'},
            includeParentEnvironment: true,
          );
        }, {});
      },
    );

    test('env keys canonicalized to uppercase on Windows', () {
      final varName = uid();
      env[varName] = 'value';
      final keys = env.keys.where((k) => k.toUpperCase() == varName.toUpperCase()).toList();
      expect(keys.length, equals(1));
      expect(keys.single, equals(varName.toUpperCase()));
    });

    // Edge case: case-collision with null values (remove-vs-set ordering semantics).
    test('case-collision null: {k: value, K: null} — last (null) wins, variable removed', () {
      final k = uid();
      withEnv(
        expectAsync0(() {
          expect(env, isNot(contains(k)));
          expect(env, isNot(contains(k.toUpperCase())));
        }),
        {k: 'value', k.toUpperCase(): null},
        includeParentEnvironment: false,
      );
    });

    test('case-collision null: {k: null, K: value} — last (value) wins, variable set', () {
      final k = uid();
      withEnv(
        expectAsync0(() {
          expect(env[k], equals('value'));
          expect(env[k.toUpperCase()], equals('value'));
          expect(env.length, equals(1));
        }),
        {k: null, k.toUpperCase(): 'value'},
        includeParentEnvironment: false,
      );
    });

    test(
      'case-collision null: {k: value, K: null} with includeParentEnvironment: true — last (null) wins, variable removed',
      () {
        final k = uid();
        withEnv(() {
          env[k] = 'parent';
          withEnv(
            expectAsync0(() {
              expect(env, isNot(contains(k)));
              expect(env, isNot(contains(k.toUpperCase())));
            }),
            {k: 'value', k.toUpperCase(): null},
            includeParentEnvironment: true,
          );
        }, {});
      },
    );

    test(
      'case-collision null: {k: null, K: value} with includeParentEnvironment: true — last (value) wins, variable set',
      () {
        final k = uid();
        withEnv(() {
          env[k] = 'parent';
          withEnv(
            expectAsync0(() {
              expect(env[k], equals('value'));
              expect(env[k.toUpperCase()], equals('value'));
            }),
            {k: null, k.toUpperCase(): 'value'},
            includeParentEnvironment: true,
          );
        }, {});
      },
    );
  }, testOn: 'windows');
}
