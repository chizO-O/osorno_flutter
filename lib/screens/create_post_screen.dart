import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/routine_step.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? existingPost;
  const CreatePostScreen({super.key, this.existingPost});

  bool get isEditing => existingPost != null;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagsController;
  final List<_StepEntry> _steps = [];
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    _titleController = TextEditingController(text: post?.title ?? '');
    _bodyController = TextEditingController(text: post?.body ?? '');
    _tagsController = TextEditingController(text: post?.tags.join(', ') ?? '');
    if (post != null) {
      for (final step in post.routine) {
        _steps.add(_StepEntry.fromRoutine(step));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill in a title and body')));
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final routine = _steps
        .where((s) => s.stepController.text.trim().isNotEmpty)
        .map((s) => RoutineStep(
              stepName: s.stepController.text.trim(),
              product: s.productController.text.trim(),
              timeOfDay: s.timeOfDay,
            ))
        .toList();

    setState(() => _posting = true);
    try {
      if (widget.existingPost == null) {
        await FirestoreService.instance.createPost(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: tags,
          routine: routine,
        );
      } else {
        await FirestoreService.instance.updatePost(
          postId: widget.existingPost!.id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: tags,
          routine: routine,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Post updated' : 'Post published')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Could not update post: $e' : 'Could not post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit post' : 'New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _posting ? null : _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 18)),
              child: _posting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.isEditing ? 'Save' : 'Post'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "What's on your mind?",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Niacinamide, CeraVe',
                helperText: 'Separate with commas',
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Routine (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => setState(() => _steps.add(_StepEntry())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add step'),
                ),
              ],
            ),
            for (int i = 0; i < _steps.length; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _steps[i].stepController,
                              decoration: const InputDecoration(labelText: 'Step (e.g. Cleanser)'),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _steps[i].productController,
                              decoration: const InputDecoration(labelText: 'Product'),
                            ),
                            const SizedBox(height: 10),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 'AM', label: Text('AM')),
                                ButtonSegment(value: 'PM', label: Text('PM')),
                              ],
                              selected: {_steps[i].timeOfDay},
                              onSelectionChanged: (v) =>
                                  setState(() => _steps[i].timeOfDay = v.first),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.muted),
                        onPressed: () => setState(() => _steps.removeAt(i).dispose()),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepEntry {
  final TextEditingController stepController;
  final TextEditingController productController;
  String timeOfDay;

  _StepEntry({String step = '', String product = '', this.timeOfDay = 'AM'})
      : stepController = TextEditingController(text: step),
        productController = TextEditingController(text: product);

  factory _StepEntry.fromRoutine(RoutineStep step) => _StepEntry(
        step: step.stepName,
        product: step.product,
        timeOfDay: step.timeOfDay,
      );

  void dispose() {
    stepController.dispose();
    productController.dispose();
  }
}
