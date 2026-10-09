import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/form_submit_state.dart';
import 'form_error_text.dart';

/// The bottom of an admin form: its full-width submit button (loading and
/// disabled while sending) and the form's error under it.
class FormSubmitSection extends StatelessWidget {
  const FormSubmitSection({
    super.key,
    required this.label,
    required this.icon,
    required this.state,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final FormSubmitState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.spaceL),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: LoadingButton(
            label: label,
            icon: icon,
            loading: state.submitting,
            onPressed: onPressed,
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppSizes.spaceS),
          FormErrorText(state.error),
        ],
      ],
    );
  }
}
