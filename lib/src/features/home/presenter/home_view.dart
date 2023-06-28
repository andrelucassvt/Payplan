import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/features/home/presenter/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/presenter/widgets/bottom_bar_valor_total_widget.dart';
import 'package:notes_app/src/features/home/presenter/widgets/card_dividas_cartao_widget.dart';
import 'package:notes_app/src/util/coordinator/app_coordinator.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _cubit = GetIt.instance.get<HomeCubit>();
  final _appCoordinator = AppCoordinator();

  final _focusNodeEditarFatura = FocusNode();
  final TextEditingController _textControllerEditarFatura =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  //Admob
  late BannerAd _bannerAd;
  bool _isLoaded = false;
  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3652623512305285/5889977427'
      : 'ca-app-pub-3652623512305285/9198667043';

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          setState(() {
            _isLoaded = false;
          });
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _cubit.inicializar();
    loadAd();
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
          ElevatedButton(
            onPressed: () {
              _appCoordinator.navegarNovoCartaoView().then((value) {
                _cubit.inicializar();
              });
            },
            child: const Text(AppStrings.adicionarCartao),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoaded)
              Padding(
                padding: const EdgeInsets.only(
                  top: 5,
                  bottom: 5,
                ),
                child: SizedBox(
                  height: 50, // Altura do banner do AdMob
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
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
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                _appCoordinator
                                    .navegarNovoCartaoView()
                                    .then((value) {
                                  _cubit.inicializar();
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Text(
                                  AppStrings.voceAindaNaoTemCartoesAdicionados,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
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
                            label: const Text(AppStrings.addDividaExterna),
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
                                    return CardDividasCartaoWidget(
                                      cartao: cartao,
                                      valorFaturaCartao: valorFaturaCartao,
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
                                      showAdicionarAtualizarValorFatura: () {
                                        Future.delayed(
                                            const Duration(seconds: 0), () {
                                          showAdicionarAtualizarValorFatura(
                                            cartao: cartao,
                                            mesSelecionado:
                                                state.mesSelecionado.first,
                                            anoAtual: state.anoAtual,
                                          );
                                        });
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          BottomBarValorTotalWidget(
                            valorFaturaCartao: state.valorTotalDaFatura,
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
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Fatura de: ${cartao.nome}',
          ),
          content: TextFormField(
            controller: _textControllerEditarFatura,
            focusNode: _focusNodeEditarFatura,
            onChanged: (value) {
              setState(() {
                _textControllerEditarFatura.text = value;
                _textControllerEditarFatura.selection =
                    TextSelection.fromPosition(
                  TextPosition(offset: _textControllerEditarFatura.text.length),
                );
              });
            },
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter(allowFraction: true)],
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
              child: const Text(
                AppStrings.cancelar,
              ),
              onPressed: () {
                _textControllerEditarFatura.clear();
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
                    valorFatura: _textControllerEditarFatura.text
                        .replaceAll(',', ''.replaceAll('.', '')),
                  );

                  final dividasAtualizadas =
                      List<FaturaEntity>.from(cartao.dividas)
                        ..removeWhere((divida) => divida.mes == mesSelecionado)
                        ..add(novaDivida);

                  _cubit.atualizarCartao(
                    cartao.copyWith(dividas: dividasAtualizadas),
                  );
                  _focusNodeEditarFatura.unfocus();
                  _textControllerEditarFatura.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                AppStrings.salvar,
              ),
            ),
          ],
        );
      },
    );
  }
}
