import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:meattrace_app/providers/animal_provider.dart';
import 'package:meattrace_app/models/animal.dart';
import 'package:meattrace_app/utils/app_colors.dart';

/// One row of the inventory list: a source animal plus whatever of it is
/// still available at this processing unit.
///
/// Slaughter parts are deliberately never listed on their own. A part
/// carries only a part type ("Head", "Feet", "Whole Carcass"), so a flat
/// list of parts never names the animal it came from - which is why an
/// animal that had just been received looked absent from this screen even
/// though its parts were sitting in the list. Parts are folded under their
/// parent animal instead, the same shape CreateProductScreen's source
/// picker uses.
class _InventoryGroup {
  _InventoryGroup({
    required this.animalId,
    required this.label,
    required this.sortTime,
    this.animal,
    this.origin,
    this.parts = const [],
    this.wholeRemaining,
    this.wholeOriginal,
  });

  final int animalId;
  final String label;
  final DateTime sortTime;
  final Animal? animal;

  /// Secondary identity line - animal ID and abbatoir where known.
  final String? origin;
  final List<SlaughterPart> parts;

  /// Set only when the animal itself still carries weight, i.e. it was
  /// received whole and never split. Once a carcass measurement creates
  /// slaughter parts the backend zeroes the animal's own remaining_weight
  /// (see create_slaughter_parts_from_measurement) and the parts become the
  /// authoritative pool, so such an animal can only appear via its parts.
  final double? wholeRemaining;
  final double? wholeOriginal;

  bool get isWholeAnimal => parts.isEmpty;

  double get remainingWeight => isWholeAnimal
      ? (wholeRemaining ?? 0)
      : parts.fold<double>(
          0,
          (sum, p) => sum + (p.remainingWeight ?? p.weight),
        );

  double get originalWeight => isWholeAnimal
      ? (wholeOriginal ?? 0)
      : parts.fold<double>(0, (sum, p) => sum + p.weight);

  double get usedFraction {
    if (originalWeight <= 0) return 0;
    return ((originalWeight - remainingWeight) / originalWeight).clamp(
      0.0,
      1.0,
    );
  }
}

/// Current Inventory: raw materials (whole animals and slaughter parts)
/// received at this processing unit and not yet fully consumed, grouped by
/// the animal they came from.
class CurrentInventoryScreen extends StatefulWidget {
  const CurrentInventoryScreen({super.key});

  @override
  State<CurrentInventoryScreen> createState() => _CurrentInventoryScreenState();
}

class _CurrentInventoryScreenState extends State<CurrentInventoryScreen> {
  bool _isLoading = true;
  String? _error;

  /// Surfaced rather than swallowed: when the parts request fails, almost
  /// everything on this screen goes missing, and a silent empty list reads
  /// as "nothing was received" instead of "the fetch failed".
  String? _partsError;

  List<_InventoryGroup> _groups = [];

  /// Kept outside the ExpansionTiles so a fold/unfold survives a filter
  /// change or a refresh.
  final Set<int> _expandedAnimals = {};

