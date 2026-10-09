import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/site_book.dart';
import 'package:flutter/material.dart';

/// The "Site or app" field, offering matching sites in a short list under it
/// as a name is typed. Picking one fills the field and moves on to the
/// username. Typing a name that is not offered is fine: it is remembered when
/// the password is saved.
class SiteNameField extends StatefulWidget {
  const SiteNameField({
    super.key,
    required this.controller,
    required this.sites,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController controller;

  /// Everything that may be offered, best first (see [SiteBook.all]).
  final List<Site> sites;
  final bool autofocus;
  final FormFieldValidator<String>? validator;

  @override
  State<SiteNameField> createState() => _SiteNameFieldState();
}

class _SiteNameFieldState extends State<SiteNameField> {
  // Owned here so the field keeps focus while the list opens and closes
  // around it.
  final FocusNode _focus = FocusNode();

  /// The name last picked from the list. The list stays shut while the field
  /// still says exactly that, and opens again as soon as it is edited.
  String? _picked;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<Site> _options(String text) {
    if (_picked != null && text == _picked) return const <Site>[];
    _picked = null;
    return SiteBook.suggestions(text, widget.sites);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => RawAutocomplete<Site>(
        textEditingController: widget.controller,
        focusNode: _focus,
        displayStringForOption: (Site s) => s.name,
        optionsBuilder: (TextEditingValue value) => _options(value.text),
        onSelected: (Site site) {
          _picked = site.name;
          FocusScope.of(context).nextFocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Site or app',
                hintText: 'e.g. Gmail, Bank, Wi-Fi',
              ),
              validator: widget.validator,
              onFieldSubmitted: (_) => onSubmitted(),
            ),
        // Built from the field's text as it is now, not from the options the
        // autocomplete last computed: those go stale after a pick, and came
        // back (Netflix under "Nepal Investment Mega Bank") when the field
        // was tapped again.
        optionsViewBuilder: (context, onSelected, _) =>
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final List<Site> now = _options(value.text);
                if (now.isEmpty) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: box.maxWidth,
                    child: SiteSuggestions(
                      options: now,
                      onSelected: onSelected,
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

/// The matching sites in a small bordered list at the field: three rows
/// showing, with a scroll bar always in view when there are more.
class SiteSuggestions extends StatefulWidget {
  const SiteSuggestions({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<Site> options;
  final ValueChanged<Site> onSelected;

  /// Rows shown before the list scrolls.
  static const int visibleRows = 3;
  static const double rowHeight = 52;

  @override
  State<SiteSuggestions> createState() => _SiteSuggestionsState();
}

class _SiteSuggestionsState extends State<SiteSuggestions> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          side: BorderSide(color: p.borderStrong.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: SiteSuggestions.rowHeight * SiteSuggestions.visibleRows,
          ),
          // Always shown, not only mid-scroll: three rows of a longer list
          // would look like the whole of it otherwise.
          child: RawScrollbar(
            controller: _scroll,
            thumbVisibility: widget.options.length > SiteSuggestions.visibleRows,
            thickness: 4,
            radius: const Radius.circular(4),
            thumbColor: p.primary.withValues(alpha: 0.6),
            crossAxisMargin: 4,
            mainAxisMargin: 8,
            padding: EdgeInsets.zero,
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.options.length,
              itemBuilder: (BuildContext context, int i) {
                final Site site = widget.options[i];
                return InkWell(
                  onTap: () => widget.onSelected(site),
                  child: Container(
                    height: SiteSuggestions.rowHeight,
                    padding: const EdgeInsets.only(left: Space.md, right: Space.lg),
                    child: Row(
                      children: [
                        Monogram(site.name, size: 32),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Text(
                            site.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyLarge,
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          site.kind.label,
                          style: t.labelSmall?.copyWith(color: p.muted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
