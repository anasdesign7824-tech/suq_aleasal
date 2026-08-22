import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_core.dart';

class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.repository, required this.product});
  final AssalRepository repository;
  final AssalProductSummary product;
  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}
class _ReviewsSectionState extends State<ReviewsSection> {
  late Future<AssalLoadState<List<AssalReviewSummary>>> future;
  final List<AssalReviewSummary> optimisticReviews = <AssalReviewSummary>[];
  bool reviewSubmitting = false;

  @override
  void initState() {
    super.initState();
    future = widget.repository.listReviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'المراجعات'),
      FutureBuilder<AssalLoadState<List<AssalReviewSummary>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          final serverState = snapshot.data!;
          final effectiveState = optimisticReviews.isNotEmpty &&
                  (serverState is AssalEmpty<List<AssalReviewSummary>> ||
                      (serverState is AssalData<List<AssalReviewSummary>> &&
                          serverState.value.isEmpty))
              ? AssalData<List<AssalReviewSummary>>(optimisticReviews)
              : serverState;
          return AssalStateView<List<AssalReviewSummary>>(
            state: effectiveState,
                        onRetry: () {
              setState(() {
                future = widget.repository.listReviews(widget.product.id);
              });
            },

            builder: (reviews) {
              final serverIds = reviews.map((review) => review.id).toSet();
              final displayedReviews = <AssalReviewSummary>[
                ...optimisticReviews
                    .where((review) => !serverIds.contains(review.id)),
                ...reviews,
              ];
              return Column(
                children: displayedReviews
                    .map<Widget>((review) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Row(
                              children: [
                                Text(review.authorName ?? 'عميل'),
                                const SizedBox(width: AssalSpacing.sm),
                                RatingStars(rating: review.rating.toDouble()),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.body ?? 'تجربة موثقة'),
                                if (review.status != ReviewStatus.approved)
                                  const Text(
                                    'قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.',
                                  ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
            OutlinedButton.icon(
        onPressed: reviewSubmitting ? null : _writeReview,
        icon: reviewSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.rate_review_outlined),
        label: Text(reviewSubmitting ? 'جارٍ إرسال المراجعة...' : 'أضف مراجعتك'),
      ),

    ]);
  }

    Future<void> _writeReview() async {
    if (reviewSubmitting) return;
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted || session.user == null) return;
    final body = TextEditingController();
    var rating = 5;
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('مراجعتك'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              initialValue: rating,
              decoration: const InputDecoration(labelText: 'التقييم'),
              items: [1, 2, 3, 4, 5]
                  .map<DropdownMenuItem<int>>(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text('$item نجوم'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setModal(() => rating = value ?? 5),
            ),
            const SizedBox(height: AssalSpacing.sm),
            TextField(
              controller: body,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setModal(() {}),
              decoration: const InputDecoration(
                labelText: 'نص المراجعة',
                hintText: 'شارك ما يفيد الآخرين',
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: body.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('نشر'),
            ),
          ],
        ),
      ),
    );
    if (submit != true || body.text.trim().isEmpty) {
      body.dispose();
      return;
    }
    setState(() => reviewSubmitting = true);
    try {
      final result = await widget.repository.createReview(
        session.user!.id,
        AssalReviewDraft(
          productId: widget.product.id,
          storeId: widget.product.storeId,
          rating: rating,
          body: body.text.trim(),
        ),
      );
      if (!mounted) return;
      if (result is AssalData<AssalReviewSummary>) {
        optimisticReviews.removeWhere((item) => item.id == result.value.id);
        setState(() {
          optimisticReviews.insert(0, result.value);
          future = widget.repository.listReviews(widget.product.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.value.status == ReviewStatus.approved
                  ? 'تم نشر تقييمك.'
                  : 'تم حفظ تقييمك وسيظهر للآخرين بعد الاعتماد.',
            ),
          ),
        );
      } else if (result is AssalError<AssalReviewSummary>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      body.dispose();
      if (mounted) setState(() => reviewSubmitting = false);
    }
  }

}

class CommentsSection extends StatefulWidget {
  const CommentsSection({super.key, required this.repository, required this.targetId});
  final AssalRepository repository;
  final String targetId;
  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}
class _CommentsSectionState extends State<CommentsSection> {
  late Future<AssalLoadState<List<AssalCommentSummary>>> future;
  final controller = TextEditingController();
  final List<AssalCommentSummary> optimisticComments =
      <AssalCommentSummary>[];
  bool adding = false;

  @override
  void initState() {
    super.initState();
    future = widget.repository.listComments(widget.targetId);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'التعليقات'),
      FutureBuilder<AssalLoadState<List<AssalCommentSummary>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          final serverState = snapshot.data!;
          final effectiveState = optimisticComments.isNotEmpty &&
                  (serverState is AssalEmpty<List<AssalCommentSummary>> ||
                      (serverState is AssalData<List<AssalCommentSummary>> &&
                          serverState.value.isEmpty))
              ? AssalData<List<AssalCommentSummary>>(optimisticComments)
              : serverState;
          return AssalStateView<List<AssalCommentSummary>>(
            state: effectiveState,
                        onRetry: () {
              setState(() {
                future = widget.repository.listComments(widget.targetId);
              });
            },

            builder: (comments) {
              final serverIds = comments.map((comment) => comment.id).toSet();
              final displayedComments = <AssalCommentSummary>[
                ...optimisticComments
                    .where((comment) => !serverIds.contains(comment.id)),
                ...comments,
              ];
              return Column(
                children: displayedComments
                    .map<Widget>(
                      (comment) => Card(
                        child: ListTile(
                          title: Text(comment.authorName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.body),
                              if (comment.isLocal)
                                const Text('تم حفظ التعليق والمزامنة مع التاجر.'),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !adding,
            minLines: 1,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.send,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              _add();
            },
            decoration: const InputDecoration(
              labelText: 'التعليق',
              hintText: 'اكتب تعليقًا مفيدًا',
            ),
          ),
        ),
        Semantics(
          button: true,
          label: adding ? 'جارٍ إرسال التعليق' : 'إرسال التعليق',
          child: IconButton(
            onPressed: adding || controller.text.trim().isEmpty ? null : _add,
            icon: adding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            tooltip: adding ? 'جارٍ إرسال التعليق' : 'إرسال التعليق',
          ),
        ),
      ]),

    ]);
  }

    Future<void> _add() async {
    if (adding) return;
    final body = controller.text.trim();
    if (body.isEmpty) return;
    setState(() => adding = true);
    try {
      final session = await requireUserSession(context, widget.repository);
      if (session == null || !mounted || session.user == null) return;
      final result = await widget.repository.createComment(
        session.user!.id,
        session.user!.nameAr,
        widget.targetId,
        body,
      );
      if (!mounted) return;
      if (result is AssalData<AssalCommentSummary>) {
        optimisticComments.removeWhere((item) => item.id == result.value.id);
        setState(() {
          optimisticComments.insert(
            0,
            AssalCommentSummary(
              id: result.value.id,
              targetId: result.value.targetId,
              authorId: result.value.authorId,
              authorName: result.value.authorName,
              body: result.value.body,
              parentId: result.value.parentId,
              createdAt: result.value.createdAt,
              updatedAt: result.value.updatedAt,
              likeCount: result.value.likeCount,
              replyCount: result.value.replyCount,
              isLiked: result.value.isLiked,
              isLocal: true,
            ),
          );
          controller.clear();
          future = widget.repository.listComments(widget.targetId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعليق وإرساله للتاجر.')),
        );
      } else if (result is AssalError<AssalCommentSummary>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

}

