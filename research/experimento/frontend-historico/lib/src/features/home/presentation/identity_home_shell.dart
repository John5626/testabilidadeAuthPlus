import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../public_registration/presentation/public_registration_view.dart';
import '../../user_management/presentation/user_management_view.dart';
import '../domain/app_status.dart';

class IdentityHomeShell extends StatefulWidget {
  const IdentityHomeShell({
    required this.dependencies,
    required this.status,
    super.key,
  });

  final AppDependencies dependencies;
  final AppStatus status;

  @override
  State<IdentityHomeShell> createState() => _IdentityHomeShellState();
}

class _IdentityHomeShellState extends State<IdentityHomeShell> {
  var _selectedPage = _IdentityPage.publicRegistration;

  @override
  Widget build(BuildContext context) {
    return switch (_selectedPage) {
      _IdentityPage.publicRegistration => PublicRegistrationView(
        dependencies: widget.dependencies,
        status: widget.status,
        onOpenUserManagement: () {
          setState(() => _selectedPage = _IdentityPage.userManagement);
        },
      ),
      _IdentityPage.userManagement => UserManagementView(
        dependencies: widget.dependencies,
        status: widget.status,
        onOpenPublicRegistration: () {
          setState(() => _selectedPage = _IdentityPage.publicRegistration);
        },
      ),
    };
  }
}

enum _IdentityPage { publicRegistration, userManagement }
