import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  static const Map<String, Map<String, String>> _languages = {
    'en': {'name': 'English', 'flag': '🇬🇧'},
    'tr': {'name': 'Türkçe', 'flag': '🇹🇷'},
    'de': {'name': 'German', 'flag': '🇩🇪'},
  };

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final currentLanguage = _languages[currentLocale];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [
        //     Colors.white.withValues(alpha: 0.2),
        //     Colors.white.withValues(alpha: 0.1),
        //   ],
        // ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEnhancedLanguageDialog(context),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLanguage?['flag'] ?? '🌐',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.center,
                    currentLanguage?['name'] ?? '🌐',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),

                const Text("             "),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnhancedLanguageDialog(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightBlack,
                  AppColors.lightBlack.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryRed.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.15),
                        AppColors.primaryRed.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              AppColors.primaryRed.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          LocaleKeys.select_language.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          tooltip: LocaleKeys.close.tr(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Language List
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _languages.entries.map((entry) {
                      final isSelected = currentLocale == entry.key;

                      return TweenAnimationBuilder<double>(
                        duration: Duration(
                          milliseconds:
                              300 +
                              (_languages.keys.toList().indexOf(entry.key) *
                                  50),
                        ),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primaryRed.withValues(
                                        alpha: 0.2,
                                      ),
                                      AppColors.primaryRed.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.white.withValues(alpha: 0.02),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryRed.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryRed.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.setLocale(Locale(entry.key));
                                Navigator.of(dialogContext).pop();
                              },
                              borderRadius: BorderRadius.circular(16),
                              splashColor: AppColors.primaryRed.withValues(
                                alpha: 0.1,
                              ),
                              highlightColor: AppColors.primaryRed.withValues(
                                alpha: 0.05,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Flag Container
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  AppColors.primaryRed
                                                      .withValues(alpha: 0.15),
                                                  AppColors.primaryRed
                                                      .withValues(alpha: 0.05),
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0.03,
                                                  ),
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryRed.withValues(
                                                  alpha: 0.3,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          entry.value['flag']!,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Language Name
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.value['name']!,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                      alpha: 0.9,
                                                    ),
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              LocaleKeys.currentlySelected.tr(),
                                              style: TextStyle(
                                                color: AppColors.primaryRed
                                                    .withValues(alpha: 0.8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Check Icon
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryRed,
                                              AppColors.primaryRed.withValues(
                                                alpha: 0.8,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryRed
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Footer Info (Optional)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKeys.languageAppliedImmediately.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Alternative: Compact Version with Popup Menu
class CompactLanguageButton extends StatelessWidget {
  const CompactLanguageButton({super.key});

  static const Map<String, Map<String, String>> _languages = {
    'en': {'name': 'English', 'flag': '🇬🇧'},
    'tr': {'name': 'Türkçe', 'flag': '🇹🇷'},
    'de': {'name': 'German', 'flag': '🇩🇪'},
  };

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _languages[currentLocale]?['flag'] ?? '🌐',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.8),
              size: 16,
            ),
          ],
        ),
        color: AppColors.lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3)),
        ),
        elevation: 20,
        offset: const Offset(0, 50),
        tooltip: LocaleKeys.change_language.tr(),
        itemBuilder: (context) => _languages.entries.map((entry) {
          final isSelected = currentLocale == entry.key;

          return PopupMenuItem<String>(
            value: entry.key,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryRed.withValues(alpha: 0.15),
                          AppColors.primaryRed.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: AppColors.primaryRed.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.value['flag']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value['name']!,
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryRed : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryRed,
                            AppColors.primaryRed.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        onSelected: (languageCode) {
          context.setLocale(Locale(languageCode));
        },
      ),
    );
  }
}
