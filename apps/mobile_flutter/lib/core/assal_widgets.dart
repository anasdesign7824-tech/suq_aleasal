import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_design/assal_tokens.dart';
import 'assal_assets.dart';

const assalDarkGradient = AssalColors.darkGradient;

class AssalBrandMark extends StatelessWidget {
  const AssalBrandMark({
    super.key,
    this.size = 44,
    this.showName = false,
    this.framed = false,
    this.nameColor,
  });
  final double size;
  final bool showName;
  final bool framed;
  final Color? nameColor;

  @override
  Widget build(BuildContext context) {
    final mark = framed
        ? Container(
            width: size,
            height: size,
            padding:
                EdgeInsets.all(size >= 64 ? AssalSpacing.sm : AssalSpacing.xs),
            decoration: BoxDecoration(
              color: AssalColors.cream,
              borderRadius: BorderRadius.circular(AssalRadius.small),
              border:
                  Border.all(color: AssalColors.cream.withValues(alpha: .9)),
            ),
            child: SvgPicture.asset(AssalAssets.logoInternal),
          )
        : SvgPicture.asset(
            AssalAssets.logoInternal,
            width: size,
            height: size,
          );

    return Semantics(
      label: 'عسلكم',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (showName) ...[
            const SizedBox(width: AssalSpacing.sm),
            Text(
              'عسلكم',
              style: AssalTypography.heading3.copyWith(
                color: nameColor ?? AssalColors.deepBrown,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DemoModePill extends StatelessWidget {
  const DemoModePill({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AssalSpacing.md, vertical: AssalSpacing.xs),
        decoration: BoxDecoration(
            color: AssalColors.honeyLight,
            borderRadius: BorderRadius.circular(AssalRadius.pill)),
        child: Text('تجربة بلا تسجيل',
            style: AssalTypography.caption
                .copyWith(color: AssalColors.primaryDark)),
      );
}

class AssalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AssalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBrand = true,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBrand;

  final PreferredSizeWidget? bottom;
  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: assalDarkGradient),
      child: AppBar(
        bottom: bottom,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AssalTypography.heading3.copyWith(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AssalColors.primaryDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleSpacing: AssalSpacing.sm,
        leading: canPop
            ? IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : showBrand
                ? const Padding(
                    padding: EdgeInsets.all(AssalSpacing.sm),
                    child: AssalBrandMark(
                      size: 36,
                      showName: false,
                      framed: true,
                      nameColor: Colors.white,
                    ),
                  )
                : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBrand && canPop) ...[
              const AssalBrandMark(
                size: 28,
                showName: true,
                framed: true,
                nameColor: Colors.white,
              ),
              const SizedBox(width: AssalSpacing.sm),
            ],
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

class AssalGlassLoading extends StatefulWidget {
  const AssalGlassLoading({
    super.key,
    this.height = 72,
    this.label = 'جارٍ تجهيز تجربة عسلكم...',
  });
  final double height;
  final String label;

  @override
  State<AssalGlassLoading> createState() => _AssalGlassLoadingState();
}

class _AssalGlassLoadingState extends State<AssalGlassLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height.clamp(56, 104).toDouble();
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: const Icon(
                  Icons.hive_outlined,
                  size: 22,
                  color: AssalColors.primaryDark,
                ),
              ),
              const SizedBox(width: AssalSpacing.xs),
              Text(
                widget.label,
                style: AssalTypography.bodySmall.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssalFutureStateView<T> extends StatelessWidget {
  const AssalFutureStateView(
      {super.key,
      required this.future,
      required this.builder,
      this.onRetry,
      this.loadingHeight = 180});
  final Future<AssalLoadState<T>> future;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) => FutureBuilder<AssalLoadState<T>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AssalMessageCard(
                icon: Icons.wifi_off_outlined,
                message:
                    'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم حاول مرة أخرى.',
                onRetry: onRetry);
          }
          if (!snapshot.hasData) {
            return AssalGlassLoading(height: loadingHeight);
          }
          return AssalStateView<T>(
              state: snapshot.data!, builder: builder, onRetry: onRetry);
        },
      );
}

class AssalStateView<T> extends StatelessWidget {
  const AssalStateView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyMessageAr =
        'لا توجد نتائج متاحة الآن. جرّب تغيير الفلاتر أو البحث مرة أخرى.',
  });
  final AssalLoadState<T> state;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;
  final String emptyMessageAr;

