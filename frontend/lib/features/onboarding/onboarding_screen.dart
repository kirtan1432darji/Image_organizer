import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/settings_provider.dart';
import '../../routes/route_names.dart';
import 'widgets/onboarding_step_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isLoading = false;

  Future<void> _handleStartScan() async {
    setState(() => _isLoading = true);

    try {
      // 1. Mark onboarding complete
      await ref.read(settingsProvider.notifier).completeOnboarding();

      // 2. Trigger scan
      await ref.read(scannerProvider.notifier).startScan();

      if (!mounted) return;
      context.go(AppRouteNames.home);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: ColorConstants.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppInfo.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${AppInfo.tagline}.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our AI engine scans and classifies your receipts, code snippets, chats, and documents automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Feature Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    OnboardingStepCard(
                      icon: Icons.shield_outlined,
                      iconColor: ColorConstants.categoryFinance,
                      title: '100% Non-Destructive',
                      description:
                          'We NEVER move, duplicate, or alter your gallery photos. Only smart metadata is indexed.',
                    ),
                    SizedBox(height: 14),
                    OnboardingStepCard(
                      icon: Icons.text_snippet_outlined,
                      iconColor: ColorConstants.categorySocial,
                      title: 'Optical Character Recognition',
                      description:
                          'Extracts text from screenshots so you can search inside images instantly.',
                    ),
                    SizedBox(height: 14),
                    OnboardingStepCard(
                      icon: Icons.category_outlined,
                      iconColor: ColorConstants.accent,
                      title: 'Smart Categorization',
                      description:
                          'Automatically groups screenshots into Receipts, Code, Work, Shopping, Travel, and Memes.',
                    ),
                  ],
                ),
              ),

              // Privacy & Action Button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: ColorConstants.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Your photos stay on your device',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorConstants.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleStartScan,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Grant Access & Start Scan'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ref.read(settingsProvider.notifier).completeOnboarding();
                        context.go(AppRouteNames.home);
                      },
                      child: Text(
                        'Skip for now',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
