// ============================================================
// ARQUIVO: lib/core/utils/format.dart
// FUNÇÃO: Formatação de tempo e datas em português, usada em todas
//         as telas. Mudar aqui muda o app inteiro.
// ============================================================

const weekdayNames = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

const weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

const monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// 5400 -> "1h 30min" · 2700 -> "45min" · 30 -> "0min"
String formatDuration(int seconds) {
  final totalMinutes = seconds ~/ 60;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '${m}min';
  if (m == 0) return '${h}h';
  return '${h}h ${m.toString().padLeft(2, '0')}min';
}

/// 3725 -> "01:02:05"
String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(h)}:${two(m)}:${two(s)}';
}

String two(int v) => v.toString().padLeft(2, '0');

/// "06/11/2026"
String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

/// "14:05"
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "06/11 14:05"
String formatShortDateTime(DateTime d) =>
    '${two(d.day)}/${two(d.month)} ${formatTime(d)}';

/// "Sexta-feira, 6 de novembro"
String formatLongDate(DateTime d) =>
    '${weekdayNames[d.weekday - 1]}, ${d.day} de ${monthNames[d.month - 1]}';

/// Texto relativo simples: "Hoje", "Ontem" ou a data.
String formatRelativeDay(DateTime d, DateTime now) {
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  return formatDate(d);
}

const priorityNames = ['Baixa', 'Média', 'Alta'];
const difficultyNames = ['Fácil', 'Intermediário', 'Difícil'];
