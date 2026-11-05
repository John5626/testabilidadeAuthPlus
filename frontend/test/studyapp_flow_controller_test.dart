import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/studyapp/data/mock_studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/domain/auth_session_store.dart';
import 'package:frontend/src/features/studyapp/domain/authentication.dart';
import 'package:frontend/src/features/studyapp/domain/studyapp_models.dart';
import 'package:frontend/src/features/studyapp/domain/studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/presentation/studyapp_flow_controller.dart';
import 'package:frontend/src/features/public_registration/domain/organization_registration.dart';
import 'package:frontend/src/features/public_registration/domain/public_registration_repository.dart';

void main() {
  test('cadastro persiste no backend e encaminha para o login', () async {
    final registrationRepository = _FakePublicRegistrationRepository();
    final controller = StudyAppFlowController(
      repository: MockStudyAppRepository(),
      publicRegistrationRepository: registrationRepository,
      authenticationRepository: _FakeAuthenticationRepository(
        _authenticatedSession,
      ),
      sessionStore: MemoryAuthSessionStore(),
    );

    controller.openRegistration();
    expect(controller.stage, StudyAppStage.registration);

    final registered = await controller.register(
      const RegistrationDraft(
        firstName: 'Ana',
        lastName: 'Admin',
        email: 'fixture-24d4b96f58@example.invalid',
        password: 'SenhaForte123!',
        passwordConfirmation: 'SenhaForte123!',
        organizationName: 'Empresa',
        organizationDomain: 'empresa.com',
        teamName: 'TI',
        personalDataConsentAccepted: true,
      ),
    );

    expect(registered, isTrue);
    expect(controller.stage, StudyAppStage.login);
    expect(controller.noticeMessage, contains('Entre com suas credenciais'));
    expect(registrationRepository.calls, 1);
    expect(registrationRepository.input?.firstName, 'Ana');
    expect(registrationRepository.input?.lastName, 'Admin');
    expect(
      registrationRepository.input?.passwordConfirmation,
      'SenhaForte123!',
    );
    expect(registrationRepository.input?.personalDataConsentAccepted, isTrue);
  });

  test('repositório mockado mantém recurso criado atrás do contrato', () async {
    final repository = MockStudyAppRepository();

    await repository.createResource(
      name: 'GitHub Produção',
      description: 'Repositórios críticos da organização.',
      category: 'Produtividade',
      risk: ResourceRisk.critical,
      provisioning: 'QR Code',
    );

    final workspace = await repository.loadWorkspace();
    expect(workspace.resources.first.name, 'GitHub Produção');
    expect(workspace.auditEvents.first.title, 'Recurso cadastrado');
  });

  test('convite guarda somente resumo e devolve token transacional', () async {
    final repository = MockStudyAppRepository();

    final receipt = await repository.inviteTeamUser(
      const InviteTeamUserInput(
        teamId: 'team-ti',
        firstName: 'Beatriz',
        lastName: 'Exemplo',
        email: 'fixture-255befc5ec@example.invalid',
        teamRole: 'Membro',
        profiles: {'Membro equipe'},
      ),
    );

    final workspace = await repository.loadWorkspace();
    expect(receipt.oneTimeToken, startsWith('studyapp-invite-'));
    expect(receipt.invitation.status, 'PENDENTE');
    expect(
      workspace.invitations.any(
        (invitation) =>
            invitation.email == 'fixture-255befc5ec@example.invalid',
      ),
      isTrue,
    );
    expect(
      workspace.members
          .firstWhere(
            (member) => member.email == 'fixture-255befc5ec@example.invalid',
          )
          .status,
      TeamMemberStatus.pending,
    );
  });

  test(
    'Admin organização cria e desativa equipe preservando o registro',
    () async {
      final repository = MockStudyAppRepository();

      final created = await repository.saveTeam(
        const SaveOrganizationTeamInput(
          name: 'Pesquisa e Inovação',
          description: 'Projetos institucionais de pesquisa aplicada.',
          responsibleUserId: 'member-ana',
        ),
      );
      await repository.setTeamStatus(
        teamId: created.id,
        status: TeamStatus.inactive,
      );

      final workspace = await repository.loadWorkspace();
      final saved = workspace.teams.firstWhere((team) => team.id == created.id);
      expect(saved.status, TeamStatus.inactive);
      expect(saved.name, 'Pesquisa e Inovação');
      expect(workspace.auditEvents.first.title, 'Equipe desativada');
    },
  );

  test(
    'convidado sem conta cria credencial e aceita convite uma vez',
    () async {
      final repository = MockStudyAppRepository();

      final preview = await repository.validateTeamInvitation(
        'studyapp-demo-carlos',
      );
      expect(preview.accountExists, isFalse);
      expect(preview.teamName, 'Tecnologia da Informação');

      final accepted = await repository.acceptTeamInvitation(
        const AcceptTeamInvitationInput(
          token: 'studyapp-demo-carlos',
          password: 'SenhaForte123!',
          passwordConfirmation: 'SenhaForte123!',
          personalDataConsentAccepted: true,
        ),
      );
      expect(accepted.accountCreated, isTrue);
      expect(accepted.requiresFirstAccess, isTrue);

      final workspace = await repository.loadWorkspace();
      expect(
        workspace.invitations
            .firstWhere((item) => item.id == 'invite-carlos')
            .status,
        'USADO',
      );
      expect(
        workspace.members
            .firstWhere(
              (item) => item.email == 'fixture-2b946b3936@example.invalid',
            )
            .status,
        TeamMemberStatus.active,
      );
      expect(
        () => repository.validateTeamInvitation('studyapp-demo-carlos'),
        throwsA(isA<MockRepositoryException>()),
      );
    },
  );

  test('convidado com conta existente aceita somente o novo vínculo', () async {
    final repository = MockStudyAppRepository();

    final preview = await repository.validateTeamInvitation(
      'studyapp-demo-marina',
    );
    expect(preview.accountExists, isTrue);
    expect(preview.requiresTermsAcceptance, isFalse);

    final accepted = await repository.acceptTeamInvitation(
      const AcceptTeamInvitationInput(
        token: 'studyapp-demo-marina',
        password: 'StudyApp123!',
        passwordConfirmation: 'StudyApp123!',
        personalDataConsentAccepted: true,
      ),
    );
    expect(accepted.accountCreated, isFalse);
    expect(accepted.teamName, 'Financeiro');
  });

  test('link abre convite e descarta token ao sair do fluxo', () {
    final controller = StudyAppFlowController(
      repository: MockStudyAppRepository(),
      authenticationRepository: _FakeAuthenticationRepository(
        _authenticatedSession,
      ),
      sessionStore: MemoryAuthSessionStore(),
    );

    controller.openInvitationFromLink('token-recebido-por-email');
    expect(controller.stage, StudyAppStage.invitation);
    expect(controller.invitationToken, 'token-recebido-por-email');

    controller.openLanding();
    expect(controller.stage, StudyAppStage.landing);
    expect(controller.invitationToken, isNull);
    expect(controller.invitationPreview, isNull);
  });

  group('login real', () {
    test('sessão restaurada abre o workspace sem novo login', () async {
      final sessionStore = MemoryAuthSessionStore()
        ..startSession(_authenticatedSession);
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: _FakeAuthenticationRepository(
          _authenticatedSession,
        ),
        sessionStore: sessionStore,
      );

      await controller.resumeSession();

      expect(controller.stage, StudyAppStage.workspace);
      expect(controller.workspace, isNotNull);
    });

    test('sessão recusada na reabertura volta ao login', () async {
      final sessionStore = MemoryAuthSessionStore()
        ..startSession(_authenticatedSession);
      final controller = StudyAppFlowController(
        repository: _InvalidSessionRepository(),
        authenticationRepository: _FakeAuthenticationRepository(
          _authenticatedSession,
        ),
        sessionStore: sessionStore,
      );

      await controller.resumeSession();

      expect(controller.stage, StudyAppStage.login);
      expect(sessionStore.session, isNull);
    });

    test('mantém somente access token e libera workspace no sucesso', () async {
      final sessionStore = MemoryAuthSessionStore();
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: _FakeAuthenticationRepository(
          _authenticatedSession,
        ),
        sessionStore: sessionStore,
      );

      controller.openLogin();
      final success = await controller.signIn(
        email: 'fixture-04f8996da7@example.invalid',
        password: 'senha privada',
      );

      expect(success, isTrue);
      expect(controller.stage, StudyAppStage.workspace);
      expect(sessionStore.session?.accessToken, 'access-token');
      expect(sessionStore.challenge, isNull);
    });

    test('challenge de termos não cria sessão nem libera workspace', () async {
      final sessionStore = MemoryAuthSessionStore();
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: _FakeAuthenticationRepository(
          _challenge(AuthChallengeType.termsAcceptanceRequired),
        ),
        sessionStore: sessionStore,
      );

      final success = await controller.signIn(
        email: 'fixture-04f8996da7@example.invalid',
        password: 'senha privada',
      );

      expect(success, isTrue);
      expect(controller.stage, StudyAppStage.policyOnboarding);
      expect(controller.workspace, isNull);
      expect(sessionStore.session, isNull);
      expect(
        sessionStore.challenge?.type,
        AuthChallengeType.termsAcceptanceRequired,
      );
      expect(controller.pendingPolicies, hasLength(1));

      final accepted = await controller.acceptRequiredPolicies();
      expect(accepted, isTrue);
      expect(controller.stage, StudyAppStage.workspace);
      expect(sessionStore.challenge, isNull);
      expect(sessionStore.session, _authenticatedSession);
    });

    test('challenge de MFA fica isolado e preparado para DEV-106', () async {
      final sessionStore = MemoryAuthSessionStore();
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: _FakeAuthenticationRepository(
          _challenge(AuthChallengeType.mfaRequired),
        ),
        sessionStore: sessionStore,
      );

      await controller.signIn(
        email: 'fixture-04f8996da7@example.invalid',
        password: 'senha privada',
      );

      expect(controller.stage, StudyAppStage.mfaChallenge);
      expect(controller.workspace, isNull);
      expect(sessionStore.session, isNull);
      expect(sessionStore.challenge?.type, AuthChallengeType.mfaRequired);

      controller.leaveAuthenticationChallenge();
      expect(controller.stage, StudyAppStage.login);
      expect(sessionStore.challenge, isNull);
    });

    test(
      'MFA válido cria sessão ACCESS e somente então libera workspace',
      () async {
        final sessionStore = MemoryAuthSessionStore();
        final authentication = _FakeAuthenticationRepository(
          _challenge(AuthChallengeType.mfaRequired),
        );
        final controller = StudyAppFlowController(
          repository: MockStudyAppRepository(),
          authenticationRepository: authentication,
          sessionStore: sessionStore,
        );

        await controller.signIn(
          email: 'fixture-04f8996da7@example.invalid',
          password: 'senha privada',
        );
        final verified = await controller.verifyMfa('123456');

        expect(verified, isTrue);
        expect(authentication.mfaCodes, ['123456']);
        expect(controller.stage, StudyAppStage.workspace);
        expect(controller.workspace, isNotNull);
        expect(sessionStore.challenge, isNull);
        expect(sessionStore.session?.accessToken, 'access-token');
      },
    );

    test(
      'MFA inválido mantém challenge isolado e workspace bloqueado',
      () async {
        final sessionStore = MemoryAuthSessionStore();
        final authentication = _FakeAuthenticationRepository(
          _challenge(AuthChallengeType.mfaRequired),
          mfaError: const InvalidMfaCodeException(),
        );
        final controller = StudyAppFlowController(
          repository: MockStudyAppRepository(),
          authenticationRepository: authentication,
          sessionStore: sessionStore,
        );

        await controller.signIn(
          email: 'fixture-04f8996da7@example.invalid',
          password: 'senha privada',
        );
        final verified = await controller.verifyMfa('123456');

        expect(verified, isFalse);
        expect(controller.stage, StudyAppStage.mfaChallenge);
        expect(controller.workspace, isNull);
        expect(sessionStore.session, isNull);
        expect(sessionStore.challenge, isNotNull);
        expect(
          controller.errorMessage,
          'Código inválido ou expirado. Tente novamente.',
        );
      },
    );

    test(
      'conflito no aceite recarrega versões e exige novo consentimento',
      () async {
        final authentication = _FakeAuthenticationRepository(
          _challenge(AuthChallengeType.termsAcceptanceRequired),
          acceptError: const RequiredPoliciesChangedException(),
          policies: [_requiredPolicy, _updatedRequiredPolicy],
        );
        final controller = StudyAppFlowController(
          repository: MockStudyAppRepository(),
          authenticationRepository: authentication,
          sessionStore: MemoryAuthSessionStore(),
        );

        await controller.signIn(
          email: 'fixture-04f8996da7@example.invalid',
          password: 'senha privada',
        );
        final accepted = await controller.acceptRequiredPolicies();

        expect(accepted, isFalse);
        expect(controller.stage, StudyAppStage.policyOnboarding);
        expect(controller.pendingPolicies, hasLength(1));
        expect(controller.pendingPolicies.single.version, '2.0');
        expect(
          controller.errorMessage,
          'As políticas foram atualizadas. Revise o conteúdo antes de aceitar.',
        );
      },
    );

    test('credencial inválida usa resposta uniforme e limpa estado', () async {
      final sessionStore = MemoryAuthSessionStore();
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: _ThrowingAuthenticationRepository(
          const InvalidCredentialsException(),
        ),
        sessionStore: sessionStore,
      );

      final success = await controller.signIn(
        email: 'fixture-04f8996da7@example.invalid',
        password: 'senha privada',
      );

      expect(success, isFalse);
      expect(controller.errorMessage, 'E-mail ou senha inválidos.');
      expect(controller.stage, StudyAppStage.landing);
      expect(sessionStore.session, isNull);
      expect(sessionStore.challenge, isNull);
    });

    test('ignora novo envio enquanto o login está em andamento', () async {
      final completer = Completer<AuthenticationResult>();
      final authentication = _PendingAuthenticationRepository(completer);
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: authentication,
        sessionStore: MemoryAuthSessionStore(),
      );

      final first = controller.signIn(
        email: 'fixture-04f8996da7@example.invalid',
        password: 'senha privada',
      );
      final second = await controller.signIn(
        email: 'fixture-04f8996da7@example.invalid',
        password: 'senha privada',
      );

      expect(second, isFalse);
      expect(authentication.calls, 1);
      completer.complete(_authenticatedSession);
      expect(await first, isTrue);
    });
  });
}

