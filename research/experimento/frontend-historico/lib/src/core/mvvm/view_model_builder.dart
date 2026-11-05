import 'package:flutter/widgets.dart';

typedef ViewModelFactory<T extends ChangeNotifier> = T Function();

typedef ViewModelWidgetBuilder<T extends ChangeNotifier> =
    Widget Function(BuildContext context, T viewModel, Widget? child);

class ViewModelBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelBuilder({
    required this.create,
    required this.builder,
    this.onModelReady,
    this.child,
    this.autoDispose = true,
    super.key,
  });

  final ViewModelFactory<T> create;
  final ViewModelWidgetBuilder<T> builder;
  final ValueChanged<T>? onModelReady;
  final Widget? child;
  final bool autoDispose;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends ChangeNotifier>
    extends State<ViewModelBuilder<T>> {
  late final T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create();
    widget.onModelReady?.call(_viewModel);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      child: widget.child,
      builder: (context, child) {
        return widget.builder(context, _viewModel, child);
      },
    );
  }

  @override
  void dispose() {
    if (widget.autoDispose) {
      _viewModel.dispose();
    }
    super.dispose();
  }
}
