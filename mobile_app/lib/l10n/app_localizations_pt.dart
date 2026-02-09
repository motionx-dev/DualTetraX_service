// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'DualTetraX';

  @override
  String get home => 'Início';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get settings => 'Configurações';

  @override
  String get guide => 'Guia';

  @override
  String get connectDevice => 'Conectar Dispositivo';

  @override
  String connectionFailed(String message) {
    return 'Falha na Conexão: $message';
  }

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get quickMenu => 'Menu Rápido';

  @override
  String get usageHistory => 'Histórico de Uso';

  @override
  String get usageGuide => 'Guia de Uso';

  @override
  String get connected => 'Conectado';

  @override
  String get connecting => 'Conectando...';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get connectedToDevice => 'Conectado ao DualTetraX';

  @override
  String get searchingDevice => 'Procurando dispositivo...';

  @override
  String get tapToConnect =>
      'Toque no botão conectar para conectar ao dispositivo';

  @override
  String get shotType => 'Tipo de Shot';

  @override
  String get mode => 'Modo';

  @override
  String get level => 'Nível';

  @override
  String get battery => 'Bateria';

  @override
  String get shakeDevice => 'Please shake the device';

  @override
  String get todayUsage => 'Uso de Hoje';

  @override
  String get totalUsageTime => 'Tempo Total de Uso';

  @override
  String get mostUsedMode => 'Modo Mais Usado';

  @override
  String get noUsageData => 'Sem dados de uso';

  @override
  String cannotLoadData(String message) {
    return 'Não foi possível carregar os dados: $message';
  }

  @override
  String get daily => 'Diário';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensal';

  @override
  String get dailyUsageTime => 'Tempo de Uso Diário';

  @override
  String get usageByType => 'Uso por Tipo de Shot';

  @override
  String get usageByUShotMode => 'U-Shot Mode Usage';

  @override
  String get usageByEShotMode => 'E-Shot Mode Usage';

  @override
  String get minutes => 'min';

  @override
  String get secondsShort => 'sec';

  @override
  String get details => 'Detalhes';

  @override
  String get weeklyUsageTime => 'Tempo de Uso Semanal';

  @override
  String get dailyUsage => 'Uso Diário';

  @override
  String get average => 'Média';

  @override
  String get minutesPerDay => 'min/dia';

  @override
  String get monthlyUsageTime => 'Tempo de Uso Mensal';

  @override
  String get usageTrend => 'Tendência de Uso';

  @override
  String get weeklyStatsComingSoon => 'Estatísticas semanais (Em breve)';

  @override
  String get monthlyStatsComingSoon => 'Estatísticas mensais (Em breve)';

  @override
  String error(String message) {
    return 'Erro: $message';
  }

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get darkMode => 'Modo Escuro';

  @override
  String get systemMode => 'Sistema';

  @override
  String get selectTheme => 'Selecionar Tema';

  @override
  String get device => 'Dispositivo';

  @override
  String get connectedDevice => 'Dispositivo Conectado';

  @override
  String get disconnectDevice => 'Desconectar Dispositivo';

  @override
  String get data => 'Dados';

  @override
  String get deleteAllData => 'Excluir Todos os Dados';

  @override
  String get information => 'Informações';

  @override
  String get appVersion => 'Versão do App';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get deleteDataTitle => 'Excluir Dados';

  @override
  String get deleteDataMessage =>
      'Todo o histórico de uso será excluído.\nEsta ação não pode ser desfeita.\nDeseja continuar?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get allDataDeleted => 'Todos os dados foram excluídos';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get shotTypeUnknown => 'Desconhecido';

  @override
  String get shotTypeUShot => 'U-Shot';

  @override
  String get shotTypeEShot => 'E-Shot';

  @override
  String get shotTypeLedCare => 'LED Care';

  @override
  String get modeUnknown => 'Desconhecido';

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
  String get levelUnknown => 'Desconhecido';

  @override
  String get level1 => 'Nível 1';

  @override
  String get level2 => 'Nível 2';

  @override
  String get level3 => 'Nível 3';

  @override
  String get guideStep1Title => 'Passo 1: Carregar e Ligar';

  @override
  String get guideStep1Item1 => 'Carregue o dispositivo usando um cabo USB-C';

  @override
  String get guideStep1Item2 =>
      'Pressione e segure o botão liga/desliga por 3 segundos para ligar';

  @override
  String get guideStep1Item3 => 'O dispositivo está ligado quando o LED acende';

  @override
  String get guideStep2Title => 'Passo 2: Alternar Tipo de Shot';

  @override
  String get guideStep2Item1 =>
      'Pressione o botão Shot para alternar entre U-Shot, E-Shot e LED Care';

  @override
  String get guideStep2Item2 =>
      'Você pode verificar o tipo de Shot atual pela cor do LED';

  @override
  String get guideStep3Title => 'Passo 3: Alterar Modo e Nível';

  @override
  String get guideStep3Item1 =>
      'Pressione o botão de modo para selecionar o modo desejado';

  @override
  String get guideStep3Item2 =>
      'Pressione o botão de nível para ajustar a intensidade (níveis 1-3)';

  @override
  String get guideStep4Title => 'Passo 4: Precauções Durante o Uso';

  @override
  String get guideStep4Item1 =>
      'Se ocorrer um aviso de temperatura, pare de usar e deixe o dispositivo esfriar';

  @override
  String get guideStep4Item2 =>
      'Se ocorrer um aviso de bateria fraca, é necessário carregar';

  @override
  String get guideStep4Item3 => 'O uso excessivo pode irritar a pele';

  @override
  String get guideStep5Title => 'Passo 5: Desligar e Guardar';

  @override
  String get guideStep5Item1 =>
      'Pressione e segure o botão liga/desliga por 3 segundos para desligar';

  @override
  String get guideStep5Item2 =>
      'Limpe o dispositivo com um pano limpo antes de guardar';

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
  String get otaMode => 'MODO ATUALIZAÇÃO OTA';

  @override
  String get otaInstructions =>
      'Conecte-se ao dispositivo via WiFi e acesse a interface web para atualizar o firmware.\n\nWiFi do dispositivo: DualTetraX-AP\nEndereço: http://192.168.4.1';

  @override
  String get sessionCompleted => 'Sessão Concluída';

  @override
  String get devicePoweredOff => 'O dispositivo foi desligado';

  @override
  String get autoReconnect => 'Reconexão Automática';

  @override
  String get autoReconnectInterval => 'Intervalo de Reconexão';

  @override
  String get seconds => 'segundos';

  @override
  String get connectionMode => 'Modo de Conexão';

  @override
  String get autoConnect => 'Automático';

  @override
  String get manualConnect => 'Manual';

  @override
  String get firmwareUpdate => 'Atualização de Firmware';

  @override
  String get firmwareUpdateSubtitle =>
      'Atualizar firmware do dispositivo via Bluetooth';

  @override
  String get otaServiceNotAvailable => 'Serviço OTA não disponível';

  @override
  String get otaUpdateCompleted => 'Atualização concluída';

  @override
  String get otaReadyForUpdate => 'Pronto para atualizar';

  @override
  String get deviceStatus => 'Status do Dispositivo';

  @override
  String get firmware => 'Firmware';

  @override
  String get noFirmwareSelected => 'Nenhum firmware selecionado';

  @override
  String get clear => 'Limpar';

  @override
  String get selectFirmwareFile => 'Selecionar Arquivo de Firmware';

  @override
  String get cancelUpdate => 'Cancelar Atualização';

  @override
  String get startUpdate => 'Iniciar Atualização';

  @override
  String get otaStateIdle => 'Ocioso';

  @override
  String get otaStateDownloading => 'Baixando...';

  @override
  String get otaStateValidating => 'Validando...';

  @override
  String get otaStateInstalling => 'Instalando...';

  @override
  String get otaStateComplete => 'Concluído';

  @override
  String get otaStateError => 'Erro';

  @override
  String get updateComplete => 'Atualização Concluída';

  @override
  String get updateCompleteMessage =>
      'Atualização de firmware bem-sucedida. O dispositivo reiniciará automaticamente.';

  @override
  String get ok => 'OK';

  @override
  String get file => 'Arquivo';

  @override
  String get version => 'Versão';

  @override
  String get size => 'Tamanho';

  @override
  String get deviceNotConnected => 'Dispositivo não conectado';

  @override
  String sendingChunk(int sent, int total) {
    return 'Enviando bloco $sent de $total';
  }

  @override
  String get syncedUsage => 'Sincronizado';

  @override
  String get unsyncedUsage => 'Tempo estimado';

  @override
  String get unsyncedTimeExplanation =>
      'Tempo estimado: Sessões gravadas enquanto o aplicativo estava desconectado. Os horários reais podem variar.';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'O email é obrigatório';

  @override
  String get invalidEmail => 'Por favor, insira um email válido';

  @override
  String get password => 'Senha';

  @override
  String get passwordRequired => 'A senha é obrigatória';

  @override
  String get passwordTooShort => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get passwordMismatch => 'As senhas não coincidem';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get login => 'Entrar';

  @override
  String get signup => 'Cadastrar';

  @override
  String get or => 'ou';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get noAccount => 'Não tem uma conta?';

  @override
  String get resetPassword => 'Redefinir Senha';

  @override
  String get resetPasswordSent => 'Email de redefinição de senha enviado';

  @override
  String get resetPasswordDescription =>
      'Insira seu endereço de email e enviaremos um link para redefinir sua senha.';

  @override
  String get profile => 'Perfil';

  @override
  String get name => 'Nome';

  @override
  String get gender => 'Gênero';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Feminino';

  @override
  String get other => 'Outro';

  @override
  String get save => 'Salvar';

  @override
  String get account => 'Conta';

  @override
  String get logout => 'Sair';

  @override
  String get cloudSync => 'Sincronização na Nuvem';

  @override
  String get syncToCloud => 'Sincronizar com a Nuvem';

  @override
  String get deviceNotRegistered => 'Dispositivo não registrado no servidor';

  @override
  String get skinProfile => 'Perfil de Pele';

  @override
  String get logoutConfirmTitle => 'Sair';

  @override
  String get logoutConfirmMessage => 'Tem certeza de que deseja sair?';
}
