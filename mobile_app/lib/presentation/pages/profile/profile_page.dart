import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            if (_nameController.text.isEmpty && state.profile.name != null) {
              _nameController.text = state.profile.name!;
            }
            _selectedGender ??= state.profile.gender;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (state.profile.name ?? state.profile.email)[0].toUpperCase(),
                    style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.profile.email,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: l10n.gender,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(l10n.male)),
                    DropdownMenuItem(value: 'female', child: Text(l10n.female)),
                    DropdownMenuItem(value: 'other', child: Text(l10n.other)),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _onSaveProfile,
                  child: Text(l10n.save),
                ),
              ],
            );
          }

          return Center(
            child: FilledButton(
              onPressed: () => context.read<ProfileBloc>().add(const LoadProfile()),
              child: Text(l10n.retry),
            ),
          );
        },
      ),
    );
  }

  void _onSaveProfile() {
    context.read<ProfileBloc>().add(UpdateProfile(
      name: _nameController.text.trim(),
      gender: _selectedGender,
    ));
  }
}
