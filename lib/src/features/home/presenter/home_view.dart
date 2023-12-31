import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:get_it/get_it.dart';
import 'package:notes_app/src/features/home/presenter/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/presenter/widgets/bottom_bar_valor_total_widget.dart';
import 'package:notes_app/src/features/home/presenter/widgets/card_dividas_cartao_widget.dart';
import 'package:notes_app/src/util/coordinator/app_coordinator.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/app_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _cubit = GetIt.instance.get<HomeCubit>();
  final _appCoordinator = AppCoordinator();

  final _focusNodeEditarFatura = FocusNode();
  final _textControllerEditarFatura =
      MoneyMaskedTextController(initialValue: 0.00);

  final ScrollController _scrollController = ScrollController();

  bool mostrarIconePermitirNotificacao = false;

  @override
  void initState() {
    super.initState();
    _cubit.inicializar();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        NotificationService().showLocalNotification(
          title: AppStrings.atencao,
          body: AppStrings.naoPercaADataPagamento,
        );
      });
    });
    verificarPermissaoNotificacao();
  } //

  Future<void> verificarPermissaoNotificacao() async {
    final result = await NotificationService().verificarPermissaoNotificacao();
    setState(() {
      if (result) {
        mostrarIconePermitirNotificacao = true;
      } else {
        mostrarIconePermitirNotificacao = false;
      }
    });
  }

  void _goToElement(int index) {
    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        (100.0 * index),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          AppStrings.nameApp,
        ),
        actions: [
          const SizedBox(
            width: 10,
          ),
          if (mostrarIconePermitirNotificacao)
            IconButton(
              onPressed: () {
                AppDialog().showDialogApp(
                  barrierDismissible: false,
                  title: AppStrings.atencao,
                  subTitle: AppStrings.paraPermitirQueOPayplan,
                  onTapButton1: () async {
                    await verificarPermissaoNotificacao();
                    if (!mostrarIconePermitirNotificacao) {
                      Navigator.of(context).pop();
                    } else {
                      openAppSettings();
                    }
                  },
                  onTapButton2: () async {
                    Navigator.of(context).pop();
                  },
                  textoButton1: AppStrings.abrirConfiguracoes,
                );
              },
              icon: const Icon(
                Icons.notification_important,
                color: Colors.red,
              ),
            ),
          ElevatedButton(
            onPressed: () {
              _appCoordinator.navegarNovoCartaoView().then((value) {
                _cubit.inicializar();
              });
            },
            child: Text(AppStrings.adicionarCartao),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<HomeCubit, HomeState>(
                bloc: _cubit,
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state is HomeSucess) {
                    final meses = state.meses;
                    final indexMesSelecionado = meses.indexWhere(
                        (element) => element == state.mesSelecionado.first);
                    _goToElement(indexMesSelecionado);
                    return Column(
                      children: [
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: meses.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  _cubit.mudarMesSelecionado(meses[index]);
                                },
                                child: Container(
                                  key: GlobalObjectKey(meses[index]),
                                  width: 100,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: state.mesSelecionado
                                            .contains(meses[index])
                                        ? Colors.lightBlue.withOpacity(.5)
                                        : Colors.green.withOpacity(.5),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${meses[index]}/${state.anoAtual.substring(state.anoAtual.length - 2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (state.cartoes.isEmpty) ...[
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _appCoordinator
                                  .navegarNovoCartaoView(
                                isDivida: true,
                              )
                                  .then((value) {
                                _cubit.inicializar();
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: Text(AppStrings.addDividaExterna),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _appCoordinator
                                  .navegarNovoCartaoView(
                                isDivida: false,
                              )
                                  .then((value) {
                                _cubit.inicializar();
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: Text(AppStrings.adicionarCartao),
                          ),
                          const Spacer(),
                        ],
                        if (state.cartoes.isNotEmpty) ...[
                          TextButton.icon(
                            onPressed: () {
                              _appCoordinator
                                  .navegarNovoCartaoView(
                                isDivida: true,
                              )
                                  .then((value) {
                                _cubit.inicializar();
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: Text(AppStrings.addDividaExterna),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () => _cubit.inicializar(),
                              child: ListView.builder(
                                itemCount: state.cartoes.length,
                                itemBuilder: (context, index) {
                                  final cartao = state.cartoes[index];
                                  final valorFaturaCartao = cartao.dividas
                                      .where(
                                        (element) =>
                                            element.mes ==
                                            state.mesSelecionado.first,
                                      )
                                      .toList();
                                  if (cartao.isMensal == false &&
                                      cartao.mes !=
                                          state.mesSelecionado.first
                                              .getMonthNumber()) {
                                    return Container();
                                  } else {
                                    return Column(
                                      children: [
                                        CardDividasCartaoWidget(
                                          cartao: cartao,
                                          valorFaturaCartao: valorFaturaCartao,
                                          mesSelecionado:
                                              state.mesSelecionado.first,
                                          mudarInformacaoCartao:
                                              (cartaoEntity) {
                                            _cubit
                                                .atualizarCartao(cartaoEntity);
                                          },
                                          deletarCartao: () {
                                            _cubit.deleterCartao(
                                              cartao,
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          atualizarCartao: () {
                                            Future.delayed(
                                                const Duration(seconds: 0), () {
                                              _appCoordinator
                                                  .navegarNovoCartaoView(
                                                cartaoEntity: cartao,
                                                isDivida: cartao.isDivida,
                                              )
                                                  .then((value) {
                                                _cubit.inicializar();
                                              });
                                            });
                                          },
                                          showAdicionarAtualizarValorFatura:
                                              () {
                                            Future.delayed(
                                                const Duration(seconds: 0), () {
                                              showAdicionarAtualizarValorFatura(
                                                cartao: cartao,
                                                mesSelecionado:
                                                    state.mesSelecionado.first,
                                                anoAtual: state.anoAtual,
                                                faturaEntity: valorFaturaCartao,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          BottomBarValorTotalWidget(
                            valorFaturaCartao: state.valorTotalDaFatura,
                            cartoes: state.cartoes,
                            mesSelecionado: state.mesSelecionado.first,
                          ),
                        ]
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool containsOnlyDotsAndCommas(String input) {
    final regex = RegExp(r'^[.,]+$');
    return regex.hasMatch(input);
  }

  void showAdicionarAtualizarValorFatura({
    required CartaoEntity cartao,
    required String mesSelecionado,
    required String anoAtual,
    required List<FaturaEntity> faturaEntity,
  }) {
    if (faturaEntity.isNotEmpty) {
      _textControllerEditarFatura
          .updateValue(double.parse(faturaEntity.first.valorFatura));
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${AppStrings.faturaDe} ${cartao.nome}',
          ),
          content: TextFormField(
            controller: _textControllerEditarFatura,
            focusNode: _focusNodeEditarFatura,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  10.0,
                ),
              ),
              hintText: AppStrings.digiteOValorDaFatura,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                AppStrings.cancelar,
              ),
              onPressed: () {
                _textControllerEditarFatura.updateValue(0);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () {
                final result =
                    containsOnlyDotsAndCommas(_textControllerEditarFatura.text);
                if (_textControllerEditarFatura.text.isNotEmpty && !result) {
                  final novaDivida = FaturaEntity(
                    idCartao: cartao.id,
                    ano: anoAtual,
                    mes: mesSelecionado,
                    valorFatura:
                        _textControllerEditarFatura.numberValue.toString(),
                    isPago: false,
                  );

                  final dividasAtualizadas =
                      List<FaturaEntity>.from(cartao.dividas)
                        ..removeWhere((divida) => divida.mes == mesSelecionado)
                        ..add(novaDivida);

                  _cubit.atualizarCartao(
                    cartao.copyWith(dividas: dividasAtualizadas),
                  );
                  _focusNodeEditarFatura.unfocus();
                  _textControllerEditarFatura.updateValue(0);
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                AppStrings.salvar,
              ),
            ),
          ],
        );
      },
    );
  }
}
