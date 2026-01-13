// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => 'Inicio';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get settings => 'Configuración';

  @override
  String get guide => 'Guía';

  @override
  String get connectDevice => 'Conectar Dispositivo';

  @override
  String connectionFailed(String message) {
    return 'Error de Conexión: $message';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get quickMenu => 'Menú Rápido';

  @override
  String get usageHistory => 'Historial de Uso';

  @override
  String get usageGuide => 'Guía de Uso';

  @override
  String get connected => 'Conectado';

  @override
  String get connecting => 'Conectando...';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get connectedToDevice => 'Conectado a DualTetraX';

  @override
  String get searchingDevice => 'Buscando dispositivo...';

  @override
  String get tapToConnect =>
      'Toca el botón conectar para conectar al dispositivo';

  @override
  String get shotType => 'Tipo de Shot';

  @override
  String get mode => 'Modo';

  @override
  String get level => 'Nivel';

  @override
  String get battery => 'Batería';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => 'Uso de Hoy';

  @override
  String get totalUsageTime => 'Tiempo Total de Uso';

  @override
  String get mostUsedMode => 'Modo Más Usado';

  @override
  String get noUsageData => 'Sin datos de uso';

  @override
  String cannotLoadData(String message) {
    return 'No se pueden cargar los datos: $message';
  }

  @override
  String get daily => 'Diario';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get dailyUsageTime => 'Tiempo de Uso Diario';

  @override
  String get usageByType => 'Uso por Tipo de Shot';

  @override
  String get minutes => 'min';

  @override
  String get weeklyStatsComingSoon => 'Estadísticas semanales (Próximamente)';

  @override
  String get monthlyStatsComingSoon => 'Estadísticas mensuales (Próximamente)';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get selectTheme => 'Seleccionar Tema';

  @override
  String get device => 'Dispositivo';

  @override
  String get connectedDevice => 'Dispositivo Conectado';

  @override
  String get disconnectDevice => 'Desconectar Dispositivo';

  @override
  String get data => 'Datos';

  @override
  String get deleteAllData => 'Eliminar Todos los Datos';

  @override
  String get information => 'Información';

  @override
  String get appVersion => 'Versión de la App';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get deleteDataTitle => 'Eliminar Datos';

  @override
  String get deleteDataMessage =>
      'Se eliminará todo el historial de uso.\\nEsta acción no se puede deshacer.\\n¿Desea continuar?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get allDataDeleted => 'Todos los datos han sido eliminados';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get shotTypeUnknown => 'Desconocido';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => 'Desconocido';

  @override
  String get modeGlow => 'Glow';

  @override
  String get modeTuning => 'Tuning';

  @override
  String get modeRenewal => 'Renewal';

  @override
  String get modeVolume => 'Volume';

  @override
  String get modeCleansing => 'Cleansing';

  @override
  String get modeFirming => 'Firming';

  @override
  String get modeLifting => 'Lifting';

  @override
  String get modeLF => 'LF';

  @override
  String get modeLED => 'Modo LED';

  @override
  String get levelUnknown => 'Desconocido';

  @override
  String get level1 => 'Nivel 1';

  @override
  String get level2 => 'Nivel 2';

  @override
  String get level3 => 'Nivel 3';

  @override
  String get guideStep1Title => 'Paso 1: Cargar y Encender';

  @override
  String get guideStep1Item1 => 'Cargue el dispositivo usando un cable USB-C';

  @override
  String get guideStep1Item2 =>
      'Mantenga presionado el botón de encendido durante 3 segundos para encender';

  @override
  String get guideStep1Item3 =>
      'El dispositivo está encendido cuando el LED se ilumina';

  @override
  String get guideStep2Title => 'Paso 2: Cambiar Tipo de Shot';

  @override
  String get guideStep2Item1 =>
      'Presione el botón Shot para cambiar entre U-Shot, E-Shot y LED Care';

  @override
  String get guideStep2Item2 =>
      'Puede verificar el tipo de Shot actual por el color del LED';

  @override
  String get guideStep3Title => 'Paso 3: Cambiar Modo y Nivel';

  @override
  String get guideStep3Item1 =>
      'Presione el botón de modo para seleccionar el modo deseado';

  @override
  String get guideStep3Item2 =>
      'Presione el botón de nivel para ajustar la intensidad (niveles 1-3)';

  @override
  String get guideStep4Title => 'Paso 4: Precauciones Durante el Uso';

  @override
  String get guideStep4Item1 =>
      'Si aparece una advertencia de temperatura, deje de usar y enfríe el dispositivo';

  @override
  String get guideStep4Item2 =>
      'Si aparece una advertencia de batería baja, es necesario cargar';

  @override
  String get guideStep4Item3 => 'El uso excesivo puede irritar la piel';

  @override
  String get guideStep5Title => 'Paso 5: Apagar y Guardar';

  @override
  String get guideStep5Item1 =>
      'Mantenga presionado el botón de encendido durante 3 segundos para apagar';

  @override
  String get guideStep5Item2 =>
      'Limpie el dispositivo con un paño limpio antes de guardarlo';

  @override
  String get korean => '한국어';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get japanese => '日本語';

  @override
  String get portuguese => 'Português';

  @override
  String get spanish => 'Español';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get thai => 'ไทย';

  @override
  String get otaMode => 'MODO ACTUALIZACIÓN OTA';

  @override
  String get otaInstructions =>
      'Conéctese al dispositivo a través de WiFi y acceda a la interfaz web para actualizar el firmware.\n\nWiFi del dispositivo: DualTetraX-AP\nDirección: http://192.168.4.1';

  @override
  String get sessionCompleted => 'Sesión Completada';

  @override
  String get devicePoweredOff => 'El dispositivo se ha apagado';

  @override
  String get autoReconnect => 'Reconexión Automática';

  @override
  String get autoReconnectInterval => 'Intervalo de Reconexión';

  @override
  String get seconds => 'segundos';

  @override
  String get connectionMode => 'Modo de Conexión';

  @override
  String get autoConnect => 'Automático';

  @override
  String get manualConnect => 'Manual';

  @override
  String get firmwareUpdate => 'Actualización de Firmware';

  @override
  String get firmwareUpdateSubtitle => 'Actualizar firmware del dispositivo vía Bluetooth';

  @override
  String get otaServiceNotAvailable => 'Servicio OTA no disponible';

  @override
  String get otaUpdateCompleted => 'Actualización completada';

  @override
  String get otaReadyForUpdate => 'Listo para actualizar';

  @override
  String get deviceStatus => 'Estado del Dispositivo';

  @override
  String get firmware => 'Firmware';

  @override
  String get noFirmwareSelected => 'No se ha seleccionado firmware';

  @override
  String get clear => 'Limpiar';

  @override
  String get selectFirmwareFile => 'Seleccionar Archivo de Firmware';

  @override
  String get cancelUpdate => 'Cancelar Actualización';

  @override
  String get startUpdate => 'Iniciar Actualización';

  @override
  String get otaStateIdle => 'Inactivo';

  @override
  String get otaStateDownloading => 'Descargando...';

  @override
  String get otaStateValidating => 'Validando...';

  @override
  String get otaStateInstalling => 'Instalando...';

  @override
  String get otaStateComplete => 'Completado';

  @override
  String get otaStateError => 'Error';

  @override
  String get updateComplete => 'Actualización Completada';

  @override
  String get updateCompleteMessage =>
      'Actualización de firmware exitosa. El dispositivo se reiniciará automáticamente.';

  @override
  String get ok => 'Aceptar';

  @override
  String get file => 'Archivo';

  @override
  String get version => 'Versión';

  @override
  String get size => 'Tamaño';

  @override
  String sendingChunk(int sent, int total) {
    return 'Enviando bloque $sent de $total';
  }
}
