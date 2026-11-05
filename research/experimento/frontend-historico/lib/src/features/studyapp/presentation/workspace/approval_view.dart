import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class ApprovalView extends StatelessWidget {
  const ApprovalView({
    required this.viewModel,
    required this.request,
    super.key,
  });
  final WorkspaceViewModel viewModel;
  final AccessRequest request;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 680,
        child: Column(
          children: [
            AppTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      'Aprovação de delegação',
                      subtitle:
                          'Analise solicitações e aprove ou rejeite acessos.',
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: StudyAppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.resource.iconLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.resource.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${request.resource.team} • ${request.resource.category}',
                                  style: const TextStyle(
                                    color: Color(0xFFC8D7FF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const StatusPill(
                            label: 'Crítico',
                            color: Color(0xFFFF8C8C),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section('Resumo da solicitação', [
                      _line(Icons.person, 'Solicitado por', request.requester),
                      _line(
                        Icons.security,
                        'Tipo de acesso',
                        request.accessType,
                      ),
                      _line(
                        Icons.schedule,
                        'Duração solicitada',
                        '${request.durationMinutes} min',
                      ),
                      _line(
                        Icons.calendar_today,
                        'Data da solicitação',
                        'Hoje, 09:41',
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _section('Justificativa', [
                      Text(
                        request.justification,
                        style: const TextStyle(
                          color: Color(0xFFD9E5FF),
                          height: 1.35,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _section('Política do recurso', const [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.policy_outlined, color: Color(0xFFC8D7FF)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '• Recurso crítico: requer aprovação manual\n• Delegação máxima: 30 min\n• Toda ação será auditada',
                              style: TextStyle(
                                color: Color(0xFFD9E5FF),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFF60A5FA),
                            child: Text(
                              'AS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aprovador responsável',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Administrador da equipe de TI',
                                  style: TextStyle(color: Color(0xFFC8D7FF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section('Decisão', [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () => _decide(context, true),
                              child: const Text('Aprovar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => showPrototypeMessage(
                                context,
                                'Solicitação devolvida para ajustes.',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Solicitar ajustes'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () => _decide(context, false),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6A2746),
                              ),
                              child: const Text('Rejeitar'),
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => showPrototypeMessage(
                        context,
                        'Trilha aberta com os eventos da solicitação.',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.manage_search),
                      label: const Text('Ver trilha de auditoria'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ao aprovar ou rejeitar, a decisão será registrada em auditoria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8FBEFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFC8D7FF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB8C7E8), fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Future<void> _decide(BuildContext context, bool approve) async {
    await viewModel.decideRequest(request.id, approve);
    if (context.mounted) {
      showPrototypeMessage(
        context,
        approve
            ? 'Acesso aprovado e usuário notificado.'
            : 'Solicitação rejeitada e usuário notificado.',
      );
      Navigator.pop(context);
    }
  }
}
