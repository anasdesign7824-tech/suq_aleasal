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
          return AssalStateView<List<AssalReviewSummary>>(
            state: snapshot.data!,
            onRetry: () => setState(() => future = widget.repository.listReviews(widget.product.id)),
            builder: (reviews) => Column(
              children: reviews.map<Widget>((review) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Row(children: [Text(review.authorName ?? 'عميل'), const SizedBox(width: AssalSpacing.sm), RatingStars(rating: review.rating.toDouble())]),
                  subtitle: Text(review.body ?? 'تجربة موثقة'),
                ),
              )).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
      OutlinedButton.icon(onPressed: _writeReview, icon: const Icon(Icons.rate_review_outlined), label: const Text('أضف مراجعتك')),
    ]);
  }

  Future<void> _writeReview() async {
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted || session.user == null) return;
    final body = TextEditingController();
    var rating = 5;
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setModal) => AlertDialog(
        title: const Text('مراجعتك'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(initialValue: rating, items: [1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((item) => DropdownMenuItem(value: item, child: Text('$item نجوم'))).toList(), onChanged: (value) => setModal(() => rating = value ?? 5)),
          TextField(controller: body, maxLines: 3, decoration: const InputDecoration(hintText: 'شارك ما يفيد الآخرين')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('نشر')),
        ],
      )),
    );
    if (submit == true && body.text.trim().isNotEmpty) {
      final result = await widget.repository.createReview(
        session.user!.id,
        AssalReviewDraft(
          productId: widget.product.id,
          storeId: widget.product.storeId,
          rating: rating,
          body: body.text.trim(),
        ),
      );
      if (!mounted) {
        body.dispose();
        return;
      }
      if (result is AssalData<AssalReviewSummary>) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال المراجعة للمراجعة قبل نشرها.')),
        );
        setState(() => future = widget.repository.listReviews(widget.product.id));
      } else if (result is AssalError<AssalReviewSummary>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    }
    body.dispose();
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
          return AssalStateView<List<AssalCommentSummary>>(
            state: snapshot.data!,
            onRetry: () => setState(() => future = widget.repository.listComments(widget.targetId)),
            builder: (comments) => Column(
              children: comments.map<Widget>((comment) => Card(child: ListTile(title: Text(comment.authorName), subtitle: Text(comment.body)))).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(hintText: 'اكتب تعليقًا مفيدًا'))),
        IconButton(onPressed: _add, icon: const Icon(Icons.send_rounded), tooltip: 'إرسال التعليق'),
      ]),
    ]);
  }

  Future<void> _add() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
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
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التعليق.')),
      );
      setState(() => future = widget.repository.listComments(widget.targetId));
    } else if (result is AssalError<AssalCommentSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.messageAr)),
      );
    }
  }
}