final _authenticatedSession = AuthenticatedSession(
  accessToken: 'access-token',
  tokenType: 'Bearer',
  expiresAt: DateTime.utc(2099),
);

final _requiredPolicy = RequiredPolicy(
  policyVersionId: '11111111-1111-1111-1111-111111111111',
  policyCode: 'PRIVACY',
  title: 'Política de Privacidade',
  type: 'PRIVACIDADE',
  version: '1.0',
  content: 'Conteúdo vigente.',
  contentHash:
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  effectiveAt: DateTime.utc(2026, 9),
  publishedAt: DateTime.utc(2026, 8, 20),
);

final _updatedRequiredPolicy = RequiredPolicy(
  policyVersionId: '22222222-2222-2222-2222-222222222222',
  policyCode: 'PRIVACY',
  title: 'Política de Privacidade',
  type: 'PRIVACIDADE',
  version: '2.0',
  content: 'Conteúdo atualizado.',
  contentHash:
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  effectiveAt: DateTime.utc(2026, 9),
  publishedAt: DateTime.utc(2026, 8, 20),
);

AuthenticationChallenge _challenge(AuthChallengeType type) {
  return AuthenticationChallenge(
    type: type,
    challengeToken: 'challenge-token',
    tokenType: type == AuthChallengeType.termsAcceptanceRequired
        ? 'Bearer'
        : null,
    expiresAt: DateTime.utc(2099),
  );
}

