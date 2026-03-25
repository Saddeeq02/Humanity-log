import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _agentIdController = TextEditingController();
  final _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isObscured = true;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _canCheckBiometrics = false);
      }
    }
  }

  @override
  void dispose() {
    _agentIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan Fingerprint to Authenticate (Mock: Just tap anywhere on emulator prompt)',
      );
    } catch (e) {
      // Ignore errors for mock presentation
      authenticated = true; 
    }

    if (authenticated) {
      final success = await ref.read(authProvider.notifier).loginWithBiometrics();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final agentId = _agentIdController.text;
    final pin = _pinController.text;

    if (agentId.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter Field Agent ID and Secure PIN', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(agentId, pin);
    
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgOffWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon Area
              Icon(
                Icons.volunteer_activism,
                size: 80,
                color: AppTheme.primaryTeal,
              ).animate().fade(duration: 600.ms).scale(delay: 200.ms),
              const SizedBox(height: 24),
              
              Text(
                'HumanityLog',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textCharcoal,
                  letterSpacing: -1.5,
                ),
              ).animate().fadeIn(delay: 300.ms),
              
              Text(
                'FIELD AGENT PORTAL',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentTerracotta,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 64),

              // Login Form Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Verification',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your credentials to access the offline database.',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _agentIdController,
                      style: GoogleFonts.inter(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Agent ID / Email',
                        hintText: 'e.g. AGENT_007',
                        prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryTeal),
                        filled: true,
                        fillColor: AppTheme.bgOffWhite.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _pinController,
                      obscureText: _isObscured,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 18, letterSpacing: 4),
                      decoration: InputDecoration(
                        labelText: 'Secure PIN',
                        hintText: '••••',
                        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryTeal),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isObscured = !_isObscured),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgOffWhite.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2)),
                      ),
                    ),
                    
                    if (authState.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.statusError.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.statusError, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(authState.error!, style: GoogleFonts.inter(color: AppTheme.statusError, fontSize: 13))),
                          ],
                        ),
                      ).animate().shake(hz: 4),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(AppLocalizations.of(context).get('login'), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          if (_canCheckBiometrics || true) ...[ // Force true for mock presentations even if emulator doesn't support it 
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 64,
                              width: 64,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _handleBiometricLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.bgOffWhite,
                                  foregroundColor: AppTheme.primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppTheme.primaryTeal, width: 2)
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.fingerprint, size: 32),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
