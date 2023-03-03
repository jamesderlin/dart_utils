import 'dart:collection';
import 'dart:math';

import 'package:dartbag/collection.dart';
import 'package:dartbag/readable_numbers.dart';
import 'package:test/test.dart';

extension<E> on List<E> {
  void rotateLeftSlow(
    int shiftAmount, {
    int? start,
    int? end,
  }) {
    for (var i = 0; i < shiftAmount; i += 1) {
      rotateLeft(1, start: start, end: end);
    }
  }
}

void main() {
  group('flattenDeep:', () {
    test('Empty List', () {
      expect(flattenDeep<int>(<int>[]), <int>[]);
    });

    test('No nested Lists', () {
      expect(flattenDeep<int>([1, 2, 3]), [1, 2, 3]);
    });

    test('One level of nesting', () {
      expect(
        flattenDeep<int>([
          [1],
          [2],
          [3]
        ]),
        [1, 2, 3],
      );
    });

    test('Mixed types of Iterables', () {
      expect(
        flattenDeep<int>([
          [1],
          {2},
          [3].map((x) => x),
        ]),
        [1, 2, 3],
      );
    });

    test('Multiple levels of nesting', () {
      expect(
        flattenDeep<int>([
          [
            [1],
            [
              [2]
            ]
          ],
          [
            3,
            [4, 5],
          ],
          6
        ]),
        [1, 2, 3, 4, 5, 6],
      );
    });
  });

  group('List.rotateLeft:', () {
    const oddList = [0, 1, 2, 3, 4, 5, 6];
    const evenList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    assert(oddList.length.isOdd);
    assert(evenList.length.isEven);

    test('Empty List', () {
      expect(<int>[]..rotateLeft(0), <int>[]);
      expect(<int>[]..rotateLeft(1), <int>[]);
      expect(<int>[]..rotateLeft(-1), <int>[]);
    });

    test('shiftAmount == 0', () {
      for (var list in [oddList, evenList]) {
        expect([...list]..rotateLeft(0), list);
      }
    });

    test('shiftAmount > 0', () {
      expect(
        [...oddList]..rotateLeft(1),
        [1, 2, 3, 4, 5, 6, 0],
      );
      expect(
        [...evenList]..rotateLeft(1),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0],
      );

      for (var list in [oddList, evenList]) {
        for (var i = 0; i < list.length; i += 1) {
          expect(
            [...list]..rotateLeft(i),
            [...list]..rotateLeftSlow(i),
            reason: 'shiftAmount: $i',
          );
        }
      }
    });

    test('shiftAmount < 0', () {
      expect(
        [...oddList]..rotateLeft(-1),
        [6, 0, 1, 2, 3, 4, 5],
      );
      expect(
        [...evenList]..rotateLeft(-1),
        [11, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      );

      for (var list in [oddList, evenList]) {
        for (var i = 0; i < list.length; i += 1) {
          expect(
            [...list]..rotateLeft(-i),
            [...list]..rotateLeft(list.length - i),
            reason: 'shiftAmount: -$i',
          );
        }
      }
    });

    test('shiftAmount >= length', () {
      for (var list in [oddList, evenList]) {
        expect([...list]..rotateLeft(list.length), list);
        expect(
          [...list]..rotateLeft(list.length + 1),
          [...list]..rotateLeft(1),
        );
        expect(
          [...list]..rotateLeft(list.length + 2),
          [...list]..rotateLeft(2),
        );
        expect(
          [...list]..rotateLeft(list.length * 2 + 1),
          [...list]..rotateLeft(1),
        );
      }
    });

    test('shiftAmount <= -length', () {
      for (var list in [oddList, evenList]) {
        expect([...list]..rotateLeft(-list.length), list);
        expect(
          [...list]..rotateLeft(-list.length - 1),
          [...list]..rotateLeft(-1),
        );
        expect(
          [...list]..rotateLeft(-list.length - 2),
          [...list]..rotateLeft(-2),
        );
        expect(
          [...list]..rotateLeft(-list.length * 2 + -1),
          [...list]..rotateLeft(-1),
        );
      }
    });

    test('ranges work', () {
      var preamble = <Object>['a', 'b', 'c'];
      var postamble = <Object>['w', 'x', 'y', 'z'];

      for (var i = 0; i < oddList.length; i += 1) {
        expect(
          (preamble + oddList + postamble)
            ..rotateLeft(
              i,
              start: preamble.length,
              end: preamble.length + oddList.length,
            ),
          preamble + ([...oddList]..rotateLeft(i)) + postamble,
          reason: 'shiftAmount: $i',
        );
      }
    });
  });

  group('List.sortWithKey:', () {
    final random = Random(0);
    final ordered =
        UnmodifiableListView([for (var i = 0; i < 1000; i += 1) '$i']);
    final shuffled = UnmodifiableListView(ordered.toList()..shuffle(random));

    test('Sorts correctly', () {
      expect(<String>[]..sortWithKey(int.parse), <String>[]);

      var shuffledCopy = shuffled.toList()..sortWithKey(int.parse);
      expect(shuffledCopy, ordered);
    });

    test('Sorts efficiently', () {
      var trackedParseCallCount = 0;

      BigInt trackedParse(String string) {
        trackedParseCallCount += 1;

        // [BigInt] is significantly more expensive than native [int].
        return BigInt.parse(string);
      }

      var stopwatch = Stopwatch()..start();
      shuffled.toList().sort((a, b) {
        var valueA = trackedParse(a);
        var valueB = trackedParse(b);
        return valueA.compareTo(valueB);
      });
      var regularDuration = stopwatch.elapsed;

      var regularCallCount = trackedParseCallCount;
      trackedParseCallCount = 0;

      stopwatch
        ..reset()
        ..start();
      shuffled.toList().sortWithKey(trackedParse);
      var keyDuration = stopwatch.elapsed;

      var keyCallCount = trackedParseCallCount;

      expect(keyCallCount, lessThan(regularCallCount));
      expect(keyDuration, lessThan(regularDuration));

      var speedup = regularDuration.inMicroseconds / keyDuration.inMicroseconds;
      print(
        'List.sort() element conversion count:        $regularCallCount\n'
        'List.sortWithKey() element conversion count: $keyCallCount\n'
        'List.sort() duration:        ${regularDuration.toReadableString()}\n'
        'List.sortWithKey() duration: ${keyDuration.toReadableString()}\n'
        'Speedup: ${speedup.toStringAsFixed(1)}x',
      );
    });
  });

  group('List.sortWithAsyncKey', () {
    final random = Random(0);
    final ordered =
        UnmodifiableListView([for (var i = 0; i < 1000; i += 1) '$i']);
    final shuffled = UnmodifiableListView(ordered.toList()..shuffle(random));

    test('Sorts correctly', () async {
      Future<int> parseAsync(String string) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return int.parse(string);
      }

      var emptyList = <String>[];
      await emptyList.sortWithAsyncKey(parseAsync);
      expect(emptyList, <String>[]);

      var shuffledCopy = shuffled.toList();
      await shuffledCopy.sortWithAsyncKey(parseAsync);

      expect(shuffledCopy, ordered);
    });
  });

  test('Iterable.drain', () {
    var list = [1, 2, 3];
    var result = 0;
    var iterable = list.map((x) => result = result * result + x);
    expect(result, 0);
    iterable.drain();
    expect(result, 12);
  });

  test('LinkedHashMap.sort', () {
    final random = Random(0);

    final asciiLittleA = 'a'.codeUnits[0];
    var keys = [
      for (var i = 0; i < 26; i += 1) String.fromCharCode(i + asciiLittleA),
    ];
    var values = [for (var i = 0; i < keys.length; i += 1) i];

    keys.shuffle(random);
    values.shuffle(random);

    var map = LinkedHashMap.fromIterables(keys, values);
    var mapCopy = {...map};

    assert(!_isSorted(map.keys));
    assert(!_isSorted(map.values));

    map.sort((entry1, entry2) => entry1.key.compareTo(entry2.key));
    expect(map.keys, map.keys.toList()..sort());
    expect(_isSorted(map.values), false);
    expect(map, mapCopy);

    map.sort((entry1, entry2) => entry1.value.compareTo(entry2.value));
    expect(map.values, map.values.toList()..sort());
    expect(_isSorted(map.keys), false);
    expect(map, mapCopy);
  });

  group('mergeMaps:', () {
    const emptyMap = <String, int>{};

    test('Empty List', () {
      expect(mergeMaps(<Map<String, int>>[]), emptyMap);
    });

    test('List with empty Maps', () {
      expect(mergeMaps([emptyMap, emptyMap]), emptyMap);
    });

    test('List with a single Map', () {
      var map = {'a': 1, 'b': 2, 'c': 3};
      expect(
        mergeMaps([map]),
        map.map((key, value) => MapEntry(key, [value])),
      );
    });

    test('List with multiple Maps', () {
      var merged = mergeMaps([
        {'a': 1, 'b': 2},
        {'a': 10, 'b': 20, 'c': 30},
        {'a': 100},
      ]);

      expect(merged, {
        'a': [1, 10, 100],
        'b': [2, 20],
        'c': [30],
      });

      var foldedValues = {
        for (var entry in merged.entries)
          entry.key: entry.value.fold(0, (a, b) => a + b),
      };
      expect(foldedValues, {'a': 111, 'b': 22, 'c': 30});

      var earliestValues = {
        for (var entry in merged.entries) entry.key: entry.value.first,
      };
      expect(earliestValues, {'a': 1, 'b': 2, 'c': 30});
    });
  });
}

/// Returns `true` if [iterable] is already sorted based on its natural
/// [Comparable] ordering, `false` otherwise.
bool _isSorted<E extends Comparable<Object>>(Iterable<E> iterable) {
  var iterator = iterable.iterator;
  if (!iterator.moveNext()) {
    return true;
  }

  var previousValue = iterator.current;
  while (iterator.moveNext()) {
    var currentValue = iterator.current;
    if (previousValue.compareTo(currentValue) > 0) {
      return false;
    }
    previousValue = currentValue;
  }
  return true;
}
