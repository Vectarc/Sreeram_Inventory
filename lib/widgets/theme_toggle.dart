import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';

/// A compact animated sun/moon toggle button for the AppBar top-right corner.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => themeProvider.toggle(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 68,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            border: Border.all(
              color: isDark
                  ? AppColors.indigo.withOpacity(0.5)
                  : AppColors.orange.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.indigo.withOpacity(0.3)
                    : AppColors.orange.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Track icons
              Positioned(
                left: 8,
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 14,
                  color: isDark ? Colors.white24 : Colors.white,
                ),
              ),
              Positioned(
                right: 8,
                child: Icon(
                  Icons.nightlight_round,
                  size: 14,
                  color: isDark ? Colors.white : Colors.white38,
                ),
              ),
              // Sliding thumb
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDark
                          ? const RadialGradient(
                              colors: [Color(0xFF9FA8DA), Color(0xFF3949AB)],
                            )
                          : const RadialGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFFFF9C4)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? AppColors.indigo.withOpacity(0.5)
                              : AppColors.yellow.withOpacity(0.7),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF1A1A2E) : AppColors.orange,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
