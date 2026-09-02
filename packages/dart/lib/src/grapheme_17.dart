import 'grapheme_17_data_generated.dart';

final class Grapheme17 {
  static List<int> boundaries(String text) {
    if (text.isEmpty) return const [0];

    final result = <int>[0];
    var codePoint = _codePointAt(text, 0);
    var cursor = codePoint > 0xffff ? 2 : 1;
    var categoryBefore = Grapheme17Data.category(codePoint);
    var state = _nextState(1, categoryBefore, codePoint);

    while (cursor < text.length) {
      codePoint = _codePointAt(text, cursor);
      final categoryAfter = Grapheme17Data.category(codePoint);
      final pairMask =
          Grapheme17Data.pairMasks[(categoryBefore << 4) | categoryAfter];
      if (state & pairMask == 0) result.add(cursor);
      state = _nextState(state, categoryAfter, codePoint);
      cursor += codePoint > 0xffff ? 2 : 1;
      categoryBefore = categoryAfter;
    }
    result.add(text.length);
    return result;
  }

  static int _nextState(int state, int category, int codePoint) {
    switch (category) {
      case 3:
        return state & 32 != 0 ? _nextExtend(state, codePoint) : state & 21;
      case 4:
        return 17;
      case 10:
        return (state & 2) ^ 3;
      case 14:
        return ((state & 16) >> 2) | (state & 41);
      case 15:
        return 33;
      default:
        return 1;
    }
  }

  static int _nextExtend(int state, int codePoint) {
    if (codePoint == 0x200c) return state & 21;
    if (state & 8 != 0 || Grapheme17Data.isLinker(codePoint)) {
      return (state & 21) | 40;
    }
    return (state & 21) | 32;
  }

  static int _codePointAt(String text, int offset) {
    final first = text.codeUnitAt(offset);
    if (first < 0xd800 || first > 0xdbff || offset + 1 >= text.length) {
      return first;
    }
    final second = text.codeUnitAt(offset + 1);
    if (second < 0xdc00 || second > 0xdfff) return first;
    return 0x10000 + ((first - 0xd800) << 10) + second - 0xdc00;
  }
}
