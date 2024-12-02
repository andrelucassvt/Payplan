import 'package:localization/localization.dart';

class AppStrings {
  static const nameApp = 'PayPlan';

  static var adicionarCartao = 'add-cartao'.i18n();
  static var adicionarDivida = 'add-divida'.i18n();
  static var desconto = 'desconto'.i18n();
  static var minhasDividas = 'minhas-dividas'.i18n();
  static var novoCartao = 'novo-cartao'.i18n();
  static var novaDivida = 'nova-divida'.i18n();
  static var adicioneUmCartao = 'add-novo-cartao'.i18n();
  static var nomeDaEmpresaDoCartao = 'nome-cartao'.i18n();
  static var nomeDaDivida = 'nome-divida'.i18n();
  static var salvar = 'salvar'.i18n();
  static var cancelar = 'cancelar'.i18n();
  static var digiteONomeCartao = 'digite-o-nome-carto'.i18n();
  static var digiteONomeDivida = 'digite-o-nome-divida'.i18n();
  static var digiteOValorDaFatura = 'digite-o-valor-fatura'.i18n();
  static var digiteOValorDoSaldo = 'digite-o-valor-do-saldo'.i18n();
  static var limparTudo = 'limpar-tudo'.i18n();
  static var corDoCartao = 'cor-do-cartao'.i18n();
  static var corDaDivida = 'cor-da-divida'.i18n();
  static var atencao = 'atencao'.i18n();
  static var deletar = 'deletar'.i18n();
  static var editar = 'editar'.i18n();
  static var editarCartao = 'editar-cartao'.i18n();
  static var editarDivida = 'editar-divida'.i18n();
  static var editarFatura = 'editar-fatura'.i18n();
  static var atualizarCartao = 'atualizar-cartao'.i18n();
  static var atualizarDivida = 'atualizar-divida'.i18n();
  static var addValor = 'add-valor-fatura'.i18n();
  static var total = 'total'.i18n();
  static var mensal = 'mensal'.i18n();
  static var unica = 'unica'.i18n();
  static var esseNovoCartao = 'esse-novo-cartao'.i18n();
  static var essaNovaDivida = 'essa-nova-divida'.i18n();
  static var esseCartaoSeraRemovido = 'esse-cartao-sera-removido'.i18n();
  static var addDividaExterna = 'add-divida-externa'.i18n();
  static var voceAindaNaoTemCartoesAdicionados =
      'voce-ainda-nao-tem-catoes-adicionados'.i18n();
  static var faturaDe = 'fatura-de'.i18n();
  static var paga = 'paga'.i18n();
  static var naoPaga = 'nao-paga'.i18n();
  static var dividaExterna = 'divida-externa'.i18n();
  static var saldoRestante = 'saldo-restante'.i18n();
  static var valorDesseMes = 'valor-desse-mes'.i18n();
  static var adicioneOValorTotalDescontado =
      'adicione-valor-total-descontado'.i18n();
  static var digiteOSaldoQueSeraDescontado =
      'digite-saldo-que-sera-descontado'.i18n();

  static var paraPermitirQueOPayplan = 'para-permitir-que-o-payplan'.i18n();
  static var paraPermitirQueOPayplanAdmob =
      'para-permitir-que-o-payplan-admob'.i18n();
  static var abrirConfiguracoes = 'abrir-configuracoes'.i18n();
  static var naoPercaADataPagamento = 'nao-perca-data-pagamento'.i18n();
  static var graficoGastos = 'grafico-gastos'.i18n();
  static var voltar = 'voltar'.i18n();
}

extension MonthsNames on String {
  String getMonthNumber() {
    switch (toUpperCase()) {
      case "JAN":
        return '1';
      case "FEV":
        return '2';
      case "MAR":
        return '3';
      case "ABR":
        return '4';
      case "MAI":
        return '5';
      case "JUN":
        return '6';
      case "JUL":
        return '7';
      case "AGO":
        return '8';
      case "SET":
        return '9';
      case "OUT":
        return '10';
      case "NOV":
        return '11';
      case "DEZ":
        return '12';
      default:
        return '1';
    }
  }
}
