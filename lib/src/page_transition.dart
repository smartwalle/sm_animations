import 'package:flutter/material.dart';

/// This is a fork of  https://github.com/flutter/packages/blob/main/packages/animations/lib/src/page_transition_switcher.dart

typedef KIPageTransitionLayoutBuilder = Widget Function(List<Widget> entries);

typedef KIPageTransitionBuilder = Widget Function(
  Animation<double> primaryAnimation,
  Animation<double> secondaryAnimation,
  Widget child,
);

class KIPageTransition extends StatefulWidget {
  const KIPageTransition({
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.initialAnimate = false,
    this.reverse = false,
    required this.transitionBuilder,
    this.layoutBuilder = defaultLayoutBuilder,
    this.child,
  });

  final Widget? child;

  final Duration duration;

  final bool initialAnimate;

  final bool reverse;

  final KIPageTransitionBuilder transitionBuilder;

  final KIPageTransitionLayoutBuilder layoutBuilder;

  static Widget defaultLayoutBuilder(List<Widget> entries) {
    return Stack(
      alignment: Alignment.center,
      children: entries,
    );
  }

  @override
  State<KIPageTransition> createState() => _KIPageTransitionState();
}

class _KIPageTransitionState extends State<KIPageTransition> with TickerProviderStateMixin {
  final List<_Entry> _entries = <_Entry>[];

  _Entry? _current;

  int _childNumber = 0;

  @override
  void initState() {
    super.initState();

    _addEntryForNewChild(shouldAnimate: widget.initialAnimate);
  }

  @override
  void didUpdateWidget(KIPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the transition builder changed, then update all of the old
    // transitions.
    if (widget.transitionBuilder != oldWidget.transitionBuilder) {
      _entries.forEach(_updateTransitionForEntry);
    }

    final bool hasNewChild = widget.child != null;
    final bool hasOldChild = _current != null;
    if (hasNewChild != hasOldChild || hasNewChild && !Widget.canUpdate(widget.child!, _current!.child)) {
      // Child has changed, fade current entry out and add new entry.
      _childNumber += 1;
      _addEntryForNewChild(shouldAnimate: true);
    } else if (_current != null) {
      assert(hasOldChild && hasNewChild);
      assert(Widget.canUpdate(widget.child!, _current!.child));
      // Child has been updated. Make sure we update the child widget and
      // transition in _currentEntry even though we're not going to start a new
      // animation, but keep the key from the old transition so that we
      // update the transition instead of replacing it.
      _current!.child = widget.child!;
      _updateTransitionForEntry(_current!); // uses entry.child
    }
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addEntryForNewChild({required bool shouldAnimate}) {
    assert(shouldAnimate || _current == null);
    if (_current != null) {
      assert(shouldAnimate);
      if (widget.reverse) {
        _current!.primaryController.reverse();
      } else {
        _current!.secondaryController.forward();
      }
      _current = null;
    }
    if (widget.child == null) {
      return;
    }
    final AnimationController primaryController = AnimationController(duration: widget.duration, vsync: this);
    final AnimationController secondaryController = AnimationController(duration: widget.duration, vsync: this);
    if (shouldAnimate) {
      if (widget.reverse) {
        primaryController.value = 1.0;
        secondaryController.value = 1.0;
        secondaryController.reverse();
      } else {
        primaryController.forward();
      }
    } else {
      assert(_entries.isEmpty);
      primaryController.value = 1.0;
    }
    _current = _newEntry(
      primaryController: primaryController,
      secondaryController: secondaryController,
      child: widget.child!,
    );
    if (widget.reverse && _entries.isNotEmpty) {
      // Add below old child.
      _entries.insert(_entries.length - 1, _current!);
    } else {
      // Add on top of old child.
      _entries.add(_current!);
    }
  }

  _Entry _newEntry({
    required AnimationController primaryController,
    required AnimationController secondaryController,
    required Widget child,
  }) {
    Widget transition = widget.transitionBuilder(primaryController, secondaryController, child);
    _Entry entry = _Entry(
      primaryController: primaryController,
      secondaryController: secondaryController,
      transition: KeyedSubtree.wrap(transition, _childNumber),
      child: child,
    );
    secondaryController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        assert(mounted);
        assert(_entries.contains(entry));
        setState(() {
          _entries.remove(entry);
          entry.dispose();
        });
      }
    });
    primaryController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        assert(mounted);
        assert(_entries.contains(entry));
        setState(() {
          _entries.remove(entry);
          entry.dispose();
        });
      }
    });
    return entry;
  }

  void _updateTransitionForEntry(_Entry entry) {
    final Widget transition = widget.transitionBuilder(
      entry.primaryController,
      entry.secondaryController,
      entry.child,
    );
    entry.transition = KeyedSubtree(key: entry.transition.key, child: transition);
  }

  @override
  Widget build(BuildContext context) {
    return widget.layoutBuilder(_entries.map<Widget>((e) => e.transition).toList());
  }
}

class _Entry {
  _Entry({
    required this.primaryController,
    required this.secondaryController,
    required this.transition,
    required this.child,
  });

  final AnimationController primaryController;
  final AnimationController secondaryController;

  Widget transition;

  Widget child;

  void dispose() {
    primaryController.dispose();
    secondaryController.dispose();
  }
}
