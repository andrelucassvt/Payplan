import 'dart:io';

import 'package:as_design_system/navbar/as_navbar.dart';
import 'package:as_design_system/navbar/util/as_nav_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/features/devedores/view/devedores_view.dart';
import 'package:notes_app/src/features/grafico/view/grafico_view.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/view/home_view.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/helpers/devedores_helper.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/service/open_app_admob.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class HomeBase extends StatefulWidget {
  const HomeBase({super.key});

  @override
  State<HomeBase> createState() => _HomeBaseState();
}

class _HomeBaseState extends State<HomeBase> {
  final _homeCubit = HomeCubit();
  final _devedoresCubit = DevedoresCubit();

  int _selectedIndex = 0;

  final List<ScrollController> _scrollControllers =
      List.generate(3, (index) => ScrollController());

  final screenshotDividasController = ScreenshotController();
  final screenshotDevedoresController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _homeCubit.buscarDividas();
    _homeCubit.buscarIsPlus();
    _homeCubit.verificarVersao();
    _devedoresCubit.buscarDevedores();
    _verificarPermissaoNotificacao();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppOpenAdManager().loadAd();
    });
  }

  Future<void> _verificarPermissaoNotificacao() async {
    final result = await NotificationService().verificarPermissaoNotificacao();
    if (result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blue,
            content: InkWell(
              onTap: () {
                openAppSettings();
              },
              child: Center(
                child: Text(
                  AppStrings.permitirNotificacoes,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  final nomeTextController = TextEditingController();
  final pixTextController = TextEditingController();
  final faturaTextController = MoneyMaskedTextController();
  final mensagemTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          [
            HomeView(
              cubit: _homeCubit,
              scrollController: _scrollControllers[0],
            ),
            DevedoresView(
              devedoresCubit: _devedoresCubit,
              scrollController: _scrollControllers[1],
            ),
            BlocBuilder<DevedoresCubit, DevedoresState>(
              bloc: _devedoresCubit,
              builder: (context, stateDevedores) {
                return BlocBuilder<HomeCubit, HomeState>(
                  bloc: _homeCubit,
                  builder: (context, state) {
                    return GraficosView(
                      dividas: state.dividas,
                      devedores: stateDevedores.devedores,
                      homeCubit: _homeCubit,
                      screenshotDividasController: screenshotDividasController,
                      screenshotDevedoresController:
                          screenshotDevedoresController,
                    );
                  },
                );
              },
            ),
          ][_selectedIndex],
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: Platform.isIOS ? 0 : 10,
                ),
                child: AsNavbar(
                  key: Key(_selectedIndex.toString()),
                  scrollController: _scrollControllers[_selectedIndex],
                  colorItemSelected: Colors.red,
                  floatingIconRight: AsNavIcon(
                    icon: _selectedIndex == 2
                        ? Icon(Icons.share)
                        : Icon(Icons.add),
                    onTap: () async {
                      if (_selectedIndex == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NovaDividaView(
                              homeCubit: _homeCubit,
                            ),
                          ),
                        );
                        return;
                      }
                      if (_selectedIndex == 1) {
                        showNovoDevedorModal(
                          context: context,
                          cubit: _devedoresCubit,
                          nomeTextController: nomeTextController,
                          pixTextController: pixTextController,
                          faturaTextController: faturaTextController,
                          mensagemTextController: mensagemTextController,
                        );
                        return;
                      }

                      if (_selectedIndex == 2) {
                        try {
                          final image1 = _homeCubit.temDividas()
                              ? await screenshotDividasController.capture()
                              : null;
                          final image2 = _devedoresCubit.temDevedores()
                              ? await screenshotDevedoresController.capture()
                              : null;

                          final List<XFile> filesToShare = [];
                          final directory =
                              await getApplicationDocumentsDirectory();

                          if (image1 != null) {
                            final imagePath =
                                await File('${directory.path}/image.png')
                                    .create();
                            await imagePath.writeAsBytes(image1);
                            filesToShare.add(XFile(imagePath.path));
                          }
                          if (image2 != null) {
                            final imagePath2 =
                                await File('${directory.path}/image2.png')
                                    .create();
                            await imagePath2.writeAsBytes(image2);
                            filesToShare.add(XFile(imagePath2.path));
                          }
                          if (filesToShare.isNotEmpty) {
                            await Share.shareXFiles(
                              filesToShare,
                              text: AppStrings.baixePayplan,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Captura de tela falhou.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                  navIcons: [
                    AsNavIcon(
                      icon: Icon(Icons.home),
                      title: 'Home',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 0;
                        });
                      },
                    ),
                    AsNavIcon(
                      icon: Icon(Icons.people),
                      title: AppStrings.devedores,
                      onTap: () {
                        _devedoresCubit.buscarDevedores();
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    ),
                    AsNavIcon(
                      icon: Icon(Icons.bar_chart),
                      title: AppStrings.graficos,
                      onTap: () {
                        _devedoresCubit.buscarDevedores();
                        _homeCubit.buscarDividas();
                        setState(() {
                          _selectedIndex = 2;
                        });
                      },
                    ),
                  ],
                  indexSelected: _selectedIndex,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
