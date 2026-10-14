import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';
import 'qr_scanner_modal.dart';

class EnvelopesTab extends StatefulWidget {
  final List<EnvelopeEntry> entries;
  final List<MemberModel> members;
  final Function(EnvelopeEntry) onAddEntry;
  final Function(String) onRemoveEntry;

  const EnvelopesTab({
    super.key,
    required this.entries,
    required this.members,
    required this.onAddEntry,
    required this.onRemoveEntry,
  });

  @override
  State<EnvelopesTab> createState() => _EnvelopesTabState();
}

class _EnvelopesTabState extends State<EnvelopesTab> {
  final _amountController = TextEditingController();
  final _memberController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _destinacao = 'dizimo';
  String _forma = 'dinheiro';
  MemberModel? _selectedMember;
  List<MemberModel> _filteredMembers = [];
  String? _printingEntryId;

  @override
  void dispose() {
    _amountController.dispose();
    _memberController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onMemberSearch(String term) {
    if (term.trim().length < 2) {
      setState(() => _filteredMembers = []);
      return;
    }
    final t = term.toLowerCase();
    final matches = widget.members.where((m) {
      final nameMatches = m.fullName.toLowerCase().contains(t);
      final envMatches = m.envelopeNumber?.contains(t) ?? false;
      return nameMatches || envMatches;
    }).take(5).toList();

    setState(() => _filteredMembers = matches);
  }

  void _selectMember(MemberModel member) {
    setState(() {
      _selectedMember = member;
      _memberController.text = member.label;
      _filteredMembers = [];
    });
  }

  Future<void> _scanEnvelopeQr() async {
    final scanned = await QrScannerModal.show(context);
    if (scanned == null || scanned.isEmpty) return;

    // Normalização: se vier "IPB:101", "ENV:101", "101", etc.
    String cleanCode = scanned.trim();
    if (cleanCode.toUpperCase().startsWith('IPB:')) {
      cleanCode = cleanCode.substring(4).trim();
    } else if (cleanCode.toUpperCase().startsWith('ENV:')) {
      cleanCode = cleanCode.substring(4).trim();
    }

    MemberModel? match;
    for (final m in widget.members) {
      final env = m.envelopeNumber?.trim();
      if ((env != null && env.isNotEmpty && (env == cleanCode || 'IPB:$env' == scanned)) ||
          m.qrCodePayload == scanned ||
          'IPB:ID${m.id}' == scanned ||
          m.id.toString() == cleanCode) {
        match = m;
        break;
      }
    }

    if (match != null) {
      _selectMember(match);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envelope #${match.envelopeNumber ?? match.id} (${match.fullName}) identificado!'),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _selectedMember = null;
        _memberController.text = 'Envelope #$cleanCode';
        _filteredMembers = [];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envelope #$cleanCode lido (não localizado na lista).'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Foca automaticamente no campo de valor
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _amountFocusNode.requestFocus();
      _amountController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountController.text.length,
      );
    });
  }

  void _addQuickAmount(double delta) {
    final cur = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final total = cur + delta;
    _amountController.text = total.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _submitEntry() async {
    final valStr = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    final val = double.tryParse(valStr);

    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe um valor válido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final membroNome = _selectedMember != null
        ? _selectedMember!.label
        : (_memberController.text.trim().isNotEmpty
            ? _memberController.text.trim()
            : 'Oferta Não Identificada');

    final entryId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newEntry = EnvelopeEntry(
      id: entryId,
      personId: _selectedMember?.id,
      membro: membroNome,
      valor: val,
      destinacao: _destinacao,
      forma: _forma,
      timestamp: timeStr,
    );

    widget.onAddEntry(newEntry);

    _amountController.clear();
    _memberController.clear();
    setState(() {
      _selectedMember = null;
      _filteredMembers = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Envelope de R\$ ${val.toStringAsFixed(2).replaceAll('.', ',')} registrado!'),
        backgroundColor: const Color(0xFF047857),
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-impressão se ativada
    final autoPrint =
        await ThermalPrinterService.instance.autoPrintEnvelopeEnabled();
    if (autoPrint) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        _printReceipt(newEntry, isAutoPrint: true);
      }
    }
  }

  Future<void> _printReceipt(EnvelopeEntry entry, {bool isAutoPrint = false}) async {
    if (_printingEntryId != null) return;
    setState(() => _printingEntryId = entry.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAutoPrint
                    ? 'Imprimindo comprovante na POS...'
                    : 'Enviando comprovante de ${entry.membro} para a POS...',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );

    try {
      await ThermalPrinterService.instance.printEnvelope(
        membro: entry.membro,
        destinacao: entry.destinacao,
        forma: entry.forma,
        valor: entry.valor,
        id: entry.id.length > 6 ? entry.id.substring(entry.id.length - 6) : entry.id,
        responsavel: ApiService.instance.currentUser?.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Comprovante de ${entry.membro} impresso na POS!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao imprimir na POS: $e'),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Tentar de novo',
            textColor: Colors.white,
            onPressed: () => _printReceipt(entry),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _printingEntryId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: Color(0xFF047857), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Lançar Envelope / Oferta',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
                    Text(
                      '#${(widget.entries.length + 1).toString().padLeft(3, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Destinação Chips
                const Text('Destinação', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('dizimo', 'Dízimo', Icons.bookmark_outline),
                      _buildChip('oferta', 'Oferta Geral', Icons.favorite_outline),
                      _buildChip('missoes', 'Missões', Icons.public_outlined),
                      _buildChip('construcao', 'Construção', Icons.business_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Meio de Pagamento
                const Text('Forma de Entrada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildPayBtn('dinheiro', 'Dinheiro', Icons.money)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPayBtn('pix', 'PIX', Icons.qr_code_2)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPayBtn('cartao', 'Cartão', Icons.credit_card)),
                  ],
                ),
                const SizedBox(height: 14),

                // Membro / Dizimista
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Membro / Dizimista (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    if (_selectedMember != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMember = null;
                            _memberController.clear();
                          });
                        },
                        child: const Text('Limpar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberController,
                        onChanged: _onMemberSearch,
                        decoration: InputDecoration(
                          hintText: 'Digite o nome ou n° do envelope...',
                          prefixIcon: const Icon(Icons.person_search_outlined, color: Color(0xFF047857)),
                          suffixIcon: _memberController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedMember = null;
                                      _memberController.clear();
                                      _filteredMembers = [];
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                      onPressed: _scanEnvelopeQr,
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: const Text('Bipar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ],
                ),
                if (_filteredMembers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: _filteredMembers
                          .map(
                            (m) => ListTile(
                              dense: true,
                              title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Text(
                                m.envelopeNumber != null ? 'Env #${m.envelopeNumber}' : '',
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                              onTap: () => _selectMember(m),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Valor Monetário
                const Text('Valor (R\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('R\$', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                    ),
                    hintText: '0,00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _submitEntry(),
                ),
                const SizedBox(height: 10),

                // Atalhos de Valores
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickValBtn(20),
                      _buildQuickValBtn(50),
                      _buildQuickValBtn(100),
                      _buildQuickValBtn(200),
                      _buildQuickValBtn(500),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _submitEntry,
                  icon: const Icon(Icons.check),
                  label: const Text('Registrar Entrada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lançamentos Desta Sessão',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Toque no registro ou no botão para imprimir',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Text(
              '${widget.entries.length} itens',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (widget.entries.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text('Nenhum envelope lançado nesta sessão.', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          ...widget.entries.map((e) => _buildEntryItem(e)),
      ],
    );
  }

  Widget _buildChip(String id, String label, IconData icon) {
    final selected = _destinacao == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF475569)),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        selectedColor: const Color(0xFF047857),
        backgroundColor: const Color(0xFFF1F5F9),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _destinacao = id),
      ),
    );
  }

  Widget _buildPayBtn(String id, String label, IconData icon) {
    final selected = _forma == id;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFECFDF5) : Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
          width: selected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => setState(() => _forma = id),
      icon: Icon(icon, size: 16, color: selected ? const Color(0xFF047857) : const Color(0xFF64748B)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF047857) : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildQuickValBtn(double val) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: const Color(0xFFF1F5F9),
        label: Text('+R\$ ${val.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        onPressed: () => _addQuickAmount(val),
      ),
    );
  }

  Widget _buildEntryItem(EnvelopeEntry e) {
    IconData icon = Icons.attach_money;
    if (e.forma == 'pix') icon = Icons.qr_code_2;
    if (e.forma == 'cartao') icon = Icons.credit_card;

    final isPrintingThis = _printingEntryId == e.id;

    return Card(
      elevation: isPrintingThis ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPrintingThis ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
          width: isPrintingThis ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _printReceipt(e),
        splashColor: const Color(0xFFECFDF5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPrintingThis ? const Color(0xFF047857) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPrintingThis ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: isPrintingThis
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: const Color(0xFF047857), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.membro,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.destinacao.toUpperCase()} • ${e.forma.toUpperCase()} • ${e.timestamp}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${e.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFECFDF5),
                          foregroundColor: const Color(0xFF047857),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFFA7F3D0)),
                          ),
                        ),
                        onPressed: isPrintingThis ? null : () => _printReceipt(e),
                        icon: isPrintingThis
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF047857),
                                ),
                              )
                            : const Icon(Icons.print_outlined, size: 14),
                        label: Text(
                          isPrintingThis ? 'Imprimindo' : 'Imprimir',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Remover',
                        onPressed: () => widget.onRemoveEntry(e.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
