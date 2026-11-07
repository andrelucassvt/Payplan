import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'paywall_cubit.dart';
import 'purchase_service.dart';

/// Preencha com context.l10n no app. Os preços vêm da loja, não destes textos.
class PaywallCopy {
  const PaywallCopy({
    required this.title,
    required this.benefit,
    required this.subscribe,
    required this.restore,
    required this.retry,
    required this.loadFailed,
    required this.month,
    required this.year,
    required this.autoRenew,
    required this.terms,
    required this.privacy,
    required this.success,
    required this.pending,
    required this.purchaseFailed,
    required this.restoreFailed,
    required this.verificationInvalid,
    required this.verificationUnavailable,
    required this.nothingToRestore,
    required this.storeTimeout,
    required this.linkFailed,
  });

  final String title;
  final String benefit;
  final String subscribe;
  final String restore;
  final String retry;
  final String loadFailed;
  final String month;
  final String year;
  final String autoRenew;
  final String terms;
  final String privacy;
  final String success;
  final String pending;
  final String purchaseFailed;
  final String restoreFailed;
  final String verificationInvalid;
  final String verificationUnavailable;
  final String nothingToRestore;
  final String storeTimeout;
  final String linkFailed;

  String period(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.monthly => month,
    SubscriptionPeriod.yearly => year,
  };

  String? message(PurchaseNotice notice) => switch (notice) {
    PurchaseNotice.granted => success,
    PurchaseNotice.pending => pending,
    PurchaseNotice.canceled => null,
    PurchaseNotice.purchaseFailed => purchaseFailed,
    PurchaseNotice.restoreFailed => restoreFailed,
    PurchaseNotice.verificationInvalid => verificationInvalid,
    PurchaseNotice.verificationUnavailable => verificationUnavailable,
    PurchaseNotice.nothingToRestore => nothingToRestore,
    PurchaseNotice.storeTimeout => storeTimeout,
  };
}

class PaywallView extends StatefulWidget {
  const PaywallView({
    required this.service,
    required this.copy,
    required this.termsUrl,
    required this.privacyUrl,
    this.onGranted,
    super.key,
  });

  final PurchaseService service;
  final PaywallCopy copy;
  final Uri termsUrl;
  final Uri privacyUrl;
  final ValueChanged<String>? onGranted;

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  late final PaywallCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PaywallCubit(widget.service);
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final periodOf = widget.service.periodOf;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(copy.title)),
        body: SafeArea(
          child: BlocConsumer<PaywallCubit, PaywallState>(
            listener: (context, state) {
              final granted = state.grantedProductId;
              if (granted != null) {
                if (widget.onGranted != null) {
                  widget.onGranted!(granted);
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                } else {
                  _showMessage(copy.success);
                }
                return;
              }
              final notice = state.notice;
              if (notice != null) {
                final message = copy.message(notice);
                if (message != null) _showMessage(message);
              }
            },
            builder: (context, state) {
              if (state.loading && state.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.loadFailed && state.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(copy.loadFailed),
                      TextButton(
                        onPressed: _cubit.load,
                        child: Text(copy.retry),
                      ),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  AbsorbPointer(
                    absorbing: state.busy,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          copy.benefit,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        for (final product in state.products)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(product.description),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${product.price} / '
                                    '${copy.period(periodOf(product.id))}',
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: () => _cubit.buy(product),
                                    child: Text(copy.subscribe),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _cubit.restore,
                          child: Text(copy.restore),
                        ),
                        const SizedBox(height: 12),
                        Text(copy.autoRenew),
                        Wrap(
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: () => _openLink(widget.termsUrl),
                              child: Text(copy.terms),
                            ),
                            TextButton(
                              onPressed: () => _openLink(widget.privacyUrl),
                              child: Text(copy.privacy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (state.busy)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(Uri url) async {
    try {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _showMessage(widget.copy.linkFailed);
    } on Object catch (_) {
      if (mounted) _showMessage(widget.copy.linkFailed);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
