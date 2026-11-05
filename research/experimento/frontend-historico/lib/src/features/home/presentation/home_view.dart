import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/mvvm/view_model_builder.dart';
import 'identity_home_shell.dart';
import 'home_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>(
      create: () => HomeViewModel(repository: dependencies.appStatusRepository),
      onModelReady: (viewModel) => viewModel.load(),
      builder: (context, viewModel, child) {
        return _HomeContent(dependencies: dependencies, viewModel: viewModel);
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.dependencies, required this.viewModel});

  final AppDependencies dependencies;
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return switch (viewModel.state) {
      HomeViewState.idle || HomeViewState.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      HomeViewState.ready => _ReadyState(
        dependencies: dependencies,
        viewModel: viewModel,
      ),
      HomeViewState.failure => Scaffold(
        appBar: AppBar(title: const Text('StudyApp')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _FailureState(viewModel: viewModel),
          ),
        ),
      ),
    };
  }
}

class _ReadyState extends StatelessWidget {
  const _ReadyState({required this.dependencies, required this.viewModel});

  final AppDependencies dependencies;
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final status = viewModel.status;

    if (status == null) {
      return const SizedBox.shrink();
    }

    return IdentityHomeShell(dependencies: dependencies, status: status);
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        viewModel.errorMessage ?? 'Erro inesperado.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
