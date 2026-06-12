import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../l10n/context_l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Feedback",
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return const FeedbackDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _step = 0;
  int _rating = 0;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      HapticFeedback.mediumImpact();
      setState(() => _step++);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      setState(() => _step--);
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.token == null || auth.token!.isEmpty) {
      if (!mounted) return;
      final s = context.read<LocaleProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.feedbackLoginRequired),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);

    try {
      final s = context.read<LocaleProvider>().strings;
      await context.read<FeedbackService>().submitFeedback(
            rating: _rating,
            comment: _controller.text.trim(),
          );
      if (!mounted) return;
      nav.pop();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(s.feedbackSent),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2), // The "Premium Frame" border thickness
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(33),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(33),
            child: Material(
              color: Colors.white,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔷 TOP INDICATOR
                    _buildStepIndicator(),

                    const SizedBox(height: 35),

                    // 🎬 ANIMATED STEPS
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStepContent(s),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = _step == i;
        final isPassed = _step > i;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2563EB) : (isPassed ? const Color(0xFF22C55E) : Colors.grey.shade200),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 4) : null,
              ),
            ),
            if (i < 2)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isPassed ? const Color(0xFF22C55E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(AppStrings s) {
    switch (_step) {
      case 0:
        return _buildRatingStep(s);
      case 1:
        return _buildCommentStep(s);
      case 2:
        return _buildConfirmStep(s);
      default:
        return _buildRatingStep(s);
    }
  }

  Widget _buildRatingStep(AppStrings s) {
    return Column(
      key: const ValueKey(0),
      children: [
        Text(
          s.feedbackShareTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          s.feedbackSubtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final isSelected = _rating > i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _rating = i + 1);
              },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: _rating == i + 1 ? 1.25 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSelected ? Colors.amber : Colors.grey.shade300,
                    size: 48,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 45),
        _buildPrimaryButton(
          onPressed: _rating > 0 ? _nextStep : null,
          label: s.continueLabel,
        ),
      ],
    );
  }

  Widget _buildCommentStep(AppStrings s) {
    return Column(
      key: const ValueKey(1),
      children: [
        Text(
          s.feedbackCommentTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          s.feedbackCommentSubtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 35),
        TextField(
          controller: _controller,
          maxLines: 4,
          maxLength: 2000,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            counterText: '',
            hintText: s.feedbackCommentHint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.blue.shade50),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.blue.shade50),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 35),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _prevStep,
                child: Text(s.feedbackBack, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                onPressed: _nextStep,
                label: s.feedbackNext,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmStep(AppStrings s) {
    return Column(
      key: const ValueKey(2),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF22C55E), size: 60),
        ),
        const SizedBox(height: 25),
        Text(
          s.feedbackReady,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        
        // Affichage de la Note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.shade50),
          ),
          child: Text(
            s.feedbackYourRating + ' $_rating ★',
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16),
          ),
        ),

        // Affichage du Commentaire (si non vide)
        if (_controller.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Text(
                  s.feedbackYourComment,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 8),
                Text(
                  _controller.text,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 40),
        _buildPrimaryButton(
          onPressed: _isLoading ? null : _submit,
          label: s.feedbackConfirmSend,
          loading: _isLoading,
        ),
        TextButton(
          onPressed: _prevStep,
          child: Text(s.feedbackModify, style: const TextStyle(color: Color(0xFF64748B))),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required VoidCallback? onPressed, required String label, bool loading = false}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: onPressed != null ? const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ) : null,
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: loading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
              ),
      ),
    );
  }
}
