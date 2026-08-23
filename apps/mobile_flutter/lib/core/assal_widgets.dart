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
    this.assetPath,
  });
  final double size;
  final bool showName;
  final bool framed;
  final Color? nameColor;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final Widget logo = SvgPicture.asset(
      assetPath ?? AssalAssets.logoInternal,
      width: size,
      height: size,
    );
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
            child: logo,
          )
        : logo;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.md),
          child: Row(
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
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AssalTypography.bodySmall.copyWith(
                    color: AssalColors.textSecondary,
                  ),
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
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AssalTypography.heading3
                  .copyWith(color: AssalColors.deepBrown),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      );

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

String _conversationDateLabel(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month · $hour:$minute';
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
          title: Row(
            children: [
              Flexible(
                child: Text(
                  conversation.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AssalSpacing.sm),
              Flexible(
                child: Text(
                  _conversationDateLabel(conversation.updatedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AssalTypography.caption.copyWith(
                    color: AssalColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
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
    this.onPickAvatar,
    this.onPickCover,
    this.imageBusy = false,
  });

  final AssalUserProfile user;
  final VoidCallback? onEdit;
  final VoidCallback? onPickAvatar;
  final VoidCallback? onPickCover;
  final bool imageBusy;

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
            height: 158,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: AssalImageTile(
                    imageUrl: user.coverUrl,
                    height: 120,
                    icon: Icons.landscape_outlined,
                  ),
                ),
                if (onPickCover != null)
                  Positioned(
                    right: AssalSpacing.sm,
                    top: AssalSpacing.sm,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: imageBusy ? null : onPickCover,
                      tooltip: 'تغيير صورة الغلاف',
                      icon: imageBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AssalColors.honeyLight,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.startsWith('http')
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child:
                              avatarUrl == null || !avatarUrl.startsWith('http')
                                  ? Text(
                                      user.nameAr.isEmpty
                                          ? 'ع'
                                          : user.nameAr.substring(0, 1),
                                      style: AssalTypography.heading1.copyWith(
                                        color: AssalColors.primaryDark,
                                      ),
                                    )
                                  : null,
                        ),
                        if (onPickAvatar != null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filledTonal(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed: imageBusy ? null : onPickAvatar,
                              tooltip: 'تغيير الصورة الشخصية',
                              icon: imageBusy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 38),
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
    this.width,
    this.height,
    this.label,
  });

  final String? imageUrl;
  final Uint8List? bytes;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final IconData icon;
  final double size;
  final double? width;
  final double? height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tileWidth = width ?? size;
    final tileHeight = height ?? size;
    final fallbackSize = tileWidth < tileHeight ? tileWidth : tileHeight;
    final hasImage = bytes != null ||
        (imageUrl != null && imageUrl!.trim().startsWith('http'));
    final image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, width: tileWidth, height: tileHeight)
        : hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: tileWidth,
                height: tileHeight,
                errorBuilder: (_, __, ___) => _fallback(fallbackSize),
              )
            : _fallback(fallbackSize);
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
                width: tileWidth,
                height: tileHeight,
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
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: hasImage ? 'تغيير الصورة' : 'إضافة الصورة',
                      onPressed: onPick,
                      icon: Icon(
                        hasImage ? Icons.edit_outlined : icon,
                        size: 16,
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
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'إزالة الصورة',
                        onPressed: onClear,
                        icon: const Icon(Icons.delete_outline, size: 16),
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

  Widget _fallback(double fallbackSize) => Center(
        child: Icon(
          icon,
          size: fallbackSize * .3,
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
  Widget build(BuildContext context) => AssalImagePickerTile(
        imageUrl: imageUrl,
        bytes: bytes,
        onPick: onPick,
        onClear: onClear,
        icon: icon,
        width: double.infinity,
        height: height,
        label: label,
      );
}

class AssalImageTile extends StatelessWidget {
  const AssalImageTile({
    super.key,
    this.imageUrl,
    this.height = 150,
    this.icon = Icons.local_florist_outlined,
    this.expand = false,
  });
  final String? imageUrl;
  final double height;
  final IconData icon;
  final bool expand;
  @override
  Widget build(BuildContext context) => Container(
        height: expand ? null : height,
        constraints: expand ? const BoxConstraints.expand() : null,
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
      child: Icon(
        icon,
        size: height.isFinite ? height * .38 : 42,
        color: AssalColors.primaryDark,
      ));
}

String formatAssalPrice(double? price, String currencyCode) {
  if (price == null) return 'السعر عند الطلب';
  final currency = switch (currencyCode.toUpperCase()) {
    'YER' => 'ريال يمني',
    'SAR' => 'ريال سعودي',
    'USD' => 'دولار أمريكي',
    _ => currencyCode,
  };
  final raw = price.toStringAsFixed(0);
  final sign = raw.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? raw : raw.substring(1);
  final formatted = digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$sign$formatted $currency';
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavorite,
    this.store,
  });
  final AssalProductSummary product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final AssalStoreSummary? store;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: product.nameAr,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: AssalImageTile(
                        imageUrl: product.primaryImageUrl,
                        expand: true,
                      ),
                    ),
                    if (product.availability.trim().isNotEmpty)
                      Positioned(
                        top: AssalSpacing.sm,
                        right: AssalSpacing.sm,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AssalColors.success.withValues(alpha: .16),
                            borderRadius:
                                BorderRadius.circular(AssalRadius.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AssalSpacing.sm,
                              vertical: AssalSpacing.xs,
                            ),
                            child: Text(
                              product.availability,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AssalTypography.caption.copyWith(
                                color: AssalColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onFavorite != null)
                      Positioned(
                        top: AssalSpacing.sm,
                        left: AssalSpacing.sm,
                        child: IconButton.filledTonal(
                          onPressed: onFavorite,
                          icon: const Icon(Icons.favorite_border_rounded),
                          tooltip: 'حفظ المنتج',
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AssalSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.subcategoryNameAr != null ||
                          product.categoryNameAr != null)
                        InfoChip(
                          label: product.subcategoryNameAr ??
                              product.categoryNameAr!,
                          icon: Icons.local_florist_outlined,
                        ),
                      const SizedBox(height: AssalSpacing.xs),
                      Text(
                        product.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AssalTypography.title
                            .copyWith(color: AssalColors.deepBrown),
                      ),
                      const SizedBox(height: AssalSpacing.xs),
                      Row(
                        children: [
                          RatingStars(rating: product.ratingAverage),
                          const SizedBox(width: AssalSpacing.xs),
                          Text(
                            product.ratingAverage.toStringAsFixed(1),
                            style: AssalTypography.bodySmall.copyWith(
                              color: AssalColors.deepBrown,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AssalSpacing.xs),
                          Flexible(
                            child: Text(
                              '${product.reviewCount} تقييم',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AssalTypography.caption.copyWith(
                                color: AssalColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AssalSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              formatAssalPrice(
                                product.price,
                                product.currencyCode,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AssalTypography.bodySmall.copyWith(
                                color: AssalColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (product.weightLabel != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AssalSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.scale_outlined,
                                    size: 16,
                                    color: AssalColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    product.weightLabel!,
                                    style: AssalTypography.caption.copyWith(
                                      color: AssalColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (store != null) ...[
                        const SizedBox(height: AssalSpacing.sm),
                        const Divider(height: 1),
                        const SizedBox(height: AssalSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store!.nameAr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AssalTypography.bodySmall.copyWith(
                                      color: AssalColors.deepBrown,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (store!.regionNameAr != null)
                                    Text(
                                      store!.regionNameAr!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AssalTypography.caption.copyWith(
                                        color: AssalColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (store!.isVerified)
                              const Icon(
                                Icons.verified_rounded,
                                size: 20,
                                color: AssalColors.secondary,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
    this.productCount,
  });
  final AssalStoreSummary store;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String actionTooltip;
  final int? productCount;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    return Semantics(
      button: true,
      label: store.nameAr,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssalImageTile(
                      imageUrl: store.coverUrl,
                      expand: true,
                      height: double.infinity,
                      icon: Icons.landscape_outlined,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AssalColors.deepBrown.withValues(alpha: .68),
                          ],
                        ),
                      ),
                    ),
                    if (onAction != null)
                      Positioned(
                        top: AssalSpacing.sm,
                        left: AssalSpacing.sm,
                        child: IconButton.filledTonal(
                          onPressed: onAction,
                          tooltip: actionTooltip,
                          icon: Icon(actionIcon),
                        ),
                      ),
                    Positioned(
                      left: AssalSpacing.md,
                      right: AssalSpacing.md,
                      bottom: AssalSpacing.md,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AssalColors.cream,
                            backgroundImage:
                                logoUrl != null && logoUrl.startsWith('http')
                                    ? NetworkImage(logoUrl)
                                    : null,
                            child: logoUrl == null || !logoUrl.startsWith('http')
                                ? const Icon(
                                    Icons.storefront_outlined,
                                    color: AssalColors.primaryDark,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AssalSpacing.sm),
                          Expanded(
                            child: Text(
                              store.nameAr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AssalTypography.title.copyWith(
                                color: AssalColors.cream,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AssalSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AssalColors.textMuted,
                        ),
                        const SizedBox(width: AssalSpacing.xs),
                        Expanded(
                          child: Text(
                            store.regionNameAr ?? 'منصة عسلكم',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AssalTypography.bodySmall.copyWith(
                              color: AssalColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AssalSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StoreStat(
                            value: _formatStoreCount(store.followersCount),
                            label: 'متابع',
                          ),
                        ),
                        Expanded(
                          child: _StoreStat(
                            value: store.ratingAverage.toStringAsFixed(1),
                            label: 'تقييم',
                            icon: Icons.star_rounded,
                          ),
                        ),
                        Expanded(
                          child: _StoreStat(
                            value: productCount?.toString() ?? '—',
                            label: 'منتج',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AssalSpacing.md),
                    OutlinedButton(
                      onPressed: onTap,
                      child: const Text('عرض المتجر'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreStat extends StatelessWidget {
  const _StoreStat({
    required this.value,
    required this.label,
    this.icon,
  });
  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AssalColors.primaryDark),
                const SizedBox(width: AssalSpacing.xs),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AssalTypography.body.copyWith(
                    color: AssalColors.deepBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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

String _formatStoreCount(int value) {
  if (value < 1000) return '$value';
  final compact = value / 1000;
  return compact == compact.roundToDouble()
      ? '${compact.toStringAsFixed(0)}K'
      : '${compact.toStringAsFixed(1)}K';
}

class AssalStoreHeaderCard extends StatelessWidget {
  const AssalStoreHeaderCard({
    super.key,
    required this.store,
    this.trailing,
    this.isFollowing = false,
    this.followBusy = false,
    this.onFollow,
    this.followersCountOverride,
    this.onFollowersTap,
    this.onPickLogo,
    this.onPickCover,
    this.imageBusy = false,
  });

  final AssalStoreSummary store;
  final Widget? trailing;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onFollow;
  final int? followersCountOverride;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onPickLogo;
  final VoidCallback? onPickCover;
  final bool imageBusy;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    final displayedFollowersCount = followersCountOverride ?? store.followersCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 128,
                  child: AssalImageTile(
                    imageUrl: store.coverUrl,
                    height: 128,
                    icon: Icons.hive_outlined,
                  ),
                ),
                if (trailing != null)
                  Positioned(
                    right: AssalSpacing.sm,
                    top: AssalSpacing.sm,
                    child: trailing!,
                  ),
                if (onPickCover != null)
                  Positioned(
                    right: trailing != null ? 56 : AssalSpacing.sm,
                    top: AssalSpacing.sm,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: imageBusy ? null : onPickCover,
                      tooltip: 'تغيير صورة غلاف المتجر',
                      icon: imageBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                if (onFollow != null)
                  Positioned(
                    right: AssalSpacing.sm,
                    top: AssalSpacing.sm,
                    child: AnimatedScale(
                      scale: isFollowing ? 1 : .92,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: IconButton.filledTonal(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: isFollowing
                              ? AssalColors.honey
                              : Colors.white.withValues(alpha: .88),
                          foregroundColor: AssalColors.deepBrown,
                        ),
                        onPressed: followBusy ? null : onFollow,
                        tooltip: isFollowing
                            ? 'إلغاء متابعة المتجر'
                            : 'متابعة المتجر',
                        icon: followBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Icon(
                                  key: ValueKey<bool>(isFollowing),
                                  isFollowing
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                ),
                              ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AssalColors.honeyLight,
                          backgroundImage:
                              logoUrl != null && logoUrl.startsWith('http')
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
                        if (onPickLogo != null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filledTonal(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed: imageBusy ? null : onPickLogo,
                              tooltip: 'تغيير شعار المتجر',
                              icon: imageBusy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
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
                    _stat(
                      '$displayedFollowersCount',
                      'متابع',
                      onTap: onFollowersTap,
                    ),
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

  Widget _stat(String value, String label, {VoidCallback? onTap}) {
    final content = Column(
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
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AssalRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AssalSpacing.sm,
          vertical: AssalSpacing.xs,
        ),
        child: content,
      ),
    );
  }
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AssalTypography.caption
                .copyWith(color: AssalColors.secondary),
          ),
        )
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
