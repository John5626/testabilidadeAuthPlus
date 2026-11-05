import 'package:flutter/foundation.dart';

import '../domain/organization_registration.dart';
import '../domain/public_registration_repository.dart';

enum PublicRegistrationState { idle, submitting, success, failure }

class PublicRegistrationViewModel extends ChangeNotifier {
  PublicRegistrationViewModel({required this.repository});

  final PublicRegistrationRepository repository;

  PublicRegistrationState _state = PublicRegistrationState.idle;
  OrganizationAdminRegistration? _registration;
  String? _errorMessage;

  PublicRegistrationState get state => _state;
  OrganizationAdminRegistration? get registration => _registration;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _state == PublicRegistrationState.submitting;

  Future<void> register(RegisterOrganizationAdminInput input) async {
    _state = PublicRegistrationState.submitting;
    _registration = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _registration = await repository.registerOrganizationAdmin(input);
      _state = PublicRegistrationState.success;
    } catch (error) {
      _errorMessage = error.toString();
      _state = PublicRegistrationState.failure;
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == PublicRegistrationState.failure) {
      _state = PublicRegistrationState.idle;
    }
    notifyListeners();
  }
}
