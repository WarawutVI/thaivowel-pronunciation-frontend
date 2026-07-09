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

  @override
  Widget build(BuildContext context) {
    final filtered = _vowelType == 'all'
        ? _sessions
        : _sessions.where((s) => s.vowelType == _vowelType).toList();

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
              child: FilterPill(
                value: _vowelType,
                isEnglish: isEnglish,
                includeAll: true,
                onChanged: (v) => setState(() => _vowelType = v),
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