class _FakeAuthenticationRepository implements AuthenticationRepository {
  _FakeAuthenticationRepository(
    this.result, {
    List<RequiredPolicy>? policies,
    this.acceptError,
    this.mfaError,
  }) : policies = policies ?? [_requiredPolicy];

  final AuthenticationResult result;
  final List<RequiredPolicy> policies;
  final Object? acceptError;
  final Object? mfaError;
  int policyLoads = 0;
  final List<String> mfaCodes = [];

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() async => [_requiredPolicy];

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async => result;

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) async {
    final index = policyLoads.clamp(0, policies.length - 1);
    policyLoads += 1;
    return [policies[index]];
  }

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) async {
    if (acceptError != null) throw acceptError!;
    return _authenticatedSession;
  }

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) async {
    mfaCodes.add(code);
    if (mfaError != null) throw mfaError!;
    return _authenticatedSession;
  }

  @override
  Future<void> requestPasswordRecovery({required String email}) async {}

  @override
  Future<void> previewPasswordRecovery({required String token}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {}

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {}
}

class _ThrowingAuthenticationRepository implements AuthenticationRepository {
  _ThrowingAuthenticationRepository(this.error);

  final Object error;

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() =>
      throw UnimplementedError();

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async => throw error;

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordRecovery({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> previewPasswordRecovery({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();
}

class _PendingAuthenticationRepository implements AuthenticationRepository {
  _PendingAuthenticationRepository(this.completer);

  final Completer<AuthenticationResult> completer;
  int calls = 0;

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() =>
      throw UnimplementedError();

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) {
    calls += 1;
    return completer.future;
  }

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordRecovery({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> previewPasswordRecovery({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();
}

class _FakePublicRegistrationRepository
    implements PublicRegistrationRepository {
  var calls = 0;
  RegisterOrganizationAdminInput? input;

  @override
  Future<OrganizationAdminRegistration> registerOrganizationAdmin(
    RegisterOrganizationAdminInput input,
  ) async {
    calls += 1;
    this.input = input;
    return const OrganizationAdminRegistration(
      organizationId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
      organizationName: 'Empresa',
      teamId: 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb',
      teamName: 'TI',
      admin: RegisteredOrganizationAdmin(
        id: 'cccccccc-cccc-4ccc-cccc-cccccccccccc',
        email: 'fixture-24d4b96f58@example.invalid',
        displayName: 'Ana Admin',
        status: 'PENDING',
        teamRole: 'RESPONSAVEL',
        profiles: ['ADMIN_ORGANIZACAO'],
        termsAcceptanceRequired: true,
      ),
    );
  }
}

class _InvalidSessionRepository extends MockStudyAppRepository {
  @override
  Future<WorkspaceData> loadWorkspace() async {
    throw const IdentitySessionInvalidException();
  }
}
