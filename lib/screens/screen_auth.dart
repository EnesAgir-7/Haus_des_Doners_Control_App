import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_assets.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/widgets/language_button.dart';
import 'package:provider/provider.dart';

import '../../translations/locale_keys.g.dart';
import '../providers/provider_auth.dart';
import '../widgets/custom_field.dart';

class ScreenAuth extends StatefulWidget {
  const ScreenAuth({super.key});

  @override
  State<ScreenAuth> createState() => _ScreenAuthState();
}

class _ScreenAuthState extends State<ScreenAuth> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: "sara.khan@example.com");
    _passwordController = TextEditingController(text: "123456");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderAuth>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.primaryDark,
          appBar: AppBar(actions: const [LanguageButton()]),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(kAppLogo, width: 300),
                        const SizedBox(height: 16),
                        Text(
                          LocaleKeys.welcome.tr(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocaleKeys.login_to_account.tr(),
                          style: const TextStyle(
                            color: AppColors.lightGrey,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),

                        CustomField(
                          controller: _emailController,
                          label: LocaleKeys.email.tr(),
                          hint: LocaleKeys.email_hint.tr(),
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return LocaleKeys.email_required.tr();
                            }
                            if (!value.contains("@")) {
                              return LocaleKeys.email_invalid.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomField(
                          controller: _passwordController,
                          label: LocaleKeys.password.tr(),
                          hint: LocaleKeys.password_hint.tr(),
                          icon: Icons.lock_outline,
                          obscureText: provider.obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              provider.obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.lightGrey,
                            ),
                            onPressed: () {
                              provider.togglePasswordVisibility();
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return LocaleKeys.password_required.tr();
                            }
                            if (value.length < 6) {
                              return LocaleKeys.password_min_length.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              LocaleKeys.forgot_password.tr(),
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      bool success = await provider.login(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text
                                            .trim(),
                                      );

                                      if (!success && provider.error != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(provider.error!),
                                          ),
                                        );
                                      }
                                    }
                                  },

                            child: provider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    LocaleKeys.login.tr(),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
