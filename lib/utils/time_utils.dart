/// Utilidades para manejo de tiempo en zona horaria de Bolivia (UTC-4)
class TimeUtils {
  TimeUtils._();

  /// Obtiene la hora actual de Bolivia (UTC-4)
  /// Bolivia está en zona horaria UTC-4 (sin cambios de horario de verano)
  static DateTime getBoliviaTime() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: -4));
  }

  /// Convierte una fecha UTC a hora de Bolivia
  static DateTime toBoliviaTime(DateTime utcDateTime) {
    if (utcDateTime.isUtc) {
      return utcDateTime.add(const Duration(hours: -4));
    }
    // Si ya está en hora local, convertir a UTC primero
    return utcDateTime.toUtc().add(const Duration(hours: -4));
  }

  /// Convierte una hora de Bolivia a UTC
  static DateTime toUtcTime(DateTime boliviaDateTime) {
    return boliviaDateTime.add(const Duration(hours: 4)).toUtc();
  }

  /// Obtiene la hora actual como DateTime (para compatibilidad con código existente)
  static DateTime now() => getBoliviaTime();
}
