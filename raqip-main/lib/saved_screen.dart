import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'settings_screen.dart';

// شاشة إدارة المواقع المحفوظة:
// - بحث سريع
// - تعديل الاسم
// - نسخ الإحداثيات
// - حذف العناصر

class SavedScreen extends StatefulWidget {
  final List<SavedLocation> savedLocations;
  final ValueChanged<List<SavedLocation>> onUpdate;
  final ValueChanged<SavedLocation> onShowOnMap;
  final String currentLanguage;

  const SavedScreen({
    super.key,
    required this.savedLocations,
    required this.onUpdate,
    required this.onShowOnMap,
    this.currentLanguage = 'ar',
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late List<SavedLocation> _locations;
  String _searchQuery = '';
  String? _expandedId;
  String? _editingId;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _locations = List.from(widget.savedLocations);
  }

  @override
  void dispose() {
    for (final ctrl in _editControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<SavedLocation> get _filtered {
    if (_searchQuery.isEmpty) return _locations;
    return _locations
        .where((l) => l.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _deleteLocation(SavedLocation loc) {
    final s = S(widget.currentLanguage == 'ar');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(s.confirmDelete),
        content: Text('${s.deleteMsg} "${loc.name}"?\n${s.cannotUndo}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              setState(() {
                _locations.removeWhere((l) => l.id == loc.id);
                if (_expandedId == loc.id) _expandedId = null;
              });
              widget.onUpdate(_locations);
              Navigator.pop(ctx);
              _showSnackbar('"${loc.name}" ${s.deleted}', isError: true);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  void _saveEdit(SavedLocation loc) {
    final s = S(widget.currentLanguage == 'ar');
    final ctrl = _editControllers[loc.id];
    if (ctrl == null) return;
    final newName = ctrl.text.trim();
    if (newName.isEmpty) return;
    setState(() {
      loc.name = newName;
      _editingId = null;
    });
    widget.onUpdate(_locations);
    _showSnackbar(s.nameUpdated);
  }

  void _copyCoords(SavedLocation loc) {
    final s = S(widget.currentLanguage == 'ar');
    Clipboard.setData(ClipboardData(text: loc.coordsString));
    _showSnackbar(s.coordsCopied);
  }

  ({double lat, double lng})? _parseCoordinates(String value) {
    final normalized = value.trim().replaceAll('،', ',');
    final parts = normalized.split(',').map((p) => p.trim()).toList();
    if (parts.length != 2) return null;

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    final validLat = lat != null && lat >= -90 && lat <= 90;
    final validLng = lng != null && lng >= -180 && lng <= 180;
    if (!validLat || !validLng) return null;

    return (lat: lat, lng: lng);
  }

  void _showAddLocationDialog() {
    final s = S(widget.currentLanguage == 'ar');
    final isAr = widget.currentLanguage == 'ar';
    final nameCtrl = TextEditingController();
    final coordsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.add_location_alt_rounded),
        title: Text(s.addLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                labelText: s.locationName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: coordsCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: s.coordinates,
                hintText: s.coordinatesHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final coords = _parseCoordinates(coordsCtrl.text);
              if (name.isEmpty || coords == null) {
                _showSnackbar(s.invalidCoords, isError: true);
                return;
              }
              final loc = SavedLocation(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: name,
                lat: coords.lat,
                lng: coords.lng,
                savedAt: DateTime.now(),
              );
              setState(() {
                _locations.add(loc);
                _expandedId = loc.id;
              });
              widget.onUpdate(_locations);
              Navigator.pop(ctx);
              _showSnackbar(s.locationAdded);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    final color = isError ? RaqibColors.errorRed : RaqibColors.successGreen;
    final bgColor =
        isError ? RaqibColors.errorRedLight : RaqibColors.successGreenLight;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              isError ? Icons.delete_rounded : Icons.check_circle_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(msg,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final s = S(widget.currentLanguage == 'ar');
    final isAr = widget.currentLanguage == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
      appBar: AppBar(
        title: Text(s.saved),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showAddLocationDialog,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(s.addLocation),
              ),
            ),
          ),
          // ── شريط البحث ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: s.searchHint,
                hintTextDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // ── القائمة ─────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(hasSearch: _searchQuery.isNotEmpty, s: s)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final loc = filtered[i];
                      final isExpanded = _expandedId == loc.id;
                      final isEditing = _editingId == loc.id;

                      if (isEditing && !_editControllers.containsKey(loc.id)) {
                        _editControllers[loc.id] =
                            TextEditingController(text: loc.name);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LocationCard(
                          loc: loc,
                          isExpanded: isExpanded,
                          isEditing: isEditing,
                          editController: _editControllers[loc.id],
                          s: s,
                          onToggle: () => setState(() {
                            _expandedId = isExpanded ? null : loc.id;
                            if (_editingId == loc.id) _editingId = null;
                          }),
                          onCopy: () => _copyCoords(loc),
                          onEdit: () => setState(() {
                            _editingId = loc.id;
                            _editControllers[loc.id] =
                                TextEditingController(text: loc.name);
                          }),
                          onSaveEdit: () => _saveEdit(loc),
                          onDelete: () => _deleteLocation(loc),
                          onShowOnMap: () {
                            widget.onShowOnMap(loc);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── بطاقة الموقع ──────────────────────────────
class _LocationCard extends StatelessWidget {
  final SavedLocation loc;
  final bool isExpanded;
  final bool isEditing;
  final TextEditingController? editController;
  final S s;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowOnMap;

  const _LocationCard({
    required this.loc,
    required this.isExpanded,
    required this.isEditing,
    required this.editController,
    required this.s,
    required this.onToggle,
    required this.onCopy,
    required this.onEdit,
    required this.onSaveEdit,
    required this.onDelete,
    required this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isExpanded
            ? Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── رأس البطاقة ────────────────
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isEditing
                          ? TextField(
                              controller: editController,
                              textDirection: TextDirection.rtl,
                              autofocus: true,
                              style: Theme.of(context).textTheme.titleSmall,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : Text(
                              loc.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),

                // ── تفاصيل موسعة ───────────────
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  Text(
                    loc.coordsString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CardActionBtn(
                        icon: Icons.copy_rounded,
                        label: s.copy,
                        onTap: onCopy,
                      ),
                      const SizedBox(width: 8),
                      _CardActionBtn(
                        icon: Icons.map_rounded,
                        label: s.openOnMap,
                        onTap: onShowOnMap,
                      ),
                      const SizedBox(width: 8),
                      _CardActionBtn(
                        icon: isEditing ? Icons.check_rounded : Icons.edit_rounded,
                        label: isEditing ? s.save : s.edit,
                        onTap: isEditing ? onSaveEdit : onEdit,
                      ),
                      const SizedBox(width: 8),
                      _CardActionBtn(
                        icon: Icons.delete_rounded,
                        label: s.delete,
                        onTap: onDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _CardActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return SizedBox(
      width: 132,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
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

// ── حالة القائمة الفارغة ───────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final S s;
  const _EmptyState({required this.hasSearch, required this.s});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.bookmark_border_rounded,
            size: 72,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? s.noResults : s.noSaved,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 8),
            Text(
              s.noSavedHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
