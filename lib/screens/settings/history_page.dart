// lib/screens/settings/history_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('history_entries') ?? '[]';
    try {
      final List<dynamic> decoded = json.decode(raw);
      setState(() {
        history = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        history.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
      });
    } catch (_) {
      setState(() => history = []);
    }
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        title: const Text('Очистить историю?', style: TextStyle(color: Colors.white)),
        content: const Text('Это действие нельзя отменить.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('history_entries');
      setState(() => history = []);
    }
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'added': return Colors.greenAccent;
      case 'edited': return Colors.orangeAccent;
      case 'deleted': return Colors.redAccent;
      default: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('История', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (history.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70), onPressed: _clearHistory),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          // Сферы
          Positioned(
            top: 100, right: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)]),
            ),
          ),
          
          SafeArea(
            child: history.isEmpty
                ? Center(child: Text('История пуста', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: Colors.amber,
                    backgroundColor: const Color(0xFF1A1C2C),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final action = entry['action'] ?? '';
                        final color = _getActionColor(action);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildGlassCard(
                            opacity: 0.03,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(_getActionIcon(action), color: color, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry['lessonName'] ?? 'Пара', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(_formatTimestamp(entry['timestamp'] ?? ''), style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                                    ],
                                  ),
                                ),
                                Text(_getActionText(action), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    if (action == 'added') return Icons.add_rounded;
    if (action == 'edited') return Icons.edit_rounded;
    return Icons.delete_outline_rounded;
  }

  String _getActionText(String action) {
    if (action == 'added') return 'ДОБАВЛЕНО';
    if (action == 'edited') return 'ИЗМЕНЕНО';
    return 'УДАЛЕНО';
  }
}
