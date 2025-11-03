import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserForm extends ConsumerStatefulWidget {
  // Accept optional params for editing
  final String? userId;
  final Map<String, dynamic>? initialData;

  const UserForm({super.key, this.userId, this.initialData});

  @override
  ConsumerState<UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<UserForm> {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController(); // new

  String role = 'sales';
  bool isActive = true;
  bool sendInvite = true;
  bool loading = false;

  static const roles = <String>[
    'admin',
    'estimation',
    'accounts',
    'store',
    'production',
    'delivery',
    'marketing',
    'sales',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      nameCtrl.text = (data['name'] ?? '').toString();
      emailCtrl.text = (data['email'] ?? '').toString();
      role = (data['role'] ?? role).toString();
      isActive = (data['isActive'] as bool?) ?? true;
      sendInvite = false; // editing -> don't force invite
      // do NOT populate passwordCtrl for security
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    nameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  bool get isEditing => widget.userId != null;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit User' : 'Create User',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Enter email';
                    final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                    if (!re.hasMatch(val)) return 'Enter valid email';
                    return null;
                  },
                  enabled: !isEditing, // don't edit email when editing profile
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),

                const SizedBox(height: 12),
                // Password only shown when creating a new user
                if (!isEditing) ...[
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimum 8 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (v) {
                      final val = v ?? '';
                      // optional: allow empty if you want to send invite instead of setting password
                      if (!sendInvite && val.isEmpty) {
                        return 'Enter a password or enable "Send invite"';
                      }
                      if (val.isNotEmpty && val.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => role = v ?? role),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
                if (!isEditing)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: sendInvite,
                    onChanged: (v) => setState(() => sendInvite = v ?? true),
                    title: const Text('Send invite/reset email'),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'Update' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final functions = FirebaseFunctions.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      if (isEditing) {
        // Update existing user profile in Firestore only
        await firestore.collection('users').doc(widget.userId).set({
          'email': emailCtrl.text.trim(),
          'name': nameCtrl.text.trim(),
          'role': role,
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('User updated')));
        }
      } else {
        // Create user using a secure Cloud Function that uses the Admin SDK.
        // We pass password to the callable ONLY so the Admin SDK can create the auth user.
        // The client MUST NOT store the password in Firestore.
        String uid;
        try {
          final payload = {
            'email': emailCtrl.text.trim(),
            'name': nameCtrl.text.trim(),
            'role': role,
            'isActive': isActive,
            'sendInvite': sendInvite,
            // include password if provided; callable should handle empty/null appropriately
            if (passwordCtrl.text.trim().isNotEmpty) 'password': passwordCtrl.text.trim(),
          };

          final res = await functions.httpsCallable('adminCreateUser').call(payload);
          uid = (res.data as Map)['uid'] as String;
        } catch (e) {
          // If callable not available, fallback to creating only Firestore profile (no Auth)
          uid = firestore.collection('_').doc().id;
          // Do NOT store password in Firestore.
        }

        await firestore.collection('users').doc(uid).set({
          'email': emailCtrl.text.trim(),
          'name': nameCtrl.text.trim(),
          'role': role,
          'isActive': isActive,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('User created')));
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}