  IconData _errorIcon(AssalErrorKind kind) => switch (kind) {
        AssalErrorKind.network => Icons.wifi_off_outlined,
        AssalErrorKind.unauthorized => Icons.lock_outline,
        AssalErrorKind.schemaMismatch => Icons.sync_problem_outlined,
        AssalErrorKind.validation => Icons.info_outline,
        AssalErrorKind.server => Icons.cloud_off_outlined,
        AssalErrorKind.unknown => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) => switch (state) {
        AssalLoading<T>() => const AssalGlassLoading(),
        AssalData<T>(:final value) => value is Iterable && value.isEmpty
            ? AssalMessageCard(
                icon: Icons.inbox_outlined,
                message: emptyMessageAr,
                onRetry: onRetry,
              )
            : builder(value),
        AssalEmpty<T>(:final messageAr) => AssalMessageCard(
            icon: Icons.inbox_outlined,
            message: messageAr,
            onRetry: onRetry,
          ),
        AssalError<T>(:final messageAr, :final kind, :final retryable) =>
          AssalMessageCard(
            icon: _errorIcon(kind),
            message: messageAr,
            onRetry: retryable ? onRetry : null,
          ),
      };
}

class AssalMessageCard extends StatelessWidget {
  const AssalMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AssalSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 34, color: AssalColors.textMuted),
                const SizedBox(height: AssalSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AssalTypography.body.copyWith(
                    color: AssalColors.textSecondary,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AssalSpacing.sm),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: AssalTypography.heading3
                .copyWith(color: AssalColors.deepBrown)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
}

