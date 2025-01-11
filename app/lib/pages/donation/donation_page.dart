import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/state/purchase_state.dart';
import 'package:localsend_app/pages/base/base_dialog_page.dart';
import 'package:localsend_app/pages/donation/donation_page_vm.dart';
// [FOSS_REMOVE_START]
import 'package:localsend_app/provider/purchase_provider.dart';
// [FOSS_REMOVE_END]
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: donationPageVmProvider,
      // [FOSS_REMOVE_START]
      init: (context) =>
          context.redux(purchaseProvider).dispatchAsync(FetchPricesAndPurchasesAction()), // ignore: discarded_futures
      // [FOSS_REMOVE_END]
      builder: (context, vm) {
        return BaseDialogPage(
          title: t.donationPage.title,
          body: Stack(
            children: [
              ResponsiveListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Text(
                      t.donationPage.info,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 50),
                  if (vm.purchased.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Center(
                        child: Text(
                          t.donationPage.thanks,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FluentTheme.of(context).accentColor),
                        ),
                      ),
                    ),
                  if (vm.platformSupportPayment) _StoreDonation(vm) else const _LinkDonation(),
                ],
              ),
              if (vm.pending)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: ProgressRing(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StoreDonation extends StatelessWidget {
  final DonationPageVm vm;

  const _StoreDonation(this.vm);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...PurchaseItem.values.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton(
              onPressed: vm.purchased.contains(item) ? null : () => vm.purchase(item),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.heart_fill),
                  const SizedBox(width: 5),
                  Text(t.donationPage.donate(amount: vm.prices[item] ?? '...')),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        HyperlinkButton(
          onPressed: vm.restore,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.update_restore),
              const SizedBox(width: 5),
              Text(t.donationPage.restore),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkDonation extends StatelessWidget {
  const _LinkDonation();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        HyperlinkButton(
          onPressed: () async {
            await launchUrl(Uri.parse('https://github.com/sponsors/Tienisto'), mode: LaunchMode.externalApplication);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.open_in_new_window),
              const SizedBox(width: 5),
              const Text('Github'),
            ],
          ),
        ),
        HyperlinkButton(
          onPressed: () async {
            await launchUrl(Uri.parse('https://ko-fi.com/tienisto'), mode: LaunchMode.externalApplication);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.open_in_new_window),
              const SizedBox(width: 5),
              const Text('Ko-fi'),
            ],
          ),
        ),
      ],
    );
  }
}
