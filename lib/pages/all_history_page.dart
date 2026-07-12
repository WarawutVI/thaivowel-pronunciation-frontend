import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/pages/progressELM/session_row.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class AllHistoryPage extends StatefulWidget {
  const AllHistoryPage({super.key});

  @override
  State<AllHistoryPage> createState() => _AllHistoryPageState();
}

class _AllHistoryPageState extends State<AllHistoryPage> {
  late bool isEnglish;
  bool _loading = true;
  String? _error;
  List<SessionRecord> _sessions = [];
  String _vowelType = 'all'; // 'all' | 'short' | 'long'
  String? _symbol; // null = all vowels

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PracticeApi.fetchRecentSessions(_uid, limit: 1000);
      setState(() { _sessions = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<SessionRecord> get _typeFiltered => _vowelType == 'all'
      ? _sessions
      : _sessions.where((s) => s.vowelType == _vowelType).toList();

  List<String> get _availableSymbols =>
      _typeFiltered.map((s) => s.symbol).toSet().toList()..sort();

  Widget _buildSymbolPill(List<String> symbols) {
    return PopupMenuButton<String?>(
      initialValue: _symbol,
      onSelected: (v) => setState(() => _symbol = v),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Icon(
                _symbol == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 16,
                color: const Color(0xFF1A7A50),
              ),
              const SizedBox(width: 8),
              Text(t('All vowels', 'สระทั้งหมด'),
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
        for (final sym in symbols)
          PopupMenuItem<String?>(
            value: sym,
            child: Row(
              children: [
                Icon(
                  _symbol == sym
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: const Color(0xFF1A7A50),
                ),
                const SizedBox(width: 8),
                Text(sym,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _symbol == sym ? FontWeight.w600 : FontWeight.normal,
                        color: Colors.black87)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1A7A50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _symbol ?? t('All vowels', 'สระทั้งหมด'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A7A50),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: Color(0xFF1A7A50)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeFiltered = _typeFiltered;
    final symbols = _availableSymbols;
    final filtered = _symbol == null
        ? typeFiltered
        : typeFiltered.where((s) => s.symbol == _symbol).toList();
    final avgConfidence = filtered.isEmpty
        ? null
        : filtered.map((s) => s.confidence).reduce((a, b) => a + b) /
            filtered.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('History', 'ประวัติ'),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterPill(
                    value: _vowelType,
                    isEnglish: isEnglish,
                    includeAll: true,
                    onChanged: (v) => setState(() {
                      _vowelType = v;
                      _symbol = null;
                    }),
                  ),
                  _buildSymbolPill(symbols),
                  if (avgConfidence != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accuracyColor(avgConfidence)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t(
                          'Average ${(avgConfidence * 100).round()}%',
                          'เฉลี่ย ${(avgConfidence * 100).round()}%',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accuracyColor(avgConfidence),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A7A50)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A7A50)),
                              child: Text(t('Retry', 'ลองอีกครั้ง'),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(t('No sessions yet', 'ยังไม่มีเซสชัน'),
                                style: const TextStyle(color: Colors.grey)),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: const Color(0xFF1A7A50),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => SessionRow(
                                session: filtered[i],
                                isEnglish: isEnglish,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
