import 'package:flutter/material.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool mostrarIconePermitirNotificacao = false;

  @override
  void initState() {
    super.initState();

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
                  contextCustom: context,
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
            onPressed: () {},
            child: Text(AppStrings.adicionarCartao),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
      body: const SafeArea(
        child: Column(
          children: [],
        ),
      ),
    );
  }
}