  String _filter = 'all'; // 'all', 'animals', 'parts'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _partsError = null;
    });

    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );

      await animalProvider.fetchAnimals();

      // Parts aren't cached on the provider, so they're fetched separately.
      List<SlaughterPart> slaughterParts = [];
      String? partsError;
      try {
        slaughterParts = await animalProvider.getSlaughterPartsList();
      } catch (e) {
        debugPrint('Error loading slaughter parts: $e');
        partsError = e.toString();
      }

      if (!mounted) return;
      setState(() {
        _partsError = partsError;
        _groups = _buildGroups(animalProvider.animals, slaughterParts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Turns the two flat server lists into one animal-per-row model.
  ///
  /// "Received" (receivedBy != null) stays mandatory - this screen is
  /// specifically for already-received raw material. The unit-match is
  /// dropped rather than compared against processingUnitId
  /// (UserProfile.processing_unit, a single FK): AnimalViewSet and
  /// SlaughterPartViewSet already scope both lists to every processing unit
  /// this user belongs to via ProcessingUnitUser (a user can belong to more
  /// than one), so a stale or single-unit processingUnitId can only wrongly
  /// hide material received into a second unit. (The two sources are known
  /// to drift - see the sync_processing_unit_memberships command.)
  List<_InventoryGroup> _buildGroups(
    List<Animal> animals,
    List<SlaughterPart> parts,
  ) {
    final animalsById = <int, Animal>{
      for (final a in animals)
        if (a.id != null) a.id!: a,
    };

    final partsByAnimal = <int, List<SlaughterPart>>{};
    for (final part in parts) {
      if (part.receivedBy == null) continue;
      if ((part.remainingWeight ?? part.weight) <= 0) continue;
      partsByAnimal.putIfAbsent(part.animalId, () => []).add(part);
    }

    final groups = <_InventoryGroup>[];

    partsByAnimal.forEach((animalId, animalParts) {
      animalParts.sort(
        (a, b) => a.partType.displayName.compareTo(b.partType.displayName),
      );
      final animal = animalsById[animalId];
      groups.add(
        _InventoryGroup(
          animalId: animalId,
          animal: animal,
          label: _labelForParts(animalParts.first, animal),
          origin: _originLine(animal, animalParts.first.animalCode),
          parts: animalParts,
          sortTime: animalParts
              .map((p) => p.receivedAt ?? p.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
      );
    });

    // Whole animals that still carry their own weight - received without
    // ever being split into parts. An animal that *was* split is already
    // represented by its parts group above, and its own remaining_weight is
    // zero, so it cannot double-count here.
    for (final animal in animals) {
      if (animal.id == null) continue;
      if (animal.receivedBy == null) continue;
      if ((animal.remainingWeight ?? 0) <= 0) continue;
      if (partsByAnimal.containsKey(animal.id)) continue;

      groups.add(
        _InventoryGroup(
          animalId: animal.id!,
          animal: animal,
          label: _labelForAnimal(animal),
          origin: _originLine(animal, animal.animalId),
          wholeRemaining: animal.remainingWeight ?? 0,
          wholeOriginal: animal.liveWeight ?? animal.remainingWeight ?? 0,
          sortTime: animal.receivedAt ?? animal.createdAt,
        ),
      );
    }

    // Most recently received first, so a just-received animal lands at the
    // top instead of being buried by registration order.
    groups.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return groups;
  }

  String _labelForAnimal(Animal animal) {
    final name = animal.animalName;
    return name != null && name.isNotEmpty
        ? '${animal.species} - $name'
        : '${animal.species} - ${animal.animalId}';
  }

  /// Same "species - name/ID" format, read off the part's own
  /// species/animal_name/animal_id fields (the backend carries them on each
  /// part) so a parts group is still named even when the parent animal is
  /// missing from the animals page.
  String _labelForParts(SlaughterPart part, Animal? animal) {
    if (animal != null) return _labelForAnimal(animal);
    if (part.species == null) return 'Animal #${part.animalId}';
    final name = part.animalName;
    return name != null && name.isNotEmpty
        ? '${part.species} - $name'
        : '${part.species} - ${part.animalCode ?? part.animalId}';
  }

  String? _originLine(Animal? animal, String? animalCode) {
    final code = animal?.animalId ?? animalCode;
    final abbatoir = animal?.abbatoirName;
    if (code == null && (abbatoir == null || abbatoir.isEmpty)) return null;
    if (abbatoir == null || abbatoir.isEmpty) return 'ID: $code';
    if (code == null) return 'Abbatoir: $abbatoir';
    return 'ID: $code  •  Abbatoir: $abbatoir';
  }

  List<_InventoryGroup> get _visibleGroups {
    switch (_filter) {
      case 'animals':
        return _groups.where((g) => g.isWholeAnimal).toList();
      case 'parts':
        return _groups.where((g) => !g.isWholeAnimal).toList();
      default:
        return _groups;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Inventory'),
        backgroundColor: AppColors.processorPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading inventory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (_partsError != null) _buildPartsErrorBanner(),
        _buildFilterChips(),
        _buildSummary(),
        Expanded(
          child: RefreshIndicator(onRefresh: _loadData, child: _buildList()),
        ),
      ],
    );
  }

  Widget _buildPartsErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Slaughter parts could not be loaded, so this list may be '
              'incomplete. Pull down to retry.',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final wholeCount = _groups.where((g) => g.isWholeAnimal).length;
    final partsCount = _groups.fold<int>(0, (sum, g) => sum + g.parts.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildFilterChip('All (${_groups.length})', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Whole ($wholeCount)', 'animals'),
          const SizedBox(width: 8),
          _buildFilterChip('Parts ($partsCount)', 'parts'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.processorPrimary.withValues(alpha: 0.2),
    );
  }

  Widget _buildSummary() {
    final visible = _visibleGroups;
    final animalCount = visible.length;
    final partCount = visible.fold<int>(0, (sum, g) => sum + g.parts.length);
    final totalWeight = visible.fold<double>(
      0,
      (sum, g) => sum + g.remainingWeight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.processorPrimary.withValues(alpha: 0.1),
            AppColors.processorPrimary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.processorPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(Icons.pets, '$animalCount', 'Animals', 'sources'),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          _buildSummaryItem(
            Icons.content_cut,
            '$partCount',
            'Parts',
            'available',
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          _buildSummaryItem(
            Icons.scale,
            totalWeight.toStringAsFixed(1),
            'Total',
            'kg available',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    String subtitle,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.processorPrimary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildList() {
    final groups = _visibleGroups;

    if (groups.isEmpty) {
      // Kept scrollable so the RefreshIndicator still works when empty.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No raw materials available',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Only animals and parts you have received, and that still have '
              'weight left, appear here. Accept a transfer under Receive to '
              'add stock.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: groups.length,
      itemBuilder: (context, index) => _buildGroupCard(groups[index]),
    );
  }

  Widget _buildGroupCard(_InventoryGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: group.isWholeAnimal
          ? _buildWholeAnimalTile(group)
          : _buildPartsGroupTile(group),
    );
  }

  Widget _buildWholeAnimalTile(_InventoryGroup group) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.processorPrimary.withValues(alpha: 0.1),
        child: Icon(Icons.pets, color: AppColors.processorPrimary),
      ),
      title: Text(
        group.label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.origin ?? 'Whole animal',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          _buildRemainingBar(group.usedFraction, group.remainingWeight),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => context.push('/animals/${group.animalId}'),
    );
  }

  Widget _buildPartsGroupTile(_InventoryGroup group) {
    final partCount = group.parts.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // Keyed by animal so the fold state survives filter changes and
        // list rebuilds.
        key: PageStorageKey<int>(group.animalId),
        initiallyExpanded: _expandedAnimals.contains(group.animalId),
        onExpansionChanged: (expanded) {
          if (expanded) {
            _expandedAnimals.add(group.animalId);
          } else {
            _expandedAnimals.remove(group.animalId);
          }
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.processorPrimary.withValues(alpha: 0.1),
          child: Icon(Icons.pets, color: AppColors.processorPrimary),
        ),
        title: Text(
          group.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$partCount part${partCount > 1 ? 's' : ''}'
              '${group.origin != null ? '  •  ${group.origin}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            _buildRemainingBar(group.usedFraction, group.remainingWeight),
          ],
        ),
        children: [
          ...group.parts.map(_buildPartRow),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/animals/${group.animalId}'),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View animal'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartRow(SlaughterPart part) {
    final remaining = part.remainingWeight ?? part.weight;
    final used = part.weight > 0
        ? ((part.weight - remaining) / part.weight).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(72, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.content_cut, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.partType.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${remaining.toStringAsFixed(1)} of '
                  '${part.weight.toStringAsFixed(1)} ${part.weightUnit} left',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: used,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    used > 0.8 ? Colors.red : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingBar(double usedFraction, double remainingWeight) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: usedFraction,
            minHeight: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              usedFraction > 0.8 ? Colors.red : AppColors.processorPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${remainingWeight.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: remainingWeight > 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
