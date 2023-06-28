class AppStrings {
  static const nameApp = 'PayPlan';
  static const adicionarCartao = 'Adicionar cartão';
  static const novoCartao = 'Novo cartão';
  static const novaDivida = 'Nova dívida';
  static const adicioneUmCartao = 'Você não tem cartão cadastrados';
  static const nomeDaEmpresaDoCartao = 'Nome do cartão:';
  static const nomeDaDivida = 'Nome da dívida:';
  static const salvar = 'Salvar';
  static const cancelar = 'Cancelar';
  static const digiteONomeEmpresa = 'Digite o nome do cartão...';
  static const digiteONomeDivida = 'Digite o nome da dívida...';
  static const digiteOValorDaFatura = 'Digite o valor da fatura';
  static const digiteOValorDoSaldo = 'Digite o valor do saldo';
  static const limparTudo = 'Limpar tudo';
  static const corDoCartao = 'Cor do cartão';
  static const corDaDivida = 'Cor da dívida';
  static const atencao = 'Atenção';
  static const deletar = 'Deletar';
  static const editar = 'Editar';
  static const editarCartao = 'Editar cartão';
  static const editarDivida = 'Editar dívida';
  static const editarFatura = 'Editar fatura';
  static const atualizarCartao = 'Atualizar cartão';
  static const atualizarDivida = 'Atualizar dívida';
  static const addValor = 'R\$ Adicionar valor da fatura';
  static const total = 'Total:';
  static const mensal = 'Mensal';
  static const unica = 'Única';
  static const esseNovoCartao =
      'O cartão será salvo para todos os meses subsequentes';
  static const essaNovaDivida =
      'O clique na opção que atenda seu tipo de dívida para salvar';
  static const esseCartaoSeraRemovido =
      'O cartão será deletado de todos os meses subsequentes';
  static const addDividaExterna = 'Adicionar divida externa';
  static const voceAindaNaoTemCartoesAdicionados =
      'Você ainda não tem cartões ou dividas adicionados!!\nClique aqui e adicione';
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
