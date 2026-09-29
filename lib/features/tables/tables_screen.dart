import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';
import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import '../../shared/widgets/animated_indicators.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  List<String> _tables = [];
  String? _current;
  List<Map<String, String>> _rows = [];
  List<String> _cols = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;
    final res = await db.rawQuery(
      'SELECT DISTINCT table_name FROM ${Tables.tableRows} ORDER BY table_name ASC',
    );
    final names = res.map((r) => r['table_name'] as String).toList();
    setState(() {
      _tables = names;
      _loading = false;
      if (names.isNotEmpty) _select(names.first);
    });
  }

  Future<void> _select(String name) async {
    final db = await AppDatabase.instance.database;
    final res = await db.query(
      Tables.tableRows,
      where: 'table_name = ?',
      whereArgs: [name],
      orderBy: 'row_index ASC',
    );
    final rows = <Map<String, String>>[];
    for (final r in res) {
      final data = r['data'] as String;
      final map = jsonDecode(data);
      if (map is Map) {
        rows.add(Map<String, String>.from(map.map((k, v) => MapEntry(k.toString(), v.toString()))));
      }
    }
    final cols = <String>{};
    for (final r in rows) {
      cols.addAll(r.keys);
    }
    setState(() {
      _current = name;
      _rows = rows;
      _cols = cols.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: '通用表格'),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: _loading
                ? const Center(child: PulsingDot(size: 16))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            const SectionIndicator(
                              label: '可编辑表格',
                              colors: [AppColors.accent1, AppColors.accent2],
                            ),
                            const Spacer(),
                            if (_current != null) _exportButtons(),
                          ],
                        ),
                      ),
                      // 标签栏（多个表格）
                      if (_tables.length > 1)
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _tables.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final name = _tables[i];
                              final selected = name == _current;
                              return GestureDetector(
                                onTap: () => _select(name),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.accent1.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected ? AppColors.accent1 : AppColors.glassBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Expanded(
                        child: _current == null
                            ? _emptyState()
                            : _tableWidget(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTable(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新表格'),
      ),
    );
  }

  Widget _exportButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: 14,
          backgroundOpacity: 0.10,
          onTap: () => _exportCsv(),
          child: Row(
            children: const [
              Icon(Icons.download_rounded, size: 14, color: AppColors.accent1),
              SizedBox(width: 4),
              Text('CSV', style: TextStyle(color: AppColors.accent1, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: 14,
          backgroundOpacity: 0.10,
          onTap: () => _copyMarkdown(),
          child: Row(
            children: const [
              Icon(Icons.copy_rounded, size: 14, color: AppColors.accent3),
              SizedBox(width: 4),
              Text('MD', style: TextStyle(color: AppColors.accent3, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WaveIndicator(height: 24, barCount: 5),
          const SizedBox(height: 16),
          const Text(
            '还没有表格',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点击右下角 + 创建',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _tableWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: GlassCard(
          padding: const EdgeInsets.all(4),
          borderRadius: 20,
          child: DataTable(
            columns: [
              ..._cols.map((c) => DataColumn(label: Text(c, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)))),
              const DataColumn(label: Text('操作', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
            ],
            rows: _rows
                .asMap()
                .entries
                .map((entry) {
              final i = entry.key;
              final r = entry.value;
              return DataRow(
                cells: [
                  ..._cols.map((c) => DataCell(GestureDetector(
                    onTap: () => _editCell(i, c, r[c] ?? ''),
                    child: Text(r[c] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                  ))),
                  DataCell(GestureDetector(
                    onTap: () => _deleteRow(i),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                  )),
                ],
              );
            }).toList(),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _createTable() async {
    final nameCtrl = TextEditingController(text: '表${_tables.length + 1}');
    final colsCtrl = TextEditingController(text: '列1,列2,列3');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B5E),
        title: const Text('新建表格', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: '表名', hintStyle: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colsCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: '列名（用逗号分隔）', hintStyle: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'name': nameCtrl.text.trim().isEmpty ? '未命名' : nameCtrl.text.trim(),
                'cols': colsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              });
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final name = result['name'] as String;
    final cols = List<String>.from(result['cols']);
    setState(() {
      _tables.add(name);
      _current = name;
      _cols = cols;
      _rows = [];
    });
  }

  Future<void> _editCell(int rowIdx, String col, String current) async {
    final ctrl = TextEditingController(text: current);
    final newTable = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B5E),
        title: Text('编辑 $col', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: '值', hintStyle: TextStyle(color: AppColors.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              // 确保行存在
              setState(() {
                if (_rows.length <= rowIdx) {
                  _rows.insert(rowIdx, <String, String>{});
                }
                _rows[rowIdx][col] = v;
              });
              Navigator.pop(ctx, v);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (newTable != null) {
      await _persist();
    }
  }

  Future<void> _deleteRow(int rowIdx) async {
    setState(() {
      _rows.removeAt(rowIdx);
    });
    await _persist();
  }

  Future<void> _persist() async {
    if (_current == null) return;
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.tableRows, where: 'table_name = ?', whereArgs: [_current]);
    final batch = db.batch();
    final uuid = const Uuid();
    for (int i = 0; i < _rows.length; i++) {
      batch.insert(Tables.tableRows, {
        'id': uuid.v4(),
        'table_name': _current!,
        'row_index': i,
        'data': jsonEncode(_rows[i]),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await batch.commit();
  }

  Future<void> _exportCsv() async {
    if (_current == null) return;
    final buf = StringBuffer();
    buf.writeln(_cols.join(','));
    for (final r in _rows) {
      buf.writeln(_cols.map((c) {
        final v = (r[c] ?? '').replaceAll(',', '，');
        return v;
      }).join(','));
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_current}.csv';
    await File(path).writeAsString(buf.toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出 CSV：$path')),
      );
    }
  }

  Future<void> _copyMarkdown() async {
    if (_current == null) return;
    final buf = StringBuffer();
    buf.writeln('| ${_cols.join(' | ')} |');
    buf.writeln('| ${_cols.map((_) => '---').join(' | ')} |');
    for (final r in _rows) {
      buf.writeln('| ${_cols.map((c) => r[c] ?? '').join(' | ')} |');
    }
    // 简易复制：通过 SnackBar 显示（剪贴板插件未引入）
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Markdown 已生成\n${buf.toString()}')),
      );
    }
  }
}
