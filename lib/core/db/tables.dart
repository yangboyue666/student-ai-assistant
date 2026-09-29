/// 表结构定义与建表 SQL
class Tables {
  Tables._();

  static const schedules = 'schedules';
  static const assignments = 'assignments';
  static const courses = 'courses';
  static const tableRows = 'table_rows';
  static const chatSessions = 'chat_sessions';
  static const chatMessages = 'chat_messages';
  static const images = 'images';
  static const moods = 'moods';

  static const allTables = [
    schedules,
    assignments,
    courses,
    tableRows,
    chatSessions,
    chatMessages,
    images,
    moods,
  ];

  static const List<String> createSql = [
    // 日程：Schedule(id, title, datetime, remind_before, note, is_done, source)
    '''
    CREATE TABLE $schedules(
      id            TEXT PRIMARY KEY,
      title         TEXT NOT NULL,
      datetime      INTEGER NOT NULL,
      remind_before INTEGER NOT NULL DEFAULT 600,
      note          TEXT,
      is_done       INTEGER NOT NULL DEFAULT 0,
      source        TEXT,
      created_at    INTEGER NOT NULL,
      updated_at    INTEGER NOT NULL
    );
    ''',
    '''
    CREATE INDEX idx_schedules_datetime ON $schedules(datetime);
    ''',
    '''
    CREATE INDEX idx_schedules_is_done ON $schedules(is_done);
    ''',

    // 作业：Assignment(id, course, title, due_date, status, progress, notes)
    '''
    CREATE TABLE $assignments(
      id         TEXT PRIMARY KEY,
      course     TEXT NOT NULL,
      title      TEXT NOT NULL,
      due_date   INTEGER NOT NULL,
      status     TEXT NOT NULL,
      progress   INTEGER NOT NULL DEFAULT 0,
      notes      TEXT,
      priority   INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    ''',
    '''
    CREATE INDEX idx_assignments_due_date ON $assignments(due_date);
    ''',
    '''
    CREATE INDEX idx_assignments_status ON $assignments(status);
    ''',
    '''
    CREATE INDEX idx_assignments_course ON $assignments(course);
    ''',

    // 课程表：Course(id, name, weekday, period, week_pattern, location, teacher, color)
    '''
    CREATE TABLE $courses(
      id           TEXT PRIMARY KEY,
      name         TEXT NOT NULL,
      weekday      INTEGER NOT NULL,
      period       INTEGER NOT NULL,
      week_start   INTEGER NOT NULL DEFAULT 1,
      week_end     INTEGER NOT NULL DEFAULT 20,
      week_pattern TEXT,
      location     TEXT,
      teacher      TEXT,
      color        INTEGER,
      note         TEXT,
      created_at   INTEGER NOT NULL,
      updated_at   INTEGER NOT NULL
    );
    ''',
    '''
    CREATE INDEX idx_courses_weekday_period ON $courses(weekday, period);
    ''',

    // 通用表格行：TableRow(id, table_name, row_index, col_values_json)
    '''
    CREATE TABLE $tableRows(
      id          TEXT PRIMARY KEY,
      table_name  TEXT NOT NULL,
      row_index   INTEGER NOT NULL,
      data        TEXT NOT NULL,
      created_at  INTEGER NOT NULL,
      updated_at  INTEGER NOT NULL
    );
    ''',
    '''
    CREATE INDEX idx_table_rows_table ON $tableRows(table_name, row_index);
    ''',

    // 对话会话
    '''
    CREATE TABLE $chatSessions(
      id         TEXT PRIMARY KEY,
      title      TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
    ''',

    // 对话消息
    '''
    CREATE TABLE $chatMessages(
      id           TEXT PRIMARY KEY,
      session_id   TEXT NOT NULL,
      role         TEXT NOT NULL,
      content      TEXT NOT NULL,
      tool_calls    TEXT,
      tool_result  TEXT,
      created_at   INTEGER NOT NULL,
      FOREIGN KEY (session_id) REFERENCES $chatSessions(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE INDEX idx_chat_messages_session ON $chatMessages(session_id, created_at);
    ''',

    // 图片引用
    '''
    CREATE TABLE $images(
      id          TEXT PRIMARY KEY,
      ref_type    TEXT NOT NULL,
      ref_id      TEXT,
      file_path   TEXT NOT NULL,
      file_name   TEXT,
      mime_type   TEXT,
      bytes       INTEGER,
      created_at  INTEGER NOT NULL
    );
    ''',
    '''
    CREATE INDEX idx_images_ref ON $images(ref_type, ref_id);
    ''',

    // 心情日记：Mood(id, emoji, content, date, created_at)
    '''
    CREATE TABLE $moods(
      id          TEXT PRIMARY KEY,
      emoji       TEXT NOT NULL,
      content     TEXT,
      date        INTEGER NOT NULL,
      created_at  INTEGER NOT NULL
    );
    ''',
    '''
    CREATE INDEX idx_moods_date ON $moods(date);
    ''',
  ];
}