class AssalPremiumBadge extends StatelessWidget {
  const AssalPremiumBadge({
    super.key,
    this.label = 'Premium',
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AssalColors.primaryDark, AssalColors.secondary],
          ),
          borderRadius: BorderRadius.circular(AssalRadius.pill),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AssalSpacing.sm : AssalSpacing.md,
            vertical: AssalSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: compact ? 14 : 16,
                color: AssalColors.cream,
              ),
              const SizedBox(width: AssalSpacing.xs),
              Text(
                label,
                style: AssalTypography.caption.copyWith(
                  color: AssalColors.cream,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

class AssalRoleBadge extends StatelessWidget {
  const AssalRoleBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AssalColors.honeyLight,
          borderRadius: BorderRadius.circular(AssalRadius.pill),
          border: Border.all(color: AssalColors.primaryDark.withValues(alpha: .2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AssalSpacing.sm,
            vertical: AssalSpacing.xs,
          ),
          child: Text(
            label,
            style: AssalTypography.caption.copyWith(
              color: AssalColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class AssalActionTile extends StatelessWidget {
  const AssalActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AssalColors.primaryDark),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: trailing ??
              (onTap == null
                  ? null
                  : const Icon(Icons.chevron_left, color: AssalColors.textMuted)),
        ),
      );
}

class AssalNotificationCard extends StatelessWidget {
  const AssalNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  final AssalNotificationSummary notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rawImage = notification.payload['image_url'];
    final imageUrl = rawImage is String && rawImage.trim().isNotEmpty
        ? rawImage.trim()
        : null;
    return Card(
      color: notification.readAt == null ? AssalColors.cream : null,
      child: ListTile(
        onTap: onTap,
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AssalRadius.medium),
                child: Image.network(
                  imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AssalColors.textMuted,
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: AssalColors.honeyLight,
                child: Icon(
                  notification.readAt == null
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none,
                  color: AssalColors.primaryDark,
                ),
              ),
        title: Text(
          notification.titleAr,
          style: notification.readAt == null
              ? const TextStyle(fontWeight: FontWeight.w700)
              : null,
        ),
        subtitle: notification.bodyAr == null
            ? null
            : Text(notification.bodyAr!),
        trailing: notification.readAt == null
            ? const AssalRoleBadge(label: 'جديد')
            : null,
      ),
    );
  }
}

class AssalConversationCard extends StatelessWidget {
  const AssalConversationCard({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final AssalConversationSummary conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(
            backgroundColor: AssalColors.honeyLight,
            child: Icon(
              Icons.storefront_outlined,
              color: AssalColors.primaryDark,
            ),
          ),
          title: Text(conversation.storeName),
          subtitle: Text(
            conversation.lastMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: conversation.unreadCount > 0
              ? AssalRoleBadge(label: '${conversation.unreadCount} جديد')
              : const Icon(Icons.chevron_left),
        ),
      );
}

class AssalMessageBubble extends StatelessWidget {
  const AssalMessageBubble({
    super.key,
    required this.message,
  });

  final AssalMessageSummary message;

  @override
  Widget build(BuildContext context) => Align(
        alignment: message.isMine
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: Card(
          color: message.isMine
              ? AssalColors.honeyLight
              : AssalColors.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(AssalSpacing.md),
            child: Text(message.body),
          ),
        ),
      );
}

class AssalProfileHeaderCard extends StatelessWidget {
  const AssalProfileHeaderCard({
    super.key,
    required this.user,
    this.onEdit,
  });

  final AssalUserProfile user;
  final VoidCallback? onEdit;

  String _roleLabel() => switch (user.role) {
        AssalRole.guest => 'زائر',
        AssalRole.customer => 'عميل عسلكم',
        AssalRole.merchant => 'تاجر عسلكم',
        AssalRole.admin => 'إدارة عسلكم',
      };

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AssalImageTile(
                    imageUrl: user.coverUrl,
                    height: 150,
                    icon: Icons.landscape_outlined,
                  ),
                ),
                Positioned(
                  bottom: -34,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AssalColors.honeyLight,
                      backgroundImage:
                          avatarUrl != null && avatarUrl.startsWith('http')
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: avatarUrl == null || !avatarUrl.startsWith('http')
                          ? Text(
                              user.nameAr.isEmpty ? 'ع' : user.nameAr.substring(0, 1),
                              style: AssalTypography.heading1.copyWith(
                                color: AssalColors.primaryDark,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              0,
              AssalSpacing.lg,
              AssalSpacing.lg,
            ),
            child: Column(
              children: [
                Text(
                  user.nameAr.isEmpty ? 'عميل عسلكم' : user.nameAr,
                  style: AssalTypography.heading2.copyWith(
                    color: AssalColors.deepBrown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AssalSpacing.xs),
                AssalRoleBadge(label: _roleLabel()),
                if (user.email != null && user.email!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AssalSpacing.xs),
                    child: Text(
                      user.email!,
                      style: AssalTypography.body.copyWith(
                        color: AssalColors.textSecondary,
                      ),
                    ),
                  ),
                if (user.phone != null && user.phone!.isNotEmpty)
                  _line(Icons.phone_outlined, user.phone!),
                if (user.location != null && user.location!.isNotEmpty)
                  _line(Icons.location_on_outlined, user.location!),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AssalSpacing.sm),
                    child: Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                      style: AssalTypography.bodyLarge,
                    ),
                  ),
                const SizedBox(height: AssalSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('${user.followersCount}', 'متابع'),
                    _stat('${user.followingCount}', 'يتابع'),
                  ],
                ),
                if (onEdit != null) ...[
                  const SizedBox(height: AssalSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تعديل الملف الشخصي'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(top: AssalSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AssalColors.primaryDark),
            const SizedBox(width: AssalSpacing.xs),
            Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  Widget _stat(String value, String label) => Column(
        children: [
          Text(
            value,
            style: AssalTypography.heading3.copyWith(
              color: AssalColors.deepBrown,
            ),
          ),
          Text(
            label,
            style: AssalTypography.caption.copyWith(
              color: AssalColors.textMuted,
            ),
          ),
        ],
      );
}

class AssalImagePickerTile extends StatelessWidget {
  const AssalImagePickerTile({
    super.key,
    this.imageUrl,
    this.bytes,
    required this.onPick,
    this.onClear,
    this.icon = Icons.add_a_photo_outlined,
    this.size = 112,
    this.label,
  });

  final String? imageUrl;
  final Uint8List? bytes;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final IconData icon;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null ||
        (imageUrl != null && imageUrl!.trim().startsWith('http'));
    final image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, width: size, height: size)
        : hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback();
    return Semantics(
      button: onPick != null,
      label: label ?? (hasImage ? 'تغيير الصورة' : 'إضافة الصورة'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        child: Material(
          color: AssalColors.honeyLight,
          child: InkWell(
            onTap: onPick,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (hasImage)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: .34),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: AssalSpacing.xs,
                    bottom: AssalSpacing.xs,
                    child: IconButton.filled(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: hasImage ? 'تغيير الصورة' : 'إضافة الصورة',
                      onPressed: onPick,
                      icon: Icon(
                        hasImage ? Icons.edit_outlined : icon,
                        size: 18,
                      ),
                    ),
                  ),
                  if (hasImage && onClear != null)
                    Positioned(
                      left: AssalSpacing.xs,
                      top: AssalSpacing.xs,
                      child: IconButton.filledTonal(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                        tooltip: 'إزالة الصورة',
                        onPressed: onClear,
                        icon: const Icon(Icons.delete_outline, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          icon,
          size: size * .3,
          color: AssalColors.primaryDark,
        ),
      );
}

class AssalImageUploadSlot extends StatelessWidget {
  const AssalImageUploadSlot({
    super.key,
    required this.label,
    required this.icon,
    required this.imageUrl,
    required this.bytes,
    required this.onPick,
    this.onClear,
    this.height = 150,
  });

  final String label;
  final IconData icon;
  final String? imageUrl;
  final Uint8List? bytes;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null ||
        (imageUrl != null && imageUrl!.trim().startsWith('http'));
    final image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity)
        : hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _fallback(icon),
              )
            : _fallback(icon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AssalTypography.subtitle),
        const SizedBox(height: AssalSpacing.sm),
        Semantics(
          button: onPick != null,
          label: hasImage ? 'تغيير $label' : 'إضافة $label',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AssalRadius.large),
            child: Material(
              color: AssalColors.honeyLight,
              child: InkWell(
                onTap: onPick,
                child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      image,
                      if (hasImage)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: .32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: AssalSpacing.sm,
                        bottom: AssalSpacing.sm,
                        child: IconButton.filled(
                          tooltip: hasImage ? 'تغيير الصورة' : 'إضافة الصورة',
                          onPressed: onPick,
                          icon: Icon(
                            hasImage
                                ? Icons.edit_outlined
                                : Icons.add_a_photo_outlined,
                          ),
                        ),
                      ),
                      if (hasImage && onClear != null)
                        Positioned(
                          left: AssalSpacing.sm,
                          top: AssalSpacing.sm,
                          child: IconButton.filledTonal(
                            tooltip: 'إزالة الصورة',
                            onPressed: onClear,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(IconData fallbackIcon) => Center(
        child: Icon(
          fallbackIcon,
          size: 42,
          color: AssalColors.primaryDark,
        ),
      );
}

class AssalImageTile extends StatelessWidget {
  const AssalImageTile(
      {super.key,
      this.imageUrl,
      this.height = 150,
      this.icon = Icons.local_florist_outlined});
  final String? imageUrl;
  final double height;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
            color: AssalColors.honeyLight,
            borderRadius: BorderRadius.circular(AssalRadius.large)),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.startsWith('http')
            ? Image.network(imageUrl!,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      );
  Widget _fallback() => Center(
      child: Icon(icon, size: height * .38, color: AssalColors.primaryDark));
}

String formatAssalPrice(double? price, String currencyCode) {
  if (price == null) return 'السعر عند الطلب';
  final currency = switch (currencyCode.toUpperCase()) {
    'YER' => 'ريال يمني',
    'SAR' => 'ريال سعودي',
    'USD' => 'دولار أمريكي',
    _ => currencyCode,
  };
  return '${price.toStringAsFixed(0)} $currency';
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavorite,
    this.showVerifiedBadge = false,
  });
  final AssalProductSummary product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool showVerifiedBadge;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: product.nameAr,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                AssalImageTile(imageUrl: product.primaryImageUrl, height: 138),
                if (onFavorite != null)
                  Positioned(
                      top: AssalSpacing.sm,
                      left: AssalSpacing.sm,
                      child: IconButton.filledTonal(
                          onPressed: onFavorite,
                          icon: const Icon(Icons.bookmark_border),
                          tooltip: 'حفظ المنتج')),
                if (showVerifiedBadge)
                  const Positioned(
                    top: AssalSpacing.sm,
                    right: AssalSpacing.sm,
                    child: AssalPremiumBadge(label: 'موثق Pro', compact: true),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.all(AssalSpacing.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nameAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AssalTypography.title
                              .copyWith(color: AssalColors.deepBrown)),
                      const SizedBox(height: AssalSpacing.xs),
                      Text(
                          product.subcategoryNameAr ??
                              product.categoryNameAr ??
                              'منتج نحلي يمني',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AssalTypography.bodySmall
                              .copyWith(color: AssalColors.textSecondary)),
                      const SizedBox(height: AssalSpacing.xs),
                      Text(
                          formatAssalPrice(product.price, product.currencyCode),
                          style: AssalTypography.bodySmall.copyWith(
                              color: AssalColors.primaryDark,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: AssalSpacing.xs),
                      Row(children: [
                        RatingStars(rating: product.ratingAverage),
                        const SizedBox(width: AssalSpacing.xs),
                        Text('(${product.reviewCount})',
                            style: AssalTypography.caption
                                .copyWith(color: AssalColors.textMuted)),
                        const Spacer(),
                        if (product.availability.isNotEmpty)
                          Flexible(
                              child: Text(product.availability,
                                  overflow: TextOverflow.ellipsis,
                                  style: AssalTypography.caption.copyWith(
                                      color: AssalColors.textSecondary)))
                      ]),
                      const SizedBox(height: AssalSpacing.sm),
                      Row(children: [
                        if (product.gradeLevel != null)
                          InfoChip(label: 'درجة ${product.gradeLevel}'),
                        const Spacer(),
                        const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AssalColors.primaryDark),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      );
}

class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.onAction,
    this.actionIcon = Icons.remove_circle_outline,
    this.actionTooltip = 'إزالة المتابعة',
  });
  final AssalStoreSummary store;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String actionTooltip;
  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              child: Row(children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: AssalColors.honeyLight,
                    backgroundImage: logoUrl != null && logoUrl.startsWith('http')
                        ? NetworkImage(logoUrl)
                        : null,
                    child: logoUrl == null || !logoUrl.startsWith('http')
                        ? const Icon(Icons.storefront_outlined,
                            color: AssalColors.primaryDark, size: 28)
                        : null),
                  const SizedBox(width: AssalSpacing.md),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Expanded(
                              child: Text(store.nameAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AssalTypography.title
                                      .copyWith(color: AssalColors.deepBrown))),
                          if (store.isVerified)
                            const Tooltip(
                              message: 'متجر موثق Pro',
                              child: Icon(Icons.verified,
                                  color: AssalColors.primaryDark, size: 18),
                            )
                        ]),
                        const SizedBox(height: AssalSpacing.xs),
                        Text(store.regionNameAr ?? 'منصة عسلكم',
                            style: AssalTypography.bodySmall
                                .copyWith(color: AssalColors.textSecondary)),
                        const SizedBox(height: AssalSpacing.xs),
                        Row(children: [
                          RatingStars(rating: store.ratingAverage),
                          const SizedBox(width: AssalSpacing.sm),
                          Text('${store.followersCount} متابع',
                              style: AssalTypography.caption
                                  .copyWith(color: AssalColors.textMuted))
                        ]),
                      ])),
                  if (onAction != null)
                    IconButton(
                      onPressed: onAction,
                      tooltip: actionTooltip,
                      icon: Icon(actionIcon, color: AssalColors.primaryDark),
                    ),
                  const Icon(Icons.chevron_left, color: AssalColors.textMuted),
                ]),
            ),
          ),
      );
  }
}

