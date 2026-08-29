import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_text_field.dart';

/// Result of the Add Context form.
class AddContextResult {
  const AddContextResult({required this.title, required this.content});

  final String title;
  final String content;
}

/// Bottom sheet form to add a RAG context document for a new chat.
///
/// Two fields: title + content. On submit it returns [AddContextResult];
/// the caller (ChatScreen) uploads the document to the backend.
class AddContextSheet extends StatefulWidget {
  const AddContextSheet({super.key});

  @override
  State<AddContextSheet> createState() => _AddContextSheetState();
}

/// Shows the add-context bottom sheet. Returns the submitted title/content
/// or null when dismissed.
Future<AddContextResult?> showAddContextSheet(BuildContext context) {
  return showModalBottomSheet<AddContextResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).extension<NeoTheme>()!.background,
    builder: (_) => const AddContextSheet(),
  );
}

class _AddContextSheetState extends State<AddContextSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      AddContextResult(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Padding(
      // Keep the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add context',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: neo.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Konteks ini akan dipakai di dalam sesi percakapan ini. '
                'AI akan menjawab berdasarkan isi konteks yang kamu berikan.',
                style: TextStyle(fontSize: 13, color: neo.inkMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Title',
                controller: _titleController,
                hint: 'mis. tentang-ceo',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Isi konteks',
                controller: _contentController,
                hint: 'Tulis informasi yang ingin dijadikan konteks AI...',
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Isi konteks wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Submit',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
