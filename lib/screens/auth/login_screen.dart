import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildLogo(isDark),
              const SizedBox(height: 12),
              _buildSlogan(),
              const Spacer(flex: 2),
              _buildButtons(context),
              const SizedBox(height: 24),
              _buildAgreement(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkSurfaceColor : Colors.white)
            .withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.fitness_center_rounded,
        size: 56,
        color: AppTheme.primaryColor,
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOut);
  }

  Widget _buildSlogan() {
    return Column(
      children: [
        Text(
          'SkillKeeper',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 6),
        Text(
          '练在当下，技能不锈',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.dangerColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: TextStyle(fontSize: 13, color: AppTheme.dangerColor),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: auth.clearError,
                        color: AppTheme.dangerColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 16),
              ],
              // 微信一键登录（需已配置 AppID 且勾选协议）
              if (auth.isWeChatRegistered) ...[
                _WeChatButton(
                  loading: auth.isLoading,
                  enabled: _agreed,
                  onPressed: _agreed ? () => auth.loginByWeChat() : null,
                ),
                const SizedBox(height: 12),
              ],
              // Mock 登录：始终可用，无需微信与协议，数据保存在本机
              OutlinedButton.icon(
                onPressed: () => context.read<AuthService>().loginAsGuest(),
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: const Text('Mock 登录（体验进入）'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (!auth.isWeChatRegistered) ...[
                const SizedBox(height: 8),
                Text(
                  '微信未配置时可使用 Mock 登录；配置后仍可用 Mock 调试',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAgreement() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 22,
            child: Checkbox(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: AppTheme.textHint, height: 1.4),
                  children: [
                    const TextSpan(text: '登录即表示同意 '),
                    TextSpan(
                      text: '《用户协议》',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryColor,
                      ),
                    ),
                    const TextSpan(text: ' 与 '),
                    TextSpan(
                      text: '《隐私政策》',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

/// 微信绿 #07C160
const Color _weChatGreen = Color(0xFF07C160);

class _WeChatButton extends StatelessWidget {
  const _WeChatButton({
    required this.loading,
    required this.enabled,
    this.onPressed,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !loading && onPressed != null ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: (onPressed != null && enabled)
                ? _weChatGreen
                : _weChatGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: (onPressed != null && enabled)
                ? [
                    BoxShadow(
                      color: _weChatGreen.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                  ),
                )
              else ...[
                Icon(Icons.chat_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  '微信一键登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
