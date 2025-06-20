import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/features/devedores/view/devedores_view.dart';
import 'package:notes_app/src/features/grafico/view/grafico_view.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/home/view/home_view.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/service/open_app_admob.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/glass_container_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeBase extends StatefulWidget {
  const HomeBase({super.key});

  @override
  State<HomeBase> createState() => _HomeBaseState();
}

class _HomeBaseState extends State<HomeBase> {
  final _homeCubit = HomeCubit();
  final _devedoresCubit = DevedoresCubit();

  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Views
          [
            HomeView(cubit: _homeCubit),
            DevedoresView(),
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
                    );
                  },
                );
              },
            ),
          ][_selectedIndex],

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GlassContainerWidget(
                sigmaX: 5,
                sigmaY: 5,
                alpha: .13,
                padding: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                child: Row(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Home
                    _iconBottomNav(
                      index: 0,
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: _selectedIndex == 0,
                    ),
                    _iconBottomNav(
                      index: 1,
                      icon: Icons.people,
                      label: AppStrings.devedores,
                      isSelected: _selectedIndex == 1,
                    ),
                    _iconBottomNav(
                      index: 2,
                      icon: Icons.bar_chart,
                      label: AppStrings.graficos,
                      isSelected: _selectedIndex == 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBottomNav({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        if (index == 2) {
          _devedoresCubit.buscarDevedores();
          _homeCubit.buscarDividas();
        }
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isSelected
              ? Colors.white.withValues(alpha: .4)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
