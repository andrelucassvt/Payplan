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
        bottomNavigationBar: Container(
          color: Colors.black,
          child: SafeArea(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: .7),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: _selectedIndex == 0
                          ? Colors.deepPurpleAccent
                          : Colors.transparent,
                      child: Icon(
                        Icons.home,
                        color: _selectedIndex == 0 ? Colors.white : Colors.grey,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                  ),
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: _selectedIndex == 2
                          ? Colors.deepPurpleAccent
                          : Colors.transparent,
                      child: Icon(
                        Icons.people,
                        color: _selectedIndex == 2 ? Colors.white : Colors.grey,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: _selectedIndex == 1
                          ? Colors.deepPurpleAccent
                          : Colors.transparent,
                      child: Icon(
                        Icons.donut_large,
                        color: _selectedIndex == 1 ? Colors.white : Colors.grey,
                      ),
                    ),
                    onPressed: () {
                      _devedoresCubit.buscarDevedores();
                      _homeCubit.buscarDividas();
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: [
          HomeView(cubit: _homeCubit),
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
          DevedoresView(),
        ][_selectedIndex]);
  }
}
