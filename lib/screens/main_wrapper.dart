import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'notification_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../services/app_navigation_service.dart';
import '../services/report_draft_service.dart';
import '../services/report_service.dart';
import '../theme/rainguard_theme.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _isRetryingDrafts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigationService.markMainWrapperReady();
    });
    ReportDraftService.refreshPendingDraftCount();
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _retryPendingDrafts() async {
    if (_isRetryingDrafts) return;

    setState(() => _isRetryingDrafts = true);
    try {
      final submittedCount = await ReportService.submitPendingDrafts();
      await ReportDraftService.refreshPendingDraftCount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submittedCount > 0
                ? '$submittedCount pending draft${submittedCount == 1 ? '' : 's'} submitted.'
                : 'No drafts submitted yet. Check your connection.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRetryingDrafts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _selectTab),
      const MapScreen(),
      const NotificationScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: ReportDraftService.pendingDraftCount,
            builder: (context, count, child) {
              if (count <= 0) return const SizedBox.shrink();

              return _PendingDraftNavBanner(
                count: count,
                isRetrying: _isRetryingDrafts,
                onRetryTap: _retryPendingDrafts,
                onViewTap: () => _selectTab(1),
              );
            },
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none),
                label: 'Notification',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _currentIndex,
            selectedItemColor: RainGuardColors.primary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontSize: 8),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _PendingDraftNavBanner extends StatelessWidget {
  const _PendingDraftNavBanner({
    required this.count,
    required this.isRetrying,
    required this.onRetryTap,
    required this.onViewTap,
  });

  final int count;
  final bool isRetrying;
  final VoidCallback onRetryTap;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: RainGuardColors.warningFill,
          border: Border(
            top: BorderSide(color: RainGuardColors.warningText.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: RainGuardColors.warningText,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onViewTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count pending report${count == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RainGuardColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Saved offline. Retry when internet returns.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: RainGuardColors.secondaryText,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: isRetrying ? null : onRetryTap,
                style: FilledButton.styleFrom(
                  backgroundColor: RainGuardColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isRetrying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
