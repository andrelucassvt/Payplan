import 'dart:io';

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
import 'package:notes_app/src/util/service/ads/app_open_ad_service.dart';
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
      AppOpenAdService.instance.load();
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
      backgroundColor: const Color(0xFFF8F9FF),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
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
        ],
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFFEEEEFF),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) async {
          if (index == 1) _devedoresCubit.buscarDevedores();
          if (index == 2) {
            _devedoresCubit.buscarDevedores();
            _homeCubit.buscarDividas();
          }
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: AppStrings.devedores,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: AppStrings.graficos,
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    if (_selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () => _shareScreenshots(context),
        backgroundColor: const Color(0xFF5C5FEF),
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.share),
      );
    }
    return FloatingActionButton(
      onPressed: () {
        if (_selectedIndex == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NovaDividaView(homeCubit: _homeCubit),
            ),
          );
        } else {
          showNovoDevedorModal(
            context: context,
            cubit: _devedoresCubit,
            nomeTextController: nomeTextController,
            pixTextController: pixTextController,
            faturaTextController: faturaTextController,
            mensagemTextController: mensagemTextController,
          );
        }
      },
      backgroundColor: const Color(0xFF5C5FEF),
      foregroundColor: Colors.white,
      elevation: 2,
      child: const Icon(Icons.add),
    );
  }

  Future<void> _shareScreenshots(BuildContext context) async {
    try {
      final image1 = _homeCubit.temDividas()
          ? await screenshotDividasController.capture()
          : null;
      final image2 = _devedoresCubit.temDevedores()
          ? await screenshotDevedoresController.capture()
          : null;

      final List<XFile> filesToShare = [];
      final directory = await getApplicationDocumentsDirectory();

      if (image1 != null) {
        final imagePath = await File('${directory.path}/image.png').create();
        await imagePath.writeAsBytes(image1);
        filesToShare.add(XFile(imagePath.path));
      }
      if (image2 != null) {
        final imagePath2 = await File('${directory.path}/image2.png').create();
        await imagePath2.writeAsBytes(image2);
        filesToShare.add(XFile(imagePath2.path));
      }
      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(filesToShare, text: AppStrings.baixePayplan);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Captura de tela falhou.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
