import 'dart:math';

/// 自然语言日期时间解析器
/// 支持模式：
///   - 明天/后天/大后天/今天 + 上午/下午/晚上 + X点/X点半/X点30分
///   - 周一..周日 / 下周一
///   - 12月25日下午2点半
///   - 2026年1月1日8点
///   - 今晚X点 / 明早X点
///   - X天后 / X小时后 / X分钟后
class NLDateTimeParser {
  NLDateTimeParser._();

  static final _chineseDigits = {
    '零': 0, '〇': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
  };

  static final _weekdayMap = {
    '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7,
    '天': 7,
  };

  /// 主入口：解析自然语言日期时间
  /// 返回 null 表示无法解析
  static DateTime? parse(String text, {DateTime? now}) {
    if (text.trim().isEmpty) return null;
    final base = (now ?? DateTime.now());
    var dt = base;
    var hasAny = false;

    // 1) 日期部分
    // 注意：_dateRegex 所有分组都是可选的，可能匹配到空字符串
    // 必须额外检查 group(0) 非空，否则 "你好" 这种文本也会被误判为日期
    final dateMatch = _dateRegex.firstMatch(text);
    if (dateMatch != null && dateMatch.group(0)!.isNotEmpty) {
      dt = _applyDate(dateMatch, dt);
      hasAny = true;
    } else {
      // "今天"/"明天" 等可能没匹配上面 regex
      final rel = _relativeDateRegex.firstMatch(text);
      if (rel != null) {
        dt = _applyRelativeDate(rel, dt);
        hasAny = true;
      }
    }

    // 2) 周几
    final weekdayMatch = _weekdayRegex.firstMatch(text);
    if (weekdayMatch != null) {
      dt = _applyWeekday(weekdayMatch, dt);
      hasAny = true;
    }

    // 3) 时间部分
    final timeMatch = _timeRegex.firstMatch(text);
    if (timeMatch != null) {
      dt = _applyTime(timeMatch, dt);
      hasAny = true;
    } else {
      // 没有时间，但有日期，默认 9:00
      if (dateMatch != null || weekdayMatch != null) {
        // 仅日期没时间时，默认上午9点
        if (text.contains('晚上') || text.contains('晚')) {
          dt = DateTime(dt.year, dt.month, dt.day, 19);
        } else if (text.contains('下午')) {
          dt = DateTime(dt.year, dt.month, dt.day, 14);
        } else if (text.contains('上午') || text.contains('早上')) {
          dt = DateTime(dt.year, dt.month, dt.day, 9);
        } else {
          dt = DateTime(dt.year, dt.month, dt.day, 9);
        }
      }
    }

    if (!hasAny) return null;

    // 4) 处理 "X天后" / "X小时后" / "X分钟后" 这种相对偏移
    // 同样需要检查 group(0) 非空，避免空匹配
    final offsetMatch = _offsetRegex.firstMatch(text);
    if (offsetMatch != null && offsetMatch.group(0)!.isNotEmpty) {
      final days = parseChineseNumber(offsetMatch.namedGroup('days') ?? '');
      final hours = parseChineseNumber(offsetMatch.namedGroup('hours') ?? '');
      final mins = parseChineseNumber(offsetMatch.namedGroup('mins') ?? '');
      if (days > 0) dt = dt.add(Duration(days: days));
      if (hours > 0) dt = dt.add(Duration(hours: hours));
      if (mins > 0) dt = dt.add(Duration(minutes: mins));
    }

    // 5) 处理 "今晚"/"明早"/"明晚" 等关键词
    if (text.contains('今晚')) {
      dt = DateTime(dt.year, dt.month, dt.day, 19);
    }
    if (text.contains('明早') || text.contains('明天早上')) {
      dt = DateTime(dt.year, dt.month, dt.day, 8);
    }
    if (text.contains('明晚') || text.contains('明天晚上')) {
      dt = DateTime(dt.year, dt.month, dt.day, 20);
    }
    if (text.contains('今晚')) {
      dt = DateTime(dt.year, dt.month, dt.day, 19);
    }

    return dt;
  }

  static String get _nums => '0-9零一二两三四五六七八九十百千';

  // YYYY年M月D日（支持阿拉伯数字 + 中文数字）
  static final _dateRegex = RegExp(
    r'(?:(?<year>[\d零一二两三四五六七八九十百千]{2,4})年)?' +
        r'(?:(?<month>[\d零一二两三四五六七八九十]{1,3})月)?' +
        r'(?:(?<day>[\d零一二两三四五六七八九十]{1,3})[日号])?',
  );

  // "今天"/"明天"/"后天"/"大后天"/"昨天"
  static final _relativeDateRegex = RegExp(
    r'(大后天|前天|昨天|今天|明天|后天|下周|下月|下年)',
  );

  // 周一..周日 / 周日
  static final _weekdayRegex = RegExp(
    r'(这|本|下)?(?:周|星期|礼拜)(?<day>[一二三四五六日天])',
  );

  // 时间：上午/下午/晚上 X点 Y分 / X点半 / X点半 / X点
  static final _timeRegex = RegExp(
    r'(?<period>上午|下午|晚上|中午|凌晨|早上|傍晚)?' +
        r'(?<hour>[\d零一二两三四五六七八九十]{1,3})' +
        r'(?:点(?: (?<minute>[\d零一二三四五六七八九十]{1,3}) ?分)?|点半|时)',
  );

