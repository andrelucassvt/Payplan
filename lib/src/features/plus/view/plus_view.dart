import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/features/plus/content/plus_premium_content.dart';
import 'package:notes_app/src/features/plus/content/plus_shop_content.dart';
import 'package:notes_app/src/features/plus/cubit/plus_cubit.dart';
import 'package:notes_app/src/util/service/in_app_purchase/in_app_purchase_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class PlusView extends StatefulWidget {
  const PlusView({super.key});

  @override
  State<PlusView> createState() => _PlusViewState();
}

class _PlusViewState extends State<PlusView> {
  late final _cubit = PlusCubit(InAppPurchaseService());

  @override
  void initState() {
    super.initState();
    _cubit.loadProducts();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlusCubit, PlusState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is PlusPurchaseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is PlusPremium && state.isRestored) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.comprasRestauradas)),
          );
        } else if (state is PlusPremium && !state.isRestored) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.compraRealizada)),
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                AppStrings.semAnuncio,
              ),
              backgroundColor: const Color(0xFF5C5FEF),
              foregroundColor: Colors.white,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_downward),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: switch (state) {
              PlusInitial() || PlusLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              PlusStoreUnavailable() => Center(
                  child: Text(
                    AppStrings.lojaIndisponivel,
                    textAlign: TextAlign.center,
                  ),
                ),
              PlusPremium() => const PlusPremiumContent(),
              PlusProductsLoaded(:final products, :final isProcessing) =>
                PlusShopContent(
                  products: products,
                  isProcessing: isProcessing,
                  onBuy: () => _cubit.buyProduct(products.first),
                  onRestore: _cubit.restorePurchases,
                ),
              PlusPurchaseError(:final products) => products.isNotEmpty
                  ? PlusShopContent(
                      products: products,
                      isProcessing: false,
                      onBuy: () => _cubit.buyProduct(products.first),
                      onRestore: _cubit.restorePurchases,
                    )
                  : Center(
                      child: Text(
                        AppStrings.lojaIndisponivel,
                        textAlign: TextAlign.center,
                      ),
                    ),
            },
          ),
        );
      },
    );
  }
}
