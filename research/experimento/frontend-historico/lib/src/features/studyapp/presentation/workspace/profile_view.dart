import 'package:flutter/material.dart';

import '../../domain/studyapp_models.dart';
import '../../domain/password_policy.dart';
import '../password_dialogs.dart';
import '../widgets/studyapp_ui.dart';
import 'institutional_policies_view.dart';
import 'workspace_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    required this.viewModel,
    required this.onChangePassword,
    required this.onLogout,
    super.key,
  });
  final WorkspaceViewModel viewModel;
  final Future<bool> Function({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  })
  onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final profile = viewModel.data.profile;
    return ContentWidth(
      maxWidth: 720,
      child: CustomScrollView(
        key: const PageStorageKey('profile-scroll'),
        slivers: [
          const SliverToBoxAdapter(child: AppTopBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: SectionTitle(
                        'Meu Perfil',
                        subtitle:
                            'Gerencie suas informações, segurança e preferências.',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => showPrototypeMessage(
                        context,
                        'Edição de perfil preparada para persistência na API.',
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFF60A5FA),
                            child: Text(
                              _initials(profile.fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const StatusPill(
                                  label: 'Administrador',
                                  color: Color(0xFF60A5FA),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  profile.email,
                                  style: const TextStyle(
                                    color: Color(0xFFD9E5FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 26, color: Color(0xFF1B4A97)),
                      Row(
                        children: [
                          Expanded(
                            child: _profileValue('Equipe', profile.team),
                          ),
                          Container(
                            width: 1,
                            height: 45,
                            color: const Color(0xFF1B4A97),
                          ),
                          Expanded(
                            child: _profileValue(
                              'Perfil de acesso',
                              'Administrador da plataforma',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 45,
                            color: const Color(0xFF1B4A97),
                          ),
                          const Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Color(0xFFB8C7E8),
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: 5),
                                StatusPill(
                                  label: 'Ativo',
                                  color: Color(0xFF70F0A4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(context, Icons.person_outline, 'Dados pessoais', [
                  _line('E-mail', profile.email),
                  _line('Telefone', profile.phone),
                  _line('Cargo', profile.role),
                  _line('Organização', profile.organization),
                ]),
                const SizedBox(height: 12),
                _section(context, Icons.shield_outlined, 'Segurança da conta', [
                  _line(
                    'Senha',
                    '••••••••••',
                    action: 'Alterar',
                    onAction: () => showChangePasswordDialog(
                      context,
                      identity: PasswordIdentityInput(
                        email: profile.email,
                        firstName: profile.fullName.split(' ').first,
                        lastName: profile.fullName.split(' ').skip(1).join(' '),
                      ),
                      onChangePassword: (current, password, confirmation) =>
                          onChangePassword(
                            currentPassword: current,
                            newPassword: password,
                            confirmPassword: confirmation,
                          ),
                    ),
                  ),
                  _line(
                    'Autenticação em duas etapas',
                    profile.twoFactorEnabled ? 'Ativada' : 'Pendente',
                    action: 'Gerenciar',
                    success: profile.twoFactorEnabled,
                  ),
                  _line('Método 2FA', 'Aplicativo autenticador (TOTP)'),
                  _line(
                    'Cofre de segredos',
                    profile.vaultType.label,
                    action: 'Configurar',
                  ),
                ]),
                if (profile.canManagePolicies) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF0F5EF7),
                        child: Icon(Icons.policy_outlined, color: Colors.white),
                      ),
                      title: const Text(
                        'Políticas institucionais',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text(
                        'Cadastre versões e publique políticas vigentes.',
                        style: TextStyle(color: Color(0xFFB8C7E8)),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              InstitutionalPoliciesView(viewModel: viewModel),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _section(context, Icons.devices_outlined, 'Sessões ativas', [
                  _line(
                    'Este dispositivo',
                    'Android • Belo Horizonte',
                    success: true,
                  ),
                  _line('Última atividade', 'Agora'),
                ]),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFA7B1),
                    side: const BorderSide(color: Color(0xFFFF7C8B)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da demonstração'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    IconData icon,
    String title,
    List<Widget> children,
  ) => GlassCard(
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0F5EF7),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
        const Divider(height: 24, color: Color(0xFF1B4A97)),
        ...children,
      ],
    ),
  );
  Widget _line(
    String label,
    String value, {
    String? action,
    VoidCallback? onAction,
    bool success = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB8C7E8), fontSize: 12),
          ),
        ),
        if (success)
          const Padding(
            padding: EdgeInsets.only(right: 5),
            child: Icon(Icons.circle, color: Color(0xFF70F0A4), size: 9),
          ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
  Widget _profileValue(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB8C7E8), fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
  String _initials(String value) {
    final parts = value.split(' ');
    return '${parts.first.characters.first}${parts.length > 1 ? parts.last.characters.first : ''}'
        .toUpperCase();
  }
}
