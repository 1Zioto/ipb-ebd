import 'package:flutter/material.dart';
import '../models/models.dart';

class CedulasTab extends StatelessWidget {
  final Map<double, int> cashCounts;
  final Function(double, int) onUpdateCount;
  final VoidCallback onReset;

  const CedulasTab({
    super.key,
    required this.cashCounts,
    required this.onUpdateCount,
    required this.onReset,
  });

  double get totalFisico {
    double total = 0.0;
    cashCounts.forEach((val, qty) {
      total += val * qty;
    });
    return total;
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
                        Icon(Icons.calculate_outlined, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Text(
                          'Contagem de Dinheiro Físico',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      'R\$ ${totalFisico.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Contador tátil de notas e moedas. Toque em +, +5, +10 para registrar o dinheiro vivo da salva.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                ...denominationsList.map((d) {
                  final qty = cashCounts[d.value] ?? 0;
                  final subtotal = qty * d.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Badge da Nota
                        Container(
                          width: 68,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: d.isCedula ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: d.isCedula ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            d.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: d.isCedula ? const Color(0xFF047857) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Subtotal
                        Expanded(
                          child: Text(
                            'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        // Controles (- / Qtd / + / +5 / +10)
                        _buildStepBtn('-', () => onUpdateCount(d.value, (qty - 1).clamp(0, 9999))),
                        Container(
                          width: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '$qty',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                        _buildStepBtn('+', () => onUpdateCount(d.value, qty + 1)),
                        const SizedBox(width: 4),
                        _buildQuickStepBtn('+5', () => onUpdateCount(d.value, qty + 5)),
                        const SizedBox(width: 4),
                        _buildQuickStepBtn('+10', () => onUpdateCount(d.value, qty + 10)),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Zerar contagem física'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: 28,
      height: 28,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }

  Widget _buildQuickStepBtn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 28,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: const Color(0xFF334155),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
      ),
    );
  }
}
