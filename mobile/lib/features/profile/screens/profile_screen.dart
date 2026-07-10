import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/subscriptions_service.dart';
import '../../subscriptions/providers/plans_provider.dart';
import '../../subscriptions/widgets/payment_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/widgets/keyboard_scroll_view.dart';
import '../../../core/layout/responsive_center.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/profile_hub_widgets.dart';
import '../../listings/providers/my_listings_provider.dart';
import '../../listings/screens/create_listing_screen.dart';
import '../../listings/utils/delete_listing_helper.dart';
import '../../listings/widgets/my_listing_tile.dart';
import '../../admin/widgets/admin_collapsible_payment_settings.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isSaving = false;
  String? _changingPlanId;
  bool _infoExpanded = false;
  bool _subscriptionExpanded = false;
  bool _securityExpanded = false;
  String? _syncedProfileKey;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _syncFieldsFromUser(UserModel user) {
    final key =
        '${user.id}|${user.name}|${user.phone ?? ''}|${user.avatarUrl ?? ''}|${user.plan}';
    if (_syncedProfileKey == key) return;
    _syncedProfileKey = key;
    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
  }

  Future<void> _pickAvatar() async {
    if (kIsWeb) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) return;

    setState(() => _isSaving = true);
    try {
      final user =
          await ref.read(usersServiceProvider).uploadAvatar(file.path);
      await ref.read(authStateProvider.notifier).setUser(user);
      _syncFieldsFromUser(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).profilePhotoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e, ref.read(stringsProvider)))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final strings = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.person_remove, color: AppColors.accentRed),
            title: Text(strings.deleteAccountTitle),
            content: Text(strings.deleteAccountMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.delete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authStateProvider.notifier).deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.accountDeleted)),
      );
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e, ref.read(stringsProvider))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().length < 2) return;
    setState(() => _isSaving = true);
    try {
      final user = await ref.read(usersServiceProvider).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      await ref.read(authStateProvider.notifier).setUser(user);
      _syncFieldsFromUser(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e, ref.read(stringsProvider)))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _userAvatarWidget({
    required UserModel user,
    required String? avatarUrl,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (!kIsWeb)
            Positioned(
              bottom: -2,
              right: -2,
              child: Material(
                color: AppColors.accentGold,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _isSaving ? null : _pickAvatar,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppSettings({
    required AppStrings strings,
    required AppLocale locale,
  }) {
    final themePref = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeader(title: strings.appSettings),
        ProfileSettingsTile(
          leadingIcon: Icons.language,
          leadingColor: AppColors.primaryBlue,
          title: strings.defaultLanguage,
          trailing: profileLocaleTrailing(locale),
          onTap: () => showProfileLanguagePicker(
            context: context,
            strings: strings,
            current: locale,
            onSelected: (loc) =>
                ref.read(localeProvider.notifier).setLocale(loc),
          ),
        ),
        const SizedBox(height: 8),
        ProfileSettingsTile(
          leadingIcon: themePref == AppThemePreference.dark
              ? Icons.dark_mode
              : Icons.wb_sunny_outlined,
          leadingColor: themePref == AppThemePreference.dark
              ? Colors.indigo
              : Colors.amber.shade700,
          title: themePref == AppThemePreference.dark
              ? strings.darkMode
              : strings.lightMode,
          trailing: Icon(
            Icons.palette_outlined,
            color: AppColors.accentRed.withValues(alpha: 0.85),
          ),
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ],
    );
  }

  Widget _buildAdminSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeader(title: strings.adminSectionTitle),
        ProfileLinkTile(
          icon: Icons.admin_panel_settings_rounded,
          leadingColor: AppColors.primaryBlue,
          title: strings.adminDashboardLink,
          subtitle: strings.adminDashboardSubtitle,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                color: Color(0xFF8A6D00),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          onTap: () => context.push('/admin'),
        ),
        const SizedBox(height: 12),
        const AdminCollapsiblePaymentSettings(),
      ],
    );
  }

  Widget _buildAboutSupport(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeader(title: strings.aboutAndSupport),
        ProfileLinkTile(
          icon: Icons.shield_outlined,
          title: strings.privacyPolicy,
          onTap: () => showProfileInfoSheet(
            context: context,
            title: strings.privacyPolicy,
            body: strings.privacyPolicyBody,
            actionLabel: strings.openWebsite,
            onAction: () => _launchUri(strings.privacyPolicyUrl),
          ),
        ),
        const SizedBox(height: 8),
        ProfileLinkTile(
          icon: Icons.description_outlined,
          title: strings.termsOfUse,
          onTap: () => showProfileInfoSheet(
            context: context,
            title: strings.termsOfUse,
            body: strings.termsBody,
            actionLabel: strings.openWebsite,
            onAction: () => _launchUri(strings.termsOfUseUrl),
          ),
        ),
        const SizedBox(height: 8),
        ProfileLinkTile(
          icon: Icons.mail_outline,
          title: strings.contactUs,
          onTap: () => showProfileInfoSheet(
            context: context,
            title: strings.contactUs,
            body: strings.contactBody,
            actionLabel: strings.sendSupportEmail,
            onAction: () => _launchSupportEmail(strings),
          ),
        ),
        const SizedBox(height: 8),
        ProfileLinkTile(
          icon: Icons.info_outline,
          title: strings.aboutApp,
          onTap: () => showAboutAppSheet(
            context: context,
            strings: strings,
          ),
        ),
      ],
    );
  }

  Future<void> _launchSupportEmail(AppStrings strings) async {
    final uri = Uri(
      scheme: 'mailto',
      path: strings.supportEmail,
      queryParameters: {'subject': 'Support Souk Tchad'},
    );
    await _launchUri(uri.toString());
  }

  Future<void> _launchUri(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(url)),
      );
    }
  }

  Future<void> _logout() async {
    final strings = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(strings.logout),
            content: Text(strings.logoutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(strings.logout),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    await ref.read(authStateProvider.notifier).logout();
  }

  void _openLoginRegister() {
    showLoginModal(context);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    ref.read(shellTabIndexProvider.notifier).setIndex(0);
  }

  PreferredSizeWidget _profileAppBar(AppStrings strings, {bool showLogout = false}) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: _goBack,
      ),
      title: Text(strings.profile),
      actions: [
        if (showLogout)
          IconButton(
            tooltip: strings.logout,
            icon: const Icon(Icons.logout, color: AppColors.accentRed),
            onPressed: () => unawaited(_logout()),
          ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.length < 6 ||
        _newPasswordController.text.length < 6) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(usersServiceProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      setState(() => _securityExpanded = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).passwordUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e, ref.read(stringsProvider)))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final prevId = previous?.value?.id;
      final nextId = next.value?.id;
      if (prevId != nextId && nextId != null) {
        _syncedProfileKey = null;
        if (next.value != null) {
          _syncFieldsFromUser(next.value!);
        }
        ref.invalidate(myListingsProvider);
      }
    });

    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;
    final plansAsync = ref.watch(plansProvider);
    final myListingsAsync = ref.watch(myListingsProvider);
    final api = ref.watch(apiServiceProvider);
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: _profileAppBar(strings),
        body: SafeArea(
          child: KeyboardScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHubTitle(text: strings.guestProfileTitle),
                  ProfileHeroCard(
                    title: strings.guestProfileTitle,
                    subtitle: strings.guestProfileCardSubtitle,
                    showAppLogo: true,
                  ),
                  const SizedBox(height: 16),
                  ProfileHubButton(
                    label: strings.loginOrRegister,
                    onPressed: _openLoginRegister,
                  ),
                  const SizedBox(height: 24),
                  _buildAppSettings(strings: strings, locale: locale),
                  const SizedBox(height: 20),
                  _buildAboutSupport(strings),
                ],
              ),
            ),
          ),
        ),
      );
    }

    _syncFieldsFromUser(user);

    final avatarUrl =
        user.avatarUrl != null ? api.mediaUrl(user.avatarUrl!) : null;
    final listingsCount = myListingsAsync.value?.length ?? 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundLight,
      appBar: _profileAppBar(strings, showLogout: true),
      body: SafeArea(
        child: KeyboardScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHubTitle(text: strings.guestProfileTitle),
                ProfileHeroCard(
                  title: user.name,
                  subtitle: strings.profileHeroLoggedIn(listingsCount, user.plan),
                  avatar: _userAvatarWidget(user: user, avatarUrl: avatarUrl),
                  onAvatarTap: _pickAvatar,
                  isSaving: _isSaving,
                ),
              const SizedBox(height: 12),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    unawaited(_logout());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentRed),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: AppColors.accentRed),
                        const SizedBox(width: 8),
                        Text(
                          strings.logout,
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_outline,
                      label: strings.publish,
                      color: AppColors.accentRed,
                      onTap: () => showCreateListingModal(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.storefront_outlined,
                      label: strings.myListings,
                      color: AppColors.primaryBlue,
                      onTap: () => context.push('/my-listings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (user.isAdmin) ...[
                _buildAdminSection(strings),
                const SizedBox(height: 24),
              ],
              _buildAppSettings(strings: strings, locale: locale),
              const SizedBox(height: 20),
              ProfileSectionHeader(title: strings.myProfile),
              const SizedBox(height: 4),
              _ExpandableMenuSection(
                    title: strings.personalInfo,
                    icon: Icons.person_outline,
                    subtitle: user.name,
                    isExpanded: _infoExpanded,
                    onTap: () =>
                        setState(() => _infoExpanded = !_infoExpanded),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: strings.displayName,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: user.email,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: strings.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                            suffixIcon: user.isEmailVerified
                                ? Tooltip(
                                    message: strings.emailVerified,
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  )
                                : Tooltip(
                                    message: strings.emailNotVerified,
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: strings.phone,
                            hintText: strings.phoneHint,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            helperText: strings.phoneHelper,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(strings.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: strings.myListings,
                    icon: Icons.inventory_2_outlined,
                    trailing: listingsCount > 0
                        ? TextButton(
                            onPressed: () => context.push('/my-listings'),
                            child: Text(strings.seeAll(listingsCount)),
                          )
                        : null,
                    child: myListingsAsync.when(
                      data: (listings) {
                        if (listings.isEmpty) {
                          return _EmptyListingsPrompt(
                            strings: strings,
                            onPublish: () => showCreateListingModal(context),
                          );
                        }
                        return Column(
                          children: [
                            ...listings.take(3).map(
                                  (listing) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: MyListingTile(
                                      listing: listing,
                                      api: api,
                                      strings: strings,
                                      onEdit: () => context
                                          .push('/edit-listing/${listing.id}'),
                                      onDelete: () =>
                                          deleteListingWithConfirmation(
                                        context: context,
                                        ref: ref,
                                        listingId: listing.id,
                                        listingTitle: listing.title,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => ListTile(
                        leading: const Icon(Icons.error_outline,
                            color: AppColors.accentRed),
                        title: Text(strings.loadingFailed),
                        subtitle: Text(apiErrorMessage(e, ref.read(stringsProvider))),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref.invalidate(myListingsProvider),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExpandableMenuSection(
                    title: strings.subscription,
                    icon: Icons.workspace_premium_outlined,
                    subtitle: strings.planLabel(user.plan),
                    isExpanded: _subscriptionExpanded,
                    onTap: () => setState(
                      () => _subscriptionExpanded = !_subscriptionExpanded,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryBlue,
                                AppColors.primaryBlue.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.currentPlan,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      user.plan,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        plansAsync.when(
                          data: (plans) => Column(
                            children: plans.map((plan) {
                              final isCurrent = user.plan == plan.id;
                              return _PlanTile(
                                plan: plan,
                                strings: strings,
                                isCurrent: isCurrent,
                                isSaving: _changingPlanId == plan.id,
                                onSelect: isCurrent || _changingPlanId != null
                                    ? null
                                    : () async {
                                        if (plan.paymentRequired) {
                                          await showPaymentModal(
                                            context: context,
                                            plan: plan,
                                          );
                                          return;
                                        }
                                        setState(
                                          () => _changingPlanId = plan.id,
                                        );
                                        try {
                                          final stringsNow =
                                              ref.read(stringsProvider);
                                          final updated = await ref
                                              .read(
                                                  subscriptionsServiceProvider)
                                              .subscribe(plan.id);
                                          await ref
                                              .read(authStateProvider.notifier)
                                              .setUser(updated);
                                          _syncFieldsFromUser(updated);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(stringsNow
                                                    .planActivated(plan.name)),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(apiErrorMessage(
                                                    e,
                                                    ref.read(
                                                        stringsProvider))),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(
                                              () => _changingPlanId = null,
                                            );
                                          }
                                        }
                                      },
                              );
                            }).toList(),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text(strings.plansError('$e')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExpandableMenuSection(
                    title: strings.security,
                    icon: Icons.shield_outlined,
                    subtitle: strings.password,
                    isExpanded: _securityExpanded,
                    onTap: () =>
                        setState(() => _securityExpanded = !_securityExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.currentPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.newPassword,
                            prefixIcon: const Icon(Icons.lock_reset),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _changePassword,
                            child: Text(strings.updatePassword),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 20),
              _buildAboutSupport(strings),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_logout()),
                  icon: const Icon(Icons.logout, color: AppColors.accentRed),
                  label: Text(
                    strings.logout,
                    style: const TextStyle(color: AppColors.accentRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isSaving ? null : _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(strings.deleteAccount),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableMenuSection extends StatelessWidget {
  const _ExpandableMenuSection({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyListingsPrompt extends StatelessWidget {
  const _EmptyListingsPrompt({
    required this.strings,
    required this.onPublish,
  });

  final AppStrings strings;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            strings.noListingsYet,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            strings.publishFirstListing,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onPublish,
            child: Text(strings.createListing),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.strings,
    required this.isCurrent,
    required this.isSaving,
    required this.onSelect,
  });

  final PlanModel plan;
  final AppStrings strings;
  final bool isCurrent;
  final bool isSaving;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.accentGold
              : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
        color: isCurrent
            ? AppColors.accentGold.withValues(alpha: 0.08)
            : AppColors.backgroundLight,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          isCurrent ? Icons.verified : Icons.card_membership_outlined,
          color: isCurrent ? AppColors.accentGold : AppColors.primaryBlue,
        ),
        title: Text(
          plan.name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          [
            plan.maxListings < 0
                ? strings.unlimitedListings
                : strings.maxListings(plan.maxListings),
            if (plan.price > 0) strings.pricePerMonth(plan.price),
            if (!plan.hasAds) strings.noAds,
          ].join(' • '),
        ),
        trailing: isCurrent
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  strings.current,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              )
            : TextButton(
                onPressed: isSaving ? null : onSelect,
                child: Text(strings.choose),
              ),
      ),
    );
  }
}
