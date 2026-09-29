import 'llm_service.dart';

/// AI 工具调用集合：定义可被 LLM 触发的工具
///
/// 这些工具的语义被传给 LLM（系统提示词），
/// LLM 据此生成 JSON，App 端解析后执行。
class AiTools {
  AiTools._();

  static List<LlmTool> all() => [
        createSchedule,
        listSchedules,
        completeSchedule,
        deleteSchedule,
        createAssignment,
        listAssignments,
        updateAssignmentProgress,
        addCourse,
        listCourses,
      ];

  static const createSchedule = LlmTool(
    name: 'create_schedule',
    description: '创建一条日程。用于用户表达"明天下午3点开会"等安排时调用。datetime 字段为 ISO8601 字符串。',
    parameters: {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'description': '日程标题'},
        'datetime': {'type': 'string', 'description': 'ISO8601 时间'},
        'remind_before': {'type': 'integer', 'description': '提前多少秒提醒，默认 600'},
        'note': {'type': 'string'},
      },
    },
    required: ['title', 'datetime'],
  );

  static const listSchedules = LlmTool(
    name: 'list_schedules',
    description: '查询日程列表，可按天/周查询。range 字段为 today/this_week/all',
    parameters: {
      'type': 'object',
      'properties': {
        'range': {'type': 'string', 'enum': ['today', 'this_week', 'all']},
      },
    },
  );

  static const completeSchedule = LlmTool(
    name: 'complete_schedule',
    description: '标记一条日程为已完成',
    parameters: {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
      },
      'required': ['id'],
    },
  );

  static const deleteSchedule = LlmTool(
    name: 'delete_schedule',
    description: '删除一条日程',
    parameters: {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
      },
      'required': ['id'],
    },
  );

  static const createAssignment = LlmTool(
    name: 'create_assignment',
    description: '创建一条作业。status: not_started/in_progress/completed',
    parameters: {
      'type': 'object',
      'properties': {
        'course': {'type': 'string'},
        'title': {'type': 'string'},
        'due_date': {'type': 'string', 'description': 'ISO8601 截止时间'},
        'status': {'type': 'string', 'enum': ['not_started', 'in_progress', 'completed']},
        'progress': {'type': 'integer', 'description': '0-100'},
      },
      'required': ['course', 'title', 'due_date'],
    },
  );

  static const listAssignments = LlmTool(
    name: 'list_assignments',
    description: '查询作业列表',
    parameters: {
      'type': 'object',
      'properties': {
        'status': {'type': 'string', 'enum': ['not_started', 'in_progress', 'completed', 'all']},
      },
    },
  );

  static const updateAssignmentProgress = LlmTool(
    name: 'update_assignment_progress',
    description: '更新作业进度',
    parameters: {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
        'progress': {'type': 'integer', 'description': '0-100'},
        'status': {'type': 'string'},
      },
      'required': ['id'],
    },
  );

  static const addCourse = LlmTool(
    name: 'add_course',
    description: '添加一条课程到课程表',
    parameters: {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'weekday': {'type': 'integer', 'description': '1=周一..7=周日'},
        'period': {'type': 'integer', 'description': '第几节'},
        'location': {'type': 'string'},
        'teacher': {'type': 'string'},
      },
      'required': ['name', 'weekday', 'period'],
    },
  );

  static const listCourses = LlmTool(
    name: 'list_courses',
    description: '查询课程表',
    parameters: {
      'type': 'object',
      'properties': {
        'weekday': {'type': 'integer', 'description': '1-7'},
      },
    },
  );

  /// 系统提示词：告诉 LLM 它是谁、有哪些工具
  static const systemPrompt = '''你是一个运行在用户手机上的学生智能助手。你的能力：
1. 日程管理：用户用自然语言描述时间，你可以解析为 ISO8601 datetime 调用 create_schedule 工具。
2. 作业管理：用户描述作业课程、标题、截止日期，调用 create_assignment 工具。
3. 课程表管理：用户描述课程信息，调用 add_course 工具。
4. 学习咨询：学习方法、知识点、心理调节，直接回复。

当用户的请求适合用工具完成时，**必须**用工具调用回复，格式：
<<TOOLCALL>>{"name":"工具名","arguments":{...}}<</TOOLCALL>>

如果工具调用成功，App 会回传结果，你再据此回复用户。
如果用户只是聊天咨询，不用工具调用，直接回复。

保持回复简洁、友好，使用中文。''';
}
