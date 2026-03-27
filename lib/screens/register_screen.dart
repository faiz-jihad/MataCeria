// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();

  String _gender = 'Laki-laki';
  String _education = 'SMA';
  String _occupation = 'Pelajar/Mahasiswa';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('err_agree_terms'.tr(context)), // Need to add to AppStrings
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        education: _education,
        occupation: _occupation,
      );

      if (success) {
        if (mounted) {
          _showSuccessSnackBar('reg_success_msg'.tr(context)); // Need to add to AppStrings
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'err_name_empty'.tr(context);
    }
    if (value.length < 3) {
      return 'err_name_short'.tr(context); // Add to AppStrings
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'err_email_empty'.tr(context);
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'err_email_invalid'.tr(context);
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'err_pass_empty'.tr(context);
    }
    if (value.length < 6) {
      return 'err_pass_long'.tr(context);
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'err_pass_complex'.tr(context); // Add to AppStrings
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'err_pass_empty'.tr(context);
    }
    if (value != _passwordController.text) {
      return 'err_pass_match'.tr(context);
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'err_age_empty'.tr(context); // Add to AppStrings
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'err_age_invalid'.tr(context); // Add to AppStrings
    }
    if (age < 5 || age > 100) {
      return 'err_age_range'.tr(context); // Add to AppStrings
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Curved Blue Header with Illustration (Matched with Login)
                Stack(
                  children: [
                    Container(
                      height: 380,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(60),
                          bottomRight: Radius.circular(60),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'MataCeria!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Image.asset(
                                'assets/images/onboarding_illustration2.png',
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Register Form Section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        
                        // Full Name Field
                        _buildSocialTextField(
                          controller: _nameController,
                          hintText: 'name_hint'.tr(context),
                          prefixIcon: Icons.person_outline,
                          validator: _validateName,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Email Field
                        _buildSocialTextField(
                          controller: _emailController,
                          hintText: 'email_hint'.tr(context),
                          prefixIcon: Icons.email_outlined,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        // Age Field
                        _buildSocialTextField(
                          controller: _ageController,
                          hintText: 'age_hint'.tr(context),
                          prefixIcon: Icons.cake_outlined,
                          validator: _validateAge,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        
                        // Gender Dropdown
                        _buildDropdownField(
                          value: _gender,
                          hintText: 'prof_gender'.tr(context),
                          prefixIcon: Icons.wc_outlined,
                          items: ['Laki-laki', 'Perempuan'],
                          onChanged: (val) => setState(() => _gender = val!),
                        ),
                        const SizedBox(height: 16),

                        // Education Dropdown
                        _buildDropdownField(
                          value: _education,
                          hintText: 'prof_education'.tr(context),
                          prefixIcon: Icons.school_outlined,
                          items: ['SD', 'SMP', 'SMA', 'D3', 'D4/S1', 'S2/S3', 'Lainnya'],
                          onChanged: (val) => setState(() => _education = val!),
                        ),
                        const SizedBox(height: 16),

                        // Occupation Dropdown
                        _buildDropdownField(
                          value: _occupation,
                          hintText: 'prof_job'.tr(context),
                          prefixIcon: Icons.work_outline,
                          items: ['Pelajar/Mahasiswa', 'Karyawan Swasta', 'PNS', 'Wiraswasta', 'Lainnya'],
                          onChanged: (val) => setState(() => _occupation = val!),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Password Field
                        _buildSocialTextField(
                          controller: _passwordController,
                          hintText: 'password_hint'.tr(context),
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password Field
                        _buildSocialTextField(
                          controller: _confirmPasswordController,
                          hintText: 'confirm_password_hint'.tr(context), // Add to AppStrings
                          prefixIcon: Icons.lock_reset_outlined,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: _validateConfirmPassword,
                        ),

                        const SizedBox(height: 24),
                        
                        // Terms and Conditions Matching Login style
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (value) => setState(() => _agreeTerms = value ?? false),
                              activeColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Expanded(
                              child: Text(
                                'agree_terms_text'.tr(context), // Add to AppStrings
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        
                        if (authProvider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),

                        const SizedBox(height: 24),
                        
                        // Main Register Button (Matched with Login)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'btn_register'.tr(context),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('already_have_account'.tr(context), style: const TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/login'),
                              child: Text(
                                'login_title'.tr(context),
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String hintText,
    required IconData prefixIcon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 22),
          ),
          hint: Text(hintText, style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}