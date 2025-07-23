import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/features/devedores/view/widgets/card_devedores_widget.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/helpers/devedores_helper.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_banner_widget.dart';
import 'package:notes_app/src/util/widgets/glass_container_widget.dart';

class DevedoresView extends StatefulWidget {
  const DevedoresView({
    required this.devedoresCubit,
    required this.scrollController,
    super.key,
  });
  final DevedoresCubit devedoresCubit;
  final ScrollController scrollController;

  @override
  State<DevedoresView> createState() => _DevedoresViewState();
}

class _DevedoresViewState extends State<DevedoresView> {
  final nomeTextController = TextEditingController();
  final pixTextController = TextEditingController();
  final faturaTextController = MoneyMaskedTextController();

  @override
  void initState() {
    super.initState();
    widget.devedoresCubit.buscarDevedores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppStrings.devedores,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: BlocBuilder<DevedoresCubit, DevedoresState>(
        bloc: widget.devedoresCubit,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    AppStrings.total,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    state.totalValorDevedor.real,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: () {
                      showNovoDevedorModal(
                        context: context,
                        cubit: widget.devedoresCubit,
                        nomeTextController: nomeTextController,
                        pixTextController: pixTextController,
                        faturaTextController: faturaTextController,
                      );
                    },
                    child: GlassContainerWidget(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Center(
                        child: Text(
                          AppStrings.novoDevedor,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Divider(),
                  const SizedBox(
                    height: 10,
                  ),
                  ...List.generate(
                    state.devedores.length,
                    (index) {
                      return ValueListenableBuilder(
                        valueListenable: UserController.user,
                        builder: (context, user, __) {
                          return Column(
                            children: [
                              CardDevedoresWidget(
                                index: index + 1,
                                devedoresEntity: state.devedores[index],
                                devedoresCubit: widget.devedoresCubit,
                                editarDevedor: () {
                                  showNovoDevedorModal(
                                    context: context,
                                    cubit: widget.devedoresCubit,
                                    nomeTextController: nomeTextController,
                                    pixTextController: pixTextController,
                                    faturaTextController: faturaTextController,
                                    devedoresEntity: state.devedores[index],
                                  );
                                },
                              ),
                              if (!user.isPlus) ...[
                                if (index == 0)
                                  AdmobBannerWidget(
                                    bannerId: Platform.isAndroid
                                        ? 'ca-app-pub-3652623512305285/2185608422'
                                        : 'ca-app-pub-3652623512305285/9922591661',
                                  ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(
                    height: 150,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
