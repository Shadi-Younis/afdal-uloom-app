import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/student_summary.dart';
import '../application/students_filter_controller.dart';
import 'widgets/admin_async_view.dart';
import '../../../core/widgets/common/account_button.dart';
import '../../../core/widgets/common/logout_button.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import 'widgets/students_filter_bar.dart';
import 'widgets/students_list.dart';

/// Every student by code, with search and a filter per halaqa. [halaqaId]
/// (from AppRoutes.adminStudentsOfHalaqa) selects that halaqa's chip.
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key, this.halaqaId});

  final String? halaqaId;

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  @override
  void initState() {
    super.initState();
    _selectHalaqa();
  }

  @override
  void didUpdateWidget(StudentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab stays alive, so a later link to another halaqa arrives here.
    if (widget.halaqaId != oldWidget.halaqaId) _selectHalaqa();
  }

  void _selectHalaqa() {
    final halaqaId = widget.halaqaId;
    if (halaqaId == null) return;
    // After the frame: providers cannot change while widgets build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(studentsFilterControllerProvider.notifier).setHalaqa(halaqaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    void add() => context.push(AppRoutes.adminNewStudent);
    return AppPageScaffold(
      actions: const [AccountButton(), LogoutButton()],
      title: AppStrings.adminNavStudents,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(AppStrings.addStudent),
      ),
      body: AdminAsyncView(
        value: ref.watch(studentSummariesProvider),
        builder: (context, students) => students.isEmpty
            ? EmptyState(
                message: AppStrings.noStudents,
                actionLabel: AppStrings.addStudent,
                onAction: add,
              )
            : const Column(
                children: [
                  StudentsFilterBar(),
                  Expanded(child: StudentsList()),
                ],
              ),
      ),
    );
  }
}
