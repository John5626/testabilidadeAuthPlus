import 'package:flutter/foundation.dart';

import '../domain/managed_user.dart';
import '../domain/user_management_repository.dart';

enum UserManagementState { idle, loading, ready, submitting, failure }

class UserManagementViewModel extends ChangeNotifier {
  UserManagementViewModel({required this.repository});

  final UserManagementRepository repository;

  UserManagementState _state = UserManagementState.idle;
  List<ManagedUser> _users = const [];
  ManagedUser? _editingUser;
  ManagedUser? _latestCreatedUser;
  ManagedUser? _completedInvitationUser;
  String? _message;
  String? _errorMessage;
  UserManagementContext? _lastContext;
  String? _lastTeamFilter;

  UserManagementState get state => _state;
  List<ManagedUser> get users => _users;
  ManagedUser? get editingUser => _editingUser;
  ManagedUser? get latestCreatedUser => _latestCreatedUser;
  ManagedUser? get completedInvitationUser => _completedInvitationUser;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _state == UserManagementState.loading ||
      _state == UserManagementState.submitting;

  int get pendingCount =>
      _users.where((user) => user.status == UserStatus.pending).length;
  int get activeCount =>
      _users.where((user) => user.status == UserStatus.active).length;
  int get blockedCount =>
      _users.where((user) => user.status == UserStatus.blocked).length;
  int get disabledCount =>
      _users.where((user) => user.status == UserStatus.disabled).length;

  Future<void> loadUsers(
    UserManagementContext context, {
    String? teamId,
  }) async {
    if (!context.isComplete) {
      _showError('Informe organização, equipe e usuário ator.');
      return;
    }

    _state = UserManagementState.loading;
    _errorMessage = null;
    _message = null;
    _lastContext = context;
    _lastTeamFilter = teamId;
    notifyListeners();

    try {
      _users = await repository.listUsers(context, teamId: teamId);
      _state = UserManagementState.ready;
    } catch (error) {
      _state = UserManagementState.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> saveUser(
    UserManagementContext context, {
    required CreateManagedUserInput createInput,
    required UpdateManagedUserInput updateInput,
  }) async {
    if (!context.isComplete) {
      _showError('Informe organização, equipe e usuário ator.');
      return;
    }

    _state = UserManagementState.submitting;
    _errorMessage = null;
    _message = null;
    notifyListeners();

    try {
      if (_editingUser == null) {
        final created = await repository.createUser(context, createInput);
        _latestCreatedUser = created;
        _upsertUser(created.withoutInvitation());
        _message = 'Usuário cadastrado. Copie o token do convite agora.';
      } else {
        final updated = await repository.updateUser(
          context,
          _editingUser!.id,
          updateInput,
        );
        _upsertUser(updated);
        _editingUser = null;
        _message = 'Usuário atualizado.';
      }

      _state = UserManagementState.ready;
    } catch (error) {
      _state = UserManagementState.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> changeStatus(
    UserManagementContext context,
    ManagedUser user,
    UserStatus status,
  ) async {
    _state = UserManagementState.submitting;
    _errorMessage = null;
    _message = null;
    notifyListeners();

    try {
      final updated = await repository.changeStatus(context, user.id, status);
      _upsertUser(updated);
      _message = 'Status de ${updated.displayName} atualizado.';
      _state = UserManagementState.ready;
    } catch (error) {
      _state = UserManagementState.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> disableUser(
    UserManagementContext context,
    ManagedUser user,
  ) async {
    _state = UserManagementState.submitting;
    _errorMessage = null;
    _message = null;
    notifyListeners();

    try {
      await repository.disableUser(context, user.id);
      _upsertUser(user.copyWith(status: UserStatus.disabled));
      _message = 'Usuário desativado.';
      _state = UserManagementState.ready;
    } catch (error) {
      _state = UserManagementState.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> completeInvitation({
    required String token,
    required String password,
    required String passwordConfirmation,
    required bool personalDataConsentAccepted,
  }) async {
    if (token.trim().isEmpty ||
        password.isEmpty ||
        password != passwordConfirmation) {
      _showError(
        'Informe token, senha e confirmação válida para concluir o convite.',
      );
      return;
    }
    if (!personalDataConsentAccepted) {
      _showError('O convidado deve confirmar o tratamento de seus dados.');
      return;
    }

    _state = UserManagementState.submitting;
    _errorMessage = null;
    _message = null;
    notifyListeners();

    try {
      final user = await repository.completeInvitation(
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
        personalDataConsentAccepted: personalDataConsentAccepted,
      );
      _completedInvitationUser = user;
      _upsertUser(user);
      _message =
          'Convite concluído. O usuário continua sujeito ao aceite de termos.';
      _state = UserManagementState.ready;
    } catch (error) {
      _state = UserManagementState.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> refreshLastQuery() async {
    final context = _lastContext;
    if (context == null) {
      return;
    }

    await loadUsers(context, teamId: _lastTeamFilter);
  }

  void startEdit(ManagedUser user) {
    _editingUser = user;
    _errorMessage = null;
    _message = null;
    notifyListeners();
  }

  void cancelEdit() {
    _editingUser = null;
    notifyListeners();
  }

  void dismissInvitationToken() {
    _latestCreatedUser = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _message = null;
    notifyListeners();
  }

  void _upsertUser(ManagedUser user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) {
      _users = [user, ..._users];
      return;
    }

    final updated = [..._users];
    updated[index] = user;
    _users = updated;
  }

  void _showError(String message) {
    _errorMessage = message;
    _message = null;
    _state = UserManagementState.failure;
    notifyListeners();
  }
}
