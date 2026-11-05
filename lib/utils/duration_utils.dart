/// ============================================================
/// ARQUIVO: lib/utils/duration_utils.dart
/// FUNÇÃO: Converte minutos em texto legível ("1h30", "45min") e
///         vice-versa. Usado em toda tela que mostra ou recebe
///         tempo de estudo.
///
/// POSSO ALTERAR:
///   - O formato do texto (ex: mudar "1h30" para "1:30").
///
/// NÃO DEVO ALTERAR SEM ENTENDER:
///   - A lógica interna de cálculo (divisão por 60), pois muitos
///     lugares do app dependem do resultado estar correto.
///
/// DEPENDÊNCIAS:
///   - widgets/subject_card.dart, screens/study, screens/home
/// ============================================================
class DurationUtils {
  DurationUtils._();

  /// Transforma minutos em um texto como "1h30" ou "45min".
  static String formatMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  /// Tenta interpretar um texto digitado pelo usuário (tempo
  /// personalizado) e devolver o total em minutos.
  /// Aceita formatos como: "30", "30min", "1h", "1h30", "1 hora",
  /// "2 horas", "90 minutos".
  static int? parseToMinutes(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return null;

    // Formato "1h30" ou "1h"
    final hourMinuteMatch = RegExp(r'^(\d+)h(\d{0,2})$').firstMatch(text);
    if (hourMinuteMatch != null) {
      final h = int.parse(hourMinuteMatch.group(1)!);
      final m = hourMinuteMatch.group(2)!.isEmpty
          ? 0
          : int.parse(hourMinuteMatch.group(2)!);
      return h * 60 + m;
    }

    // Formato "1 hora" / "2 horas"
    final hourWordMatch =
        RegExp(r'^(\d+)\s*horas?$').firstMatch(text);
    if (hourWordMatch != null) {
      return int.parse(hourWordMatch.group(1)!) * 60;
    }

    // Formato "30min" / "30 minutos" / "30"
    final minuteMatch = RegExp(r'^(\d+)\s*(min(utos?)?)?$').firstMatch(text);
    if (minuteMatch != null) {
      return int.parse(minuteMatch.group(1)!);
    }

    return null; // não foi possível interpretar
  }
}
