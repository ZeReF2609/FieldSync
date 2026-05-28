import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'data/repositories/inspection_repository.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/sync_service.dart';
import 'features/inspections/cubit/inspections_cubit.dart';
import 'features/inspections/screens/inspection_list_screen.dart';

class FieldSyncApp extends StatelessWidget {
  final InspectionRepository repo;

  const FieldSyncApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService();
    final syncService = SyncService(repo: repo);

    return BlocProvider(
      create: (_) => InspectionsCubit(
        repo: repo,
        syncService: syncService,
        connectivityService: connectivityService,
      ),
      child: MaterialApp(
        title: 'Field Sync',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const InspectionListScreen(),
      ),
    );
  }
}
