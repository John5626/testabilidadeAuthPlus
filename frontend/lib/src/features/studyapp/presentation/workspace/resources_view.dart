import 'package:flutter/material.dart';

import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'resource_detail_view.dart';
import 'resource_form_view.dart';
import 'workspace_view_model.dart';

class ResourcesView extends StatelessWidget {
  const ResourcesView({required this.viewModel, super.key});
  final WorkspaceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: 780,
      child: CustomScrollView(
        key: const PageStorageKey('resources-scroll'),
        slivers: [
          const SliverToBoxAdapter(child: AppTopBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverList.list(
              children: [
                const SectionTitle(
                  'Recursos TOTP',
                  subtitle: 'Gerencie e monitore seus recursos protegidos.',
                ),
                if (!viewModel.data.profile.resourceFeaturesAvailable) ...[
                  const SizedBox(height: 18),
                  const GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF60A5FA)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Os recursos autorizados não estão disponíveis nesta sessão. Atualize a lista ou confira seu vínculo com a equipe.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: viewModel.searchResources,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar recurso',
                          hintStyle: const TextStyle(color: Color(0xFF9EB3E0)),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFC8D7FF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0D2D6A),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B4A97),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (viewModel.repository.revelation == null)
                      FilledButton.icon(
                        onPressed:
                            viewModel.data.profile.resourceFeaturesAvailable
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ResourceFormView(viewModel: viewModel),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Novo'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Todos', 'Empresa', 'Equipe', 'Status']
                      .map(
                        (label) => FilterChip(
                          label: Text(label),
                          selected: label == 'Todos',
                          onSelected: (_) {},
                          selectedColor: const Color(0xFF174A9B),
                          backgroundColor: const Color(0xFF0D2D6A),
                          side: const BorderSide(color: Color(0xFF1B4A97)),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Lista de recursos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${viewModel.filteredResources.length} ativos',
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...viewModel.filteredResources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResourceCard(
                      resource: resource,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResourceDetailView(
                            viewModel: viewModel,
                            resource: resource,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.onTap});
  final ProtectedResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (resource.risk) {
      ResourceRisk.critical => const Color(0xFFFF8C8C),
      ResourceRisk.moderate => const Color(0xFF52DA97),
      ResourceRisk.restricted => const Color(0xFFFFB14D),
    };
    return Semantics(
      button: true,
      label: 'Abrir ${resource.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  resource.iconLabel,
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
                      resource.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      resource.team,
                      style: const TextStyle(color: Color(0xFFC8D7FF)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF9EB3E0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Último acesso: ${resource.lastAccessLabel}',
                            style: const TextStyle(
                              color: Color(0xFF9EB3E0),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(label: resource.criticalityLabel, color: color),
                  const SizedBox(height: 10),
                  const Icon(Icons.chevron_right, color: Color(0xFFD9E5FF)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