  // 相对偏移：X天后 / X小时后 / X分钟后
  static final _offsetRegex = RegExp(
    r'(?:(?<days>[\d零一二三四五六七八九十百]{1,4})天后)?' +
        r'(?:(?<hours>[\d零一二三四五六七八九十]{1,3})小时后)?' +
        r'(?:(?<mins>[\d零一二三四五六七八九十]{1,3})分钟后)?',
  );

  static DateTime _applyDate(RegExpMatch m, DateTime base) {
    var y = base.year, mo = base.month, d = base.day;
    final yStr = m.namedGroup('year');
    final mStr = m.namedGroup('month');
    final dStr = m.namedGroup('day');
    if (yStr != null && yStr.isNotEmpty) {
      final v = parseChineseNumber(yStr);
      if (v > 0) y = v < 100 ? 2000 + v : v;
    }
    if (mStr != null && mStr.isNotEmpty) {
      final v = parseChineseNumber(mStr);
      if (v > 0 && v <= 12) mo = v;
    }
    if (dStr != null && dStr.isNotEmpty) {
      final v = parseChineseNumber(dStr);
      if (v > 0 && v <= 31) d = v;
    }
    return DateTime(y, mo, d, base.hour, base.minute);
  }

  static DateTime _applyRelativeDate(RegExpMatch m, DateTime base) {
    final s = m.group(0)!;
    switch (s) {
      case '今天':
        return base;
      case '明天':
        return base.add(const Duration(days: 1));
      case '后天':
        return base.add(const Duration(days: 2));
      case '大后天':
        return base.add(const Duration(days: 3));
      case '昨天':
        return base.subtract(const Duration(days: 1));
      case '前天':
        return base.subtract(const Duration(days: 2));
      case '下周':
        return base.add(const Duration(days: 7));
      case '下月':
        return DateTime(base.year, base.month + 1, base.day, base.hour, base.minute);
      default:
        return base;
    }
  }

  static DateTime _applyWeekday(RegExpMatch m, DateTime base) {
    final prefix = m.group(1) ?? '';
    final dayStr = m.namedGroup('day')!;
    final target = _weekdayMap[dayStr];
    if (target == null) return base;
    final current = base.weekday;
    var diff = target - current;
    if (prefix == '下') {
      diff += 7;
    } else if (diff < 0) {
      diff += 7;
    } else if (diff == 0 && (prefix.isEmpty)) {
      // 同一天不调整
    }
    return base.add(Duration(days: diff));
  }

  static DateTime _applyTime(RegExpMatch m, DateTime base) {
    final period = m.namedGroup('period');
    final hourStr = m.namedGroup('hour');
    final minuteStr = m.namedGroup('minute');
    final isHalf = m.group(0)!.contains('点半');
    var h = parseChineseNumber(hourStr ?? '0');
    var min = 0;
    if (isHalf) {
      min = 30;
    } else if (minuteStr != null && minuteStr.isNotEmpty) {
      min = parseChineseNumber(minuteStr);
    }
    // 12 小时制 → 24 小时制
    if (period == '下午' || period == '中午' || period == '晚上' || period == '傍晚' || period == '凌晨') {
      if (h < 12) h += 12;
      if (period == '凌晨' && h >= 24) h -= 12; // 凌晨0点
    } else if (period == '上午' || period == '早上') {
      // 保持上午
    } else {
      // 没有上午/下午修饰，看上下文：写"X点"且 X<=12 默认上午
    }
    h = h.clamp(0, 23);
    min = min.clamp(0, 59);
    return DateTime(base.year, base.month, base.day, h, min);
  }

  /// 解析中文/阿拉伯数字混合
  static int parseChineseNumber(String s) {
    if (s.isEmpty) return 0;
    s = s.trim();
    // 纯阿拉伯数字
    final arabicOnly = RegExp(r'^\d+$');
    if (arabicOnly.hasMatch(s)) return int.parse(s);

    // 处理 "十" / "二十" / "三百" / "三百二十一" 等中文数字
    if (!_containsChinese(s)) {
      // 仅数字 + 可能含小数 / 单位
      final m = RegExp(r'(\d+)').firstMatch(s);
      if (m != null) return int.parse(m.group(0)!);
      return 0;
    }
    return _chineseNumberToInt(s);
  }

  static bool _containsChinese(String s) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(s);
  }

  static int _chineseNumberToInt(String s) {
    int result = 0;
    int section = 0;
    int num = 0;
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      final v = _chineseDigits[c];
      if (v != null) {
        if (c == '十' || c == '百' || c == '千') {
          // should not be reached
        }
        num = v;
      } else if (c == '十') {
        section += (num == 0 ? 1 : num) * 10;
        num = 0;
      } else if (c == '百') {
        section += (num == 0 ? 1 : num) * 100;
        num = 0;
      } else if (c == '千') {
        section += (num == 0 ? 1 : num) * 1000;
        num = 0;
      } else {
        // 数字字符
        final d = int.tryParse(c);
        if (d != null) num = d;
      }
    }
    result = section + num;
    return result;
  }
}

// 防止未使用警告
// ignore: unused_element
final _unusedRandom = Random();
