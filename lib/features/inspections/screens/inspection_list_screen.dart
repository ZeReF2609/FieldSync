import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/inspections_cubit.dart';
import '../cubit/inspections_state.dart';
import '../widgets/inspection_card.dart';
import 'create_inspection_screen.dart';
import 'inspection_detail_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InspectionsCubit>().loadInspections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Field Sync',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<InspectionsCubit, InspectionsState>(
            builder: (context, state) {
              if (state is! InspectionsLoaded) return const SizedBox.shrink();
              final hasPending =
                  state.pendingCount > 0 || state.failedCount > 0;
              if (!hasPending) return const SizedBox.shrink();

              return IconButton(
                tooltip: 'Reintentar sincronización',
                icon: state.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Badge(
                        label: Text('${state.pendingCount + state.failedCount}'),
                        child: const Icon(Icons.sync),
                      ),
                onPressed: state.isSyncing
                    ? null
                    : () => context.read<InspectionsCubit>().retrySync(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<InspectionsCubit, InspectionsState>(
        builder: (context, state) {
          return switch (state) {
            InspectionsInitial() || InspectionsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            InspectionsError(message: final msg) => _ErrorView(
                message: msg,
                onRetry: () =>
                    context.read<InspectionsCubit>().loadInspections(),
              ),
            InspectionsLoaded(inspections: final list) when list.isEmpty =>
              const _EmptyView(),
            InspectionsLoaded(inspections: final list) => RefreshIndicator(
                onRefresh: () =>
                    context.read<InspectionsCubit>().loadInspections(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final inspection = list[index];
                    final cubit = context.read<InspectionsCubit>();
                    return InspectionCard(
                      inspection: inspection,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionDetailScreen(
                            inspection: inspection,
                          ),
                        ),
                      ).then((_) => cubit.loadInspections()),
                    );
                  },
                ),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final cubit = context.read<InspectionsCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInspectionScreen()),
          ).then((_) => cubit.loadInspections());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva inspección'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin inspecciones aún',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca "+" para crear la primera.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
