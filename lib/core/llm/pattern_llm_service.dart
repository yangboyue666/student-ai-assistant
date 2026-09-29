import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'llm_service.dart';
import '../utils/nl_datetime_parser.dart';

/// 离线智能助手（基于模式匹配 + 模板回复的本地 LLM 服务）
class PatternBasedLlmService implements LlmService {
  PatternBasedLlmService();

  final _random = Random();

  @override
  Future<bool> isReady() async => true;

  @override
  String describe() => '本地智能助手 · 离线模式（无 API 费用）';

  @override
  Future<String> complete(
    List<LlmMessage> messages, {
    List<LlmTool> tools = const [],
  }) async {
    final lastUser = _lastUserText(messages);
    if (lastUser == null || lastUser.trim().isEmpty) {
      return '你好！我是你的学生智能助手，可以帮你管理日程、作业、课程表，也支持聊天。';
    }
    final toolCall = _tryToolCall(lastUser, tools);
    if (toolCall != null) return toolCall;
    return _replyForUser(lastUser, messages);
  }

  @override
  Stream<String> stream(
    List<LlmMessage> messages, {
    List<LlmTool> tools = const [],
  }) async* {
    final lastUser = _lastUserText(messages);
    if (lastUser == null || lastUser.trim().isEmpty) {
      yield* _streamText('你好！我是你的学生智能助手，可以帮你管理日程、作业、课程表，也支持聊天。');
      return;
    }
    final toolCall = _tryToolCall(lastUser, tools);
    if (toolCall != null) {
      yield* _streamText(toolCall);
      return;
    }
    final reply = _replyForUser(lastUser, messages);
    yield* _streamText(reply);
  }

