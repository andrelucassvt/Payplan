import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:notes_app/src/features/novo_cartao/presenter/cubit/novo_cartao_cubit.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/app_dialog.dart';
import 'package:uuid/uuid.dart';

class NovoCartaoView extends StatefulWidget {
  const NovoCartaoView({
    this.cartaoEntity,
    this.isDivida = false,
    super.key,
  });

  final CartaoEntity? cartaoEntity;
  final bool isDivida;

  @override
  State<NovoCartaoView> createState() => _NovoCartaoViewState();
}

class _NovoCartaoViewState extends State<NovoCartaoView> {
  final _cubit = GetIt.instance.get<NovoCartaoCubit>();
  final _focusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit.iniciar();
    if (widget.cartaoEntity != null) {
      _textController.text = widget.cartaoEntity!.nome;
      _cubit.mudarNomeEmpresa(widget.cartaoEntity!.nome);
      _cubit.mudarCorSelecionada(Color(widget.cartaoEntity!.cor));
    }
  }

  String _tituloDaAppBar() {
    if (widget.isDivida) {
      return AppStrings.novaDivida;
    }
    if (widget.cartaoEntity != null) {
      return AppStrings.atualizarCartao;
    }
    return AppStrings.novoCartao;
  }

  String _digiteONome() {
    if (widget.isDivida) {
      return AppStrings.digiteONomeDivida;
    }
    return AppStrings.digiteONomeEmpresa;
  }

  void acaoSalvar(NovoCartaoState state) {
    if (widget.isDivida) {
      AppDialog().showDialogApp(
        title: AppStrings.atencao,
        subTitle: AppStrings.essaNovaDivida,
        corButtonCancelOnTap: Colors.red,
        isDivida: true,
        textoButton2: AppStrings.mensal,
        textoButton1: AppStrings.unica,
        corTextoOnTap: Colors.blue,
        onTapButton1: () {
          final date = DateTime.now();
          // Unica
          if (widget.cartaoEntity != null) {
            _cubit.atualizarCartao(
              widget.cartaoEntity!.copyWith(
                cor: state.corSelecionada.first.value,
                nome: state.nomeEmpresa,
              ),
            );
          } else {
            _cubit.salvarCartao(
              cartaoEntity: CartaoEntity(
                id: const Uuid().v4().toLowerCase().replaceAll('-', ''),
                nome: state.nomeEmpresa,
                cor: state.corSelecionada.first.value,
                dividas: [],
                isDivida: true,
                isMensal: false,
                ano: date.year.toString(),
                mes: date.month.toString(),
              ),
            );
          }
          Navigator.of(context).pop();
        },
        onTapButton2: () {
          final date = DateTime.now();
          // mensal
          if (widget.cartaoEntity != null) {
            _cubit.atualizarCartao(
              widget.cartaoEntity!.copyWith(
                cor: state.corSelecionada.first.value,
                nome: state.nomeEmpresa,
              ),
            );
          } else {
            _cubit.salvarCartao(
              cartaoEntity: CartaoEntity(
                id: const Uuid().v4().toLowerCase().replaceAll('-', ''),
                nome: state.nomeEmpresa,
                cor: state.corSelecionada.first.value,
                dividas: [],
                isDivida: true,
                isMensal: true,
                ano: date.year.toString(),
                mes: date.month.toString(),
              ),
            );
          }
          Navigator.of(context).pop();
        },
      );
    } else {
      AppDialog().showDialogApp(
        title: AppStrings.atencao,
        subTitle: AppStrings.esseNovoCartao,
        corButtonCancelOnTap: Colors.red,
        onTapButton1: () {
          final date = DateTime.now();
          if (widget.cartaoEntity != null) {
            _cubit.atualizarCartao(
              widget.cartaoEntity!.copyWith(
                cor: state.corSelecionada.first.value,
                nome: state.nomeEmpresa,
              ),
            );
          } else {
            _cubit.salvarCartao(
              cartaoEntity: CartaoEntity(
                  id: const Uuid().v4().toLowerCase().replaceAll('-', ''),
                  nome: state.nomeEmpresa,
                  cor: state.corSelecionada.first.value,
                  dividas: [],
                  isDivida: false,
                  isMensal: true,
                  ano: date.year.toString(),
                  mes: date.month.toString()),
            );
          }
          Navigator.of(context).pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tituloDaAppBar(),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              _textController.clear();
              _cubit.iniciar();
            },
            child: const Text(AppStrings.limparTudo),
          )
        ],
      ),
      floatingActionButton: BlocBuilder<NovoCartaoCubit, NovoCartaoState>(
        bloc: _cubit,
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (_textController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isDivida
                          ? AppStrings.digiteONomeDivida
                          : AppStrings.digiteONomeEmpresa,
                    ),
                  ),
                );
              } else {
                acaoSalvar(state);
              }
            },
            label: const Text(AppStrings.salvar),
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: BlocConsumer<NovoCartaoCubit, NovoCartaoState>(
              bloc: _cubit,
              listener: (context, state) {
                if (state is NovoCartaoErro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.erroMessage.toString())));
                }
                if (state is NovoCartaoSucessoSalvo) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is NovoCartaoLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: state.corSelecionada.first,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 100,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                            ),
                            child: Text(
                              widget.isDivida
                                  ? AppStrings.nomeDaDivida
                                  : AppStrings.nomeDaEmpresaDoCartao,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                            ),
                            child: Text(
                              state.nomeEmpresa,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            onChanged: (value) {
                              _cubit.mudarNomeEmpresa(value);
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              hintText: _digiteONome(),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _focusNode.unfocus();
                          },
                          child: const Icon(Icons.check),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Text(
                      widget.isDivida
                          ? AppStrings.corDaDivida
                          : AppStrings.corDoCartao,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      runSpacing: 15,
                      spacing: 15,
                      children: state.cores.map((cor) {
                        return GestureDetector(
                          onTap: () {
                            _cubit.mudarCorSelecionada(cor);
                          },
                          child: CircleAvatar(
                            backgroundColor: cor,
                          ),
                        );
                      }).toList(),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
