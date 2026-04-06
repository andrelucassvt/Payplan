part of 'plus_cubit.dart';

@immutable
sealed class PlusState {
  const PlusState();
}

final class PlusInitial extends PlusState {
  const PlusInitial();
}

final class PlusLoading extends PlusState {
  const PlusLoading();
}

final class PlusProductsLoaded extends PlusState {
  const PlusProductsLoaded({
    required this.products,
    this.isProcessing = false,
  });

  final List<ProductDetails> products;
  final bool isProcessing;
}

final class PlusPremium extends PlusState {
  const PlusPremium({this.isRestored = false});

  final bool isRestored;
}

final class PlusStoreUnavailable extends PlusState {
  const PlusStoreUnavailable();
}

final class PlusPurchaseError extends PlusState {
  const PlusPurchaseError({required this.message, required this.products});

  final String message;
  final List<ProductDetails> products;
}