  String? _lastUserText(List<LlmMessage> messages) {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == 'user') return messages[i].content;
    }
    return null;
  }

  String? _tryToolCall(String text, List<LlmTool> tools) {
    if (tools.isEmpty) return null;
    final toolNames = tools.map((t) => t.name).toSet();

    // 优先判断作业（更具体），再判断日程
    if (toolNames.contains('create_assignment') && _looksLikeAssignment(text)) {
      final parsed = _parseAssignmentArgs(text);
      if (parsed != null) return _wrapToolCall('create_assignment', parsed);
    }
    if (toolNames.contains('create_schedule') && _looksLikeSchedule(text)) {
      final parsed = _parseScheduleArgs(text);
      if (parsed != null) return _wrapToolCall('create_schedule', parsed);
    }
    if (toolNames.contains('add_course') && _looksLikeCourse(text)) {
      final parsed = _parseCourseArgs(text);
      if (parsed != null) return _wrapToolCall('add_course', parsed);
    }
    if (toolNames.contains('list_assignments') &&
        _matches(text, ['作业', '截止', '进度', '未完成', '已完成', '查看作业']) &&
        !_looksLikeAssignment(text)) {
      return _wrapToolCall('list_assignments', {});
    }
    if (toolNames.contains('list_schedules') &&
        _matches(text, ['今天', '明天', '本周', '这周', '日程', '提醒', '安排', '查看日程']) &&
        !_looksLikeSchedule(text)) {
      return _wrapToolCall('list_schedules', {});
    }
    return null;
  }

  bool _matches(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  /// 判断是否为创建日程的意图：
  /// 必须同时满足：有时间词 + 有动作词（提醒/安排/开会/约/创建/记录等）
  /// 或者明确包含"日程"且有动作词
  bool _looksLikeSchedule(String text) {
    final t = text.toLowerCase();
    // 动作词：表示用户想"创建/设置/安排"某事
    final actionWords = [
      '提醒', '安排', '开会', '约', '创建', '记录', '设置', '添加', '新建',
      '订', '预定', '报名', '参加', '去', '上课', '见面', '出发',
    ];
    // 时间词
    final timeWords = [
      '明天', '后天', '大后天', '今天', '下周', '这周', '本周', '今晚', '明早', '明晚',
      '周', '星期', '点', '时', '上午', '下午', '晚上', '中午', '凌晨', '早上',
    ];
    // 明确的日程关键词
    if (_matches(text, ['日程', '待办', 'todo']) &&
        _matches(text, ['创建', '添加', '新建', '记录', '设置', '安排', '加', '记'])) {
      return true;
    }
    // 必须同时有时间词和动作词
    final hasTime = _matches(text, timeWords) || NLDateTimeParser.parse(t) != null;
    final hasAction = _matches(text, actionWords);
    return hasTime && hasAction;
  }

  Map<String, dynamic>? _parseScheduleArgs(String text) {
    final dt = NLDateTimeParser.parse(text);
    var title = text;
    title = title
        .replaceAll(RegExp(r'(明天|后天|大后天|今天|昨晚|今晚|明早|明晚|下周|这周|本周|下月|下年|前天|昨天)'), '')
        .replaceAll(RegExp(r'(周一|周二|周三|周四|周五|周六|周日|周天|星期一|星期二|星期三|星期四|星期五|星期六|星期日|星期天|礼拜一|礼拜二|礼拜三|礼拜四|礼拜五|礼拜六|礼拜日|礼拜天)'), '')
        .replaceAll(RegExp(r'\d{1,4}年'), '')
        .replaceAll(RegExp(r'\d{1,2}月'), '')
        .replaceAll(RegExp(r'\d{1,2}[日号]'), '')
        .replaceAll(RegExp(r'(上午|下午|晚上|中午|凌晨|早上|傍晚)'), '')
        .replaceAll(RegExp(r'\d{1,2}点(?:\d{1,2}分)?|点半'), '')
        .replaceAll(RegExp(r'(提醒我|提醒|安排|开会|约|上课|去|做|开|约个)'), '')
        .replaceAll(RegExp(r'^[，,。、\s]+|[，,。、\s]+$'), '')
        .trim();
    if (title.isEmpty) {
      if (text.contains('开会')) {
        title = '开会';
      } else if (text.contains('上课')) {
        title = '上课';
      } else if (text.contains('约')) {
        title = '约会';
      } else {
        title = '日程安排';
      }
    }
    if (dt == null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return {
        'title': title,
        'datetime': DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9).toIso8601String(),
        'remind_before': 600,
        'note': '由 AI 助手自动解析',
      };
    }
    return {
      'title': title,
      'datetime': dt.toIso8601String(),
      'remind_before': 600,
      'note': '由 AI 助手自动解析',
    };
  }

  /// 判断是否为创建作业的意图：必须包含明确的作业关键词
  bool _looksLikeAssignment(String text) {
    return _matches(text, [
      '作业', '实验报告', '课程设计', '论文', 'due', 'assignment', 'deadline',
    ]);
  }

  Map<String, dynamic>? _parseAssignmentArgs(String text) {
    String course = '未指定';
    final courseMatch = RegExp(r'《([^》]+)》').firstMatch(text);
    if (courseMatch != null) {
      course = courseMatch.group(1)!;
    } else {
      final cm = RegExp(r'(\S{1,8}?)(?:课|课程)').firstMatch(text);
      if (cm != null) {
        course = '${cm.group(1)}课';
      }
    }

    // 提取进度百分比（如 50%、百分之五十、进度一半）
    int progress = 0;
    final pctMatch = RegExp(r'(\d{1,3})\s*%').firstMatch(text);
    if (pctMatch != null) {
      progress = int.tryParse(pctMatch.group(1)!) ?? 0;
      progress = progress.clamp(0, 100);
    } else if (_matches(text, ['一半', '半完成'])) {
      progress = 50;
    } else if (_matches(text, ['全部', '全部完成', '完成了', '已完成'])) {
      progress = 100;
    }

    // 识别状态
    String status = 'not_started';
    if (progress >= 100) {
      status = 'completed';
    } else if (progress > 0) {
      status = 'in_progress';
    } else if (_matches(text, ['进行中', '正在做', '做了一半', '没做完'])) {
      status = 'in_progress';
    } else if (_matches(text, ['已完成', '做完了', '完成了', '搞定'])) {
      status = 'completed';
      progress = 100;
    } else if (_matches(text, ['未开始', '还没做', '没做'])) {
      status = 'not_started';
    }

    // 清理标题：移除课程、作业、进度、时间等关键词
    var title = text;
    title = title
        .replaceAll(RegExp(r'《[^》]+》'), '')
        .replaceAll(RegExp(r'(作业|实验报告|课程设计|论文|due|assignment|deadline|截止|提交|要交|交)'), '')
        .replaceAll(RegExp(r'进度\s*\d{1,3}\s*%?|进度[一-龥]*|百分之[一二三四五六七八九十百千零两]+'), '')
        .replaceAll(RegExp(r'\d{1,3}\s*%'), '')
        .replaceAll(RegExp(r'状态[：:]?\s*(未开始|进行中|已完成)'), '')
        .replaceAll(RegExp(r'(未开始|进行中|已完成|做完了|完成了|搞定|还没做|没做|正在做)'), '')
        .replaceAll(RegExp(r'\d{1,4}年'), '')
        .replaceAll(RegExp(r'\d{1,2}月'), '')
        .replaceAll(RegExp(r'\d{1,2}[日号]'), '')
        .replaceAll(RegExp(r'(明天|后天|大后天|今天|下周|这周|本周|今晚|明早|明晚)'), '')
        .replaceAll(RegExp(r'(上午|下午|晚上|中午|凌晨|早上|傍晚)'), '')
        .replaceAll(RegExp(r'\d{1,2}点(?:\d{1,2}分)?|点半'), '')
        .replaceAll(RegExp(r'^[，,。、\s]+|[，,。、\s]+$'), '')
        .trim();
    if (title.isEmpty) title = '新作业';

    final dueDate = NLDateTimeParser.parse(text);
    if (dueDate == null) {
      final d = DateTime.now().add(const Duration(days: 3));
      return {
        'course': course,
        'title': title,
        'due_date': DateTime(d.year, d.month, d.day, 23, 59).toIso8601String(),
        'status': status,
        'progress': progress,
      };
    }
    return {
      'course': course,
      'title': title,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'progress': progress,
    };
  }

  bool _looksLikeCourse(String text) {
    return _matches(text, [
      '课程表', '周', '节', '节次', '星期', '教室', '老师', '教师',
      '课', '上课', '排课',
    ]);
  }

  Map<String, dynamic>? _parseCourseArgs(String text) {
    String name = '新课程';
    final nm = RegExp(r'《([^》]+)》').firstMatch(text);
    if (nm != null) {
      name = nm.group(1)!;
    } else {
      final cm = RegExp(r'(\S{1,8}?)(?:课|课程)').firstMatch(text);
      if (cm != null) name = '${cm.group(1)}课';
    }

    int? weekday;
    final wd = RegExp(r'周([一二三四五六日天])|星期([一二三四五六日天])').firstMatch(text);
    if (wd != null) {
      final s = wd.group(1) ?? wd.group(2);
      const map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
      weekday = map[s];
    }

    int? period;
    final pd = RegExp(r'(?:第)?(\d{1,2})(?:节|节课)').firstMatch(text);
    if (pd != null) period = int.tryParse(pd.group(1)!);

    String? location;
    final lc = RegExp(r'(?:教室|地点|在)(\S{1,20})').firstMatch(text);
    if (lc != null) location = lc.group(1)!.trim();

    String? teacher;
    final tc = RegExp(r'(?:老师|教师|授课)(\S{1,10})').firstMatch(text);
    if (tc != null) teacher = tc.group(1)!.trim();

    if (weekday == null && period == null && name == '新课程') return null;
    return {
      'name': name,
      'weekday': weekday ?? 1,
      'period': period ?? 1,
      'location': location ?? '',
      'teacher': teacher ?? '',
    };
  }

  String _wrapToolCall(String name, Map<String, dynamic> args) {
    final payload = jsonEncode({'name': name, 'arguments': args});
    return '<<TOOLCALL>>$payload<</TOOLCALL>>';
  }

  String _replyForUser(String text, List<LlmMessage> history) {
    final t = text.toLowerCase();

    // 数学计算：识别加减乘除等算式
    final mathResult = _tryMath(text);
    if (mathResult != null) return mathResult;

    if (_matches(text, ['你好', 'hi', 'hello', '嗨', '您好']) && text.length < 12) {
      return _pick([
        '你好！我是你的学生智能助手，有什么我可以帮你的吗？',
        '你好呀~ 我可以帮你记录日程、管理作业、整理课程表，也可以陪你聊聊学习上的问题。',
      ]);
    }

    if (_matches(text, ['你是谁', '你能做什么', '有什么功能', '介绍', '帮助'])) {
      return '我是你的学生智能助手，完全离线运行，不会上传你的数据。'
          '我能帮你做这些事：\n'
          '1. 日程管理 —— 你可以直接说"明天下午3点开会"，我会自动解析并设置提醒。\n'
          '2. 作业管理 —— 添加、追踪作业进度，截止前自动提醒。\n'
          '3. 课程表 —— 周视图展示，支持上传课程表照片作参考。\n'
          '4. 聊天咨询 —— 学习方法、知识点解答、心理调节等。\n'
          '5. 简单计算 —— 直接问"1+1等于几"我就能回答。\n'
          '试试看，直接和我说一句话吧！';
    }

    if (_matches(text, ['怎么学', '学习方法', '提高', '记忆', '专注', '效率'])) {
      return '关于学习方法，我推荐几个被验证有效的策略：\n\n'
          '1. 番茄工作法：25 分钟专注 + 5 分钟休息，4 个番茄后休息 15 分钟。\n'
          '2. 主动回忆（Active Recall）：合上书本尝试复述刚学的内容，比反复阅读高效得多。\n'
          '3. 间隔重复（Spaced Repetition）：用 Anki 等工具，按遗忘曲线复习。\n'
          '4. 费曼技巧：用最简单的话把概念讲给"小白"听，讲不通的地方就是你需要重学的。\n'
          '5. 双码学习：把抽象概念和具体图像/例子绑定。\n\n'
          '要不要我帮你把"番茄工作法"加成一条日程，每天固定时段使用？';
    }

    if (_matches(text, ['数学', '公式', '解题', '方程', '几何'])) {
      return '数学学习的关键是：先理解概念本质，再做大量变式练习。\n\n'
          '如果你有具体的题目（比如算式），直接发过来，我可以帮你算；\n'
          '如果是某个知识点（如导数、向量、概率）想加深理解，告诉我主题，我帮你梳理。';
    }

    if (_matches(text, ['英语', '单词', '语法', '听力', '口语', '阅读理解'])) {
      return '英语提升要分模块突破：\n'
          '· 单词：每天 20 个，结合例句记忆；高频词优先。\n'
          '· 语法：从句子结构入手，别死记规则。\n'
          '· 听力：先精听（逐句听写）再泛听。\n'
          '· 口语：影子跟读（shadowing）+ 录音自检。\n'
          '· 阅读：限时训练，先题后文。\n\n'
          '告诉我你的薄弱点，我给你更具体的练习方案。';
    }

    if (_matches(text, ['累', '焦虑', '压力', '不想学', '难过', '崩溃', '烦', '失眠'])) {
      return '听到你说这些，我先抱抱你。\n\n'
          '学生时代压力大是常态，但你愿意说出来，就已经在自我调节了。\n'
          '现在可以试着：\n'
          '1. 暂停学习 10 分钟，做几次深呼吸（吸 4 秒 - 屏 4 秒 - 呼 6 秒）。\n'
          '2. 喝一杯水，到窗边看看远处。\n'
          '3. 把让你焦虑的事写在纸上，区分"可控"和"不可控"。\n\n'
          '如果持续低落超过两周，请一定找心理咨询师聊聊，这不是软弱，是智慧。';
    }

    if (_matches(text, ['吃什么', '作息', '睡觉', '熬夜', '早起'])) {
      return '健康作息比临时努力更重要：\n'
          '· 尽量 23:30 前睡，7:00 左右起，规律比时长更重要。\n'
          '· 早餐要有蛋白质（鸡蛋/牛奶），别只吃面包。\n'
          '· 久坐每 45 分钟起身活动 2 分钟。\n\n'
          '要不要我帮你设置"23:00 提醒准备睡觉"的日程？';
    }

    if (_matches(text, ['谢谢', 'thanks', '感谢'])) {
      return _pick(['不客气！随时来找我~', '很高兴能帮到你']);
    }

    if (_matches(text, ['再见', '拜拜', 'bye', '晚安'])) {
      return _pick(['再见！有需要随时来找我~', '晚安，明天见！']);
    }

    // 天气/日期等常识性问题
    if (_matches(text, ['今天', '星期几', '几号', '日期']) && !_looksLikeSchedule(text)) {
      final now = DateTime.now();
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      return '今天是 ${now.year} 年 ${now.month} 月 ${now.day} 日，星期${weekdays[now.weekday - 1]}。';
    }

    // 默认：自然聊天，不再总是列举功能
    return _pick([
      '嗯，我在听。你可以和我说说具体情况，我会尽力帮你。',
      '好的，我理解你的意思。如果需要我帮忙记录日程、作业，或者解答学习问题，随时告诉我。',
      '收到~ 有什么我能帮上忙的吗？比如安排日程、管理作业，或者聊聊学习方法都可以。',
      '我明白了。你还想了解什么，或者需要我帮你做什么吗？',
    ]);
  }

  /// 尝试解析并计算简单的数学表达式
  String? _tryMath(String text) {
    // 匹配常见数学问法
    final askPattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*([+\-*/×÷])\s*(\d+(?:\.\d+)?)',
    );
    final match = askPattern.firstMatch(text);
    if (match == null) return null;
    final a = double.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = double.parse(match.group(3)!);
    double result;
    String opSymbol;
    switch (op) {
      case '+':
        result = a + b;
        opSymbol = '+';
        break;
      case '-':
        result = a - b;
        opSymbol = '-';
        break;
      case '*':
      case '×':
        result = a * b;
        opSymbol = '×';
        break;
      case '/':
      case '÷':
        if (b == 0) return '除数不能为 0 哦~';
        result = a / b;
        opSymbol = '÷';
        break;
      default:
        return null;
    }
    // 结果格式化：整数则去掉小数点
    final resultStr = result == result.roundToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return '$a $opSymbol $b = $resultStr';
  }

  String _pick(List<String> options) =>
      options[_random.nextInt(options.length)];

  Stream<String> _streamText(String text) async* {
    final chunks = _chunk(text);
    for (final c in chunks) {
      await Future.delayed(Duration(milliseconds: 25 + _random.nextInt(55)));
      yield c;
    }
  }

  List<String> _chunk(String text) {
    final out = <String>[];
    final buf = StringBuffer();
    for (final c in text.runes) {
      buf.writeCharCode(c);
      final s = String.fromCharCode(c);
      if (_isPunct(s)) {
        out.add(buf.toString());
        buf.clear();
      } else if (buf.length >= 3) {
        out.add(buf.toString());
        buf.clear();
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    return out;
  }

  bool _isPunct(String c) => '。，；！？.,;!?、\n'.contains(c);
}

class ToolCallParser {
  static final _pattern = RegExp(r'<<TOOLCALL>>([\s\S]*?)<</TOOLCALL>>');

  static List<LlmToolCall> extract(String text) {
    final matches = _pattern.allMatches(text);
    final out = <LlmToolCall>[];
    int idx = 0;
    for (final m in matches) {
      final raw = m.group(1)!.trim();
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final name = decoded['name']?.toString() ?? '';
          final args = decoded['arguments'];
          final argsJson = args is String ? args : jsonEncode(args ?? {});
          out.add(LlmToolCall(
            id: 'call_${DateTime.now().millisecondsSinceEpoch}_$idx',
            name: name,
            arguments: argsJson,
          ));
          idx++;
        }
      } catch (_) {}
    }
    return out;
  }

  static String stripToolCalls(String text) =>
      text.replaceAll(_pattern, '').trim();
}
