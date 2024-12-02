enum MesesEnum {
  jan(nome: 'Janeiro', id: 1),
  fev(nome: 'Fevereiro', id: 2),
  mar(nome: 'Março', id: 3),
  abr(nome: 'Abril', id: 4),
  maio(nome: 'Maio', id: 5),
  jun(nome: 'Junho', id: 6),
  jul(nome: 'Julho', id: 7),
  ago(nome: 'Agosto', id: 8),
  set(nome: 'Setembro', id: 9),
  out(nome: 'Outubro', id: 10),
  nov(nome: 'Novembro', id: 11),
  dez(nome: 'Dezembro', id: 12);

  final String nome;
  final int id;

  const MesesEnum({required this.nome, required this.id});
}
