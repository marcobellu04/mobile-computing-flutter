import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String _me = 'guest@local';
  int? _myAge;

  @override
  void initState() {
    super.initState();
    _loadMeAndAge();
  }

  Future<void> _loadMeAndAge() async {
    final prefs = await SharedPreferences.getInstance();
    final me = prefs.getString('currentUserEmail') ??
        prefs.getString('userEmail') ??
        prefs.getString('email') ??
        'guest@local';
    final age = prefs.getInt('userAge');

    if (mounted) {
      setState(() {
        _me = me;
        _myAge = age;
      });
    }
  }

  Future<void> _saveAge(int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userAge', age);
    if (mounted) setState(() => _myAge = age);
  }

  Event _fresh(BuildContext context) {
    final provider = context.read<EventProvider>();
    return provider.events.firstWhere(
      (e) => e.id == widget.event.id,
      orElse: () => widget.event,
    );
  }

  bool _isFull(Event e) => e.participants.length >= e.maxParticipants;
  bool _isIn(Event e) => e.participants.contains(_me);
  bool _hasRequested(Event e) => e.pendingRequests.contains(_me);

  bool _isOwner(Event e) =>
      _me.trim().toLowerCase() == e.ownerEmail.trim().toLowerCase();

  Event _copyWith({
    required Event base,
    List<String>? participants,
    List<String>? pendingRequests,
    String? fullAddress,
  }) {
    return Event(
      id: base.id,
      name: base.name,
      description: base.description,
      date: base.date,
      ownerEmail: base.ownerEmail,
      maxParticipants: base.maxParticipants,
      participants: participants ?? base.participants,
      pendingRequests: pendingRequests ?? base.pendingRequests,
      listType: base.listType,
      venueId: base.venueId,
      fullAddress: fullAddress ?? base.fullAddress,
      ageRestrictionType: base.ageRestrictionType,
      ageRestrictionValue: base.ageRestrictionValue,
      zone: base.zone,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- AGE LOGIC ----

  String _ageRuleLabel(Event e) {
    if (e.ageRestrictionType == AgeRestrictionType.none) return 'Nessuna';
    final v = e.ageRestrictionValue ?? 0;
    if (e.ageRestrictionType == AgeRestrictionType.over) return 'Minimo $v+';
    return 'Massimo $v';
  }

  bool _passesAgeRestriction(Event e, int age) {
    if (e.ageRestrictionType == AgeRestrictionType.none) return true;
    final v = e.ageRestrictionValue;
    if (v == null) return true;

    if (e.ageRestrictionType == AgeRestrictionType.over) return age >= v;
    if (e.ageRestrictionType == AgeRestrictionType.under) return age <= v;
    return true;
  }

  Future<bool> _ensureAgeAllowed(Event e) async {
    if (_isOwner(e)) return true;
    if (e.ageRestrictionType == AgeRestrictionType.none) return true;

    if (_myAge == null) {
      final entered = await _askAgeDialog();
      if (entered == null) return false;
      await _saveAge(entered);
    }

    final age = _myAge!;
    final ok = _passesAgeRestriction(e, age);

    if (!ok) {
      final v = e.ageRestrictionValue ?? 0;
      final msg = e.ageRestrictionType == AgeRestrictionType.over
          ? 'Questo evento è ${v}+ (tu hai $age).'
          : 'Questo evento è massimo $v (tu hai $age).';
      _snack(msg);
      return false;
    }

    return true;
  }

  Future<int?> _askAgeDialog() async {
    final controller = TextEditingController();

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Inserisci la tua età'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Es. 18'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = controller.text.trim();
                final age = int.tryParse(raw);
                if (age == null || age < 1 || age > 120) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci un numero valido.')),
                  );
                  return;
                }
                Navigator.pop(ctx, age);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  // ---- ADDRESS EDIT (OWNER) ----

  Future<String?> _askAddressDialog(String initial) async {
    final controller = TextEditingController(text: initial);

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Indirizzo completo'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.streetAddress,
            decoration: const InputDecoration(
              hintText: 'Es. Via Roma 10, 00100 Roma',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci un indirizzo valido.')),
                  );
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAddressToEvent() async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);

    if (!_isOwner(current)) {
      _snack('Solo l’organizzatore può modificare l’indirizzo.');
      return;
    }

    final initial = (current.fullAddress ?? '').trim();
    final newAddress = await _askAddressDialog(initial);
    if (newAddress == null) return;

    final updated = _copyWith(base: current, fullAddress: newAddress);
    provider.updateEvent(updated);
    _snack('Indirizzo aggiornato ✅');
    setState(() {});
  }

  // ---- ACTIONS ----

  Future<void> _joinOrRequest() async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);

    final allowed = await _ensureAgeAllowed(current);
    if (!allowed) return;

    if (_isIn(current)) {
      _snack('Sei già tra i partecipanti.');
      return;
    }

    if (_isFull(current)) {
      _snack('Evento pieno.');
      return;
    }

    if (current.listType == ListType.open) {
      final updated = _copyWith(
        base: current,
        participants: [...current.participants, _me],
      );
      provider.updateEvent(updated);
      _snack('Partecipazione confermata!');
      setState(() {});
      return;
    }

    if (_hasRequested(current)) {
      _snack('Hai già inviato una richiesta.');
      return;
    }

    final updated = _copyWith(
      base: current,
      pendingRequests: [...current.pendingRequests, _me],
    );
    provider.updateEvent(updated);
    _snack('Richiesta inviata!');
    setState(() {});
  }

  Future<void> _cancelRequest() async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);

    if (!_hasRequested(current)) {
      _snack('Nessuna richiesta da annullare.');
      return;
    }

    final updated = _copyWith(
      base: current,
      pendingRequests: current.pendingRequests.where((x) => x != _me).toList(),
    );
    provider.updateEvent(updated);
    _snack('Richiesta annullata.');
    setState(() {});
  }

  Future<void> _leaveEvent() async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);

    if (!_isIn(current)) {
      _snack('Non risulti tra i partecipanti.');
      return;
    }

    final updated = _copyWith(
      base: current,
      participants: current.participants.where((x) => x != _me).toList(),
    );
    provider.updateEvent(updated);
    _snack('Sei uscito dall’evento.');
    setState(() {});
  }

  Future<void> _approveRequest(String email) async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);

    if (!_isOwner(current)) {
      _snack('Solo l’organizzatore può approvare.');
      return;
    }

    if (_isFull(current)) {
      _snack('Evento pieno: non puoi approvare altre richieste.');
      return;
    }

    if (!current.pendingRequests.contains(email)) return;

    final newPending = current.pendingRequests.where((x) => x != email).toList();
    final newParticipants = [...current.participants];
    if (!newParticipants.contains(email)) newParticipants.add(email);

    final updated = _copyWith(
      base: current,
      pendingRequests: newPending,
      participants: newParticipants,
    );

    provider.updateEvent(updated);
    _snack('Richiesta approvata ✅');
    setState(() {});
  }

  Future<void> _rejectRequest(String email) async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);

    if (!_isOwner(current)) {
      _snack('Solo l’organizzatore può rifiutare.');
      return;
    }

    if (!current.pendingRequests.contains(email)) return;

    final updated = _copyWith(
      base: current,
      pendingRequests: current.pendingRequests.where((x) => x != email).toList(),
    );

    provider.updateEvent(updated);
    _snack('Richiesta rifiutata ❌');
    setState(() {});
  }

  // ---- PRIVACY + ADDRESS ACTIONS ----

  bool _canSeeFullAddress(Event e) {
    final hasAddress = (e.fullAddress ?? '').trim().isNotEmpty;
    if (!hasAddress) return false;
    return _isIn(e) || _isOwner(e);
  }

  Future<void> _copyAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    _snack('Indirizzo copiato ✅');
  }

  Future<void> _openInGoogleMaps(String address) async {
    final q = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Impossibile aprire Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<EventProvider>().events.firstWhere(
          (e) => e.id == widget.event.id,
          orElse: () => widget.event,
        );

    final dateStr =
        '${current.date.day.toString().padLeft(2, "0")}/${current.date.month.toString().padLeft(2, "0")}/${current.date.year}';

    final listTypeStr =
        current.listType == ListType.open ? 'Lista aperta' : 'Lista privata';

    final zoneStr = (current.zone == null || current.zone!.trim().isEmpty)
        ? 'Zona non indicata'
        : current.zone!.trim();

    final isFull = _isFull(current);
    final alreadyIn = _isIn(current);
    final alreadyRequested = _hasRequested(current);
    final isOwner = _isOwner(current);

    String primaryLabel;
    VoidCallback? primaryAction;

    if (alreadyIn) {
      primaryLabel = 'Esci';
      primaryAction = _leaveEvent;
    } else if (current.listType == ListType.open) {
      primaryLabel = isFull ? 'Evento pieno' : 'Partecipa';
      primaryAction = isFull ? null : _joinOrRequest;
    } else {
      if (alreadyRequested) {
        primaryLabel = 'Annulla richiesta';
        primaryAction = _cancelRequest;
      } else {
        primaryLabel = isFull ? 'Evento pieno' : 'Richiedi accesso';
        primaryAction = isFull ? null : _joinOrRequest;
      }
    }

    final address = (current.fullAddress ?? '').trim();
    final canSeeAddress = _canSeeFullAddress(current);
    final ageRule = _ageRuleLabel(current);

    return Scaffold(
      appBar: AppBar(title: Text(current.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            current.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$dateStr • $zoneStr',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: current.listType == ListType.open ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                listTypeStr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Età
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Età',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _myAge == null ? 'Non impostata' : 'La tua: $_myAge',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              IconButton(
                onPressed: () async {
                  final entered = await _askAgeDialog();
                  if (entered != null) {
                    await _saveAge(entered);
                    _snack('Età salvata ✅');
                  }
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Imposta età',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Regola: $ageRule', style: const TextStyle(fontSize: 14)),

          const SizedBox(height: 16),

          if ((current.description ?? '').trim().isNotEmpty) ...[
            const Text(
              'Descrizione',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              current.description!,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 16),
          ],

          const Text(
            'Partecipanti',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${current.participants.length}/${current.maxParticipants}${isFull ? " • Pieno" : ""}',
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 16),

          const Text(
            'Organizzatore',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(current.ownerEmail, style: const TextStyle(fontSize: 14)),

          const SizedBox(height: 16),

          // Indirizzo + copia + maps + (owner edit)
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Indirizzo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (isOwner)
                TextButton(
                  onPressed: _saveAddressToEvent,
                  child: Text(address.isEmpty ? 'Aggiungi' : 'Modifica'),
                ),
              if (canSeeAddress && address.isNotEmpty) ...[
                IconButton(
                  onPressed: () => _copyAddress(address),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copia indirizzo',
                ),
                IconButton(
                  onPressed: () => _openInGoogleMaps(address),
                  icon: const Icon(Icons.map_outlined),
                  tooltip: 'Apri in Google Maps',
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (canSeeAddress)
            Text(
              address.isEmpty ? 'Non disponibile' : address,
              style: const TextStyle(fontSize: 14),
            )
          else
            Text(
              address.isEmpty
                  ? (isOwner
                      ? 'Non hai ancora inserito l’indirizzo.'
                      : 'Indirizzo non disponibile.')
                  : 'Visibile solo dopo approvazione / partecipazione.',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),

          const SizedBox(height: 16),

          // Richieste per evento privato
          if (current.listType == ListType.closed) ...[
            const Text(
              'Richieste in attesa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (current.pendingRequests.isEmpty)
              const Text('Nessuna richiesta al momento.',
                  style: TextStyle(fontSize: 14))
            else if (!isOwner)
              Text('Totale richieste: ${current.pendingRequests.length}',
                  style: const TextStyle(fontSize: 14))
            else
              Column(
                children: current.pendingRequests.map((email) {
                  return Card(
                    child: ListTile(
                      title: Text(email),
                      subtitle: const Text('Vuole partecipare'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: isFull ? null : () => _approveRequest(email),
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: 'Approva',
                          ),
                          IconButton(
                            onPressed: () => _rejectRequest(email),
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: 'Rifiuta',
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: primaryAction,
                  child: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