class AssalStoreHeaderCard extends StatelessWidget {
  const AssalStoreHeaderCard({
    super.key,
    required this.store,
    this.trailing,
  });

  final AssalStoreSummary store;
  final Widget? trailing;

  String _statusLabel() {
    if (store.isVerified) return 'متجر موثق Pro';
    return switch (store.status) {
      StoreStatus.active => 'متجر مفعّل',
      StoreStatus.pending => 'المتجر قيد التفعيل',
      StoreStatus.paused => 'المتجر موقوف مؤقتًا',
      StoreStatus.rejected => 'المتجر يحتاج مراجعة',
      StoreStatus.suspended => 'المتجر موقوف',
    };
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    final badge = store.isVerified
        ? const AssalPremiumBadge(label: 'موثق Pro', compact: true)
        : AssalRoleBadge(label: _statusLabel());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AssalImageTile(
                    imageUrl: store.coverUrl,
                    height: 168,
                    icon: Icons.hive_outlined,
                  ),
                ),
                Positioned(
                  left: AssalSpacing.md,
                  top: AssalSpacing.md,
                  child: badge,
                ),
                if (trailing != null)
                  Positioned(
                    right: AssalSpacing.sm,
                    top: AssalSpacing.sm,
                    child: trailing!,
                  ),
                Positioned(
                  bottom: -30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AssalColors.honeyLight,
                      backgroundImage: logoUrl != null && logoUrl.startsWith('http')
                          ? NetworkImage(logoUrl)
                          : null,
                      child: logoUrl == null || !logoUrl.startsWith('http')
                          ? const Icon(
                              Icons.storefront_outlined,
                              size: 34,
                              color: AssalColors.primaryDark,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              0,
              AssalSpacing.lg,
              AssalSpacing.lg,
            ),
            child: Column(
              children: [
                Text(
                  store.nameAr,
                  textAlign: TextAlign.center,
                  style: AssalTypography.heading2.copyWith(
                    color: AssalColors.deepBrown,
                  ),
                ),
                const SizedBox(height: AssalSpacing.sm),
                Text(
                  store.description ?? 'متجر متخصص في المنتجات النحلية اليمنية.',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AssalTypography.body.copyWith(
                    color: AssalColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AssalSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('${store.followersCount}', 'متابع'),
                    _stat('${store.reviewCount}', 'مراجعة'),
                    _stat(store.ratingAverage.toStringAsFixed(1), 'التقييم'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(
            value,
            style: AssalTypography.heading3.copyWith(
              color: AssalColors.deepBrown,
            ),
          ),
          Text(
            label,
            style: AssalTypography.caption.copyWith(
              color: AssalColors.textMuted,
            ),
          ),
        ],
      );
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          5,
          (index) => Icon(
              index < rating.round()
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 16,
              color: AssalColors.primaryDark)));
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AssalSpacing.sm, vertical: AssalSpacing.xs),
      decoration: BoxDecoration(
          color: AssalColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AssalRadius.small)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 14, color: AssalColors.primaryDark),
        if (icon != null) const SizedBox(width: 3),
        Text(label,
            style:
                AssalTypography.caption.copyWith(color: AssalColors.secondary))
      ]));
}

Future<bool> showAuthPrompt(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('هذه الميزة تحتاج حسابًا'),
        content: const Text(
            'أنشئ حسابًا مجانيًا لحفظ المنتجات ومتابعة المتاجر وإرسال الطلبات، أو تابع التصفح كزائر.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('متابعة التصفح')),
          OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تسجيل الدخول')),
        ],
      ),
    ) ??
    false;
