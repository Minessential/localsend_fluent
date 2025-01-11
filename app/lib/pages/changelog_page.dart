import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:localsend_app/gen/assets.gen.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/base/base_dialog_page.dart';
import 'package:localsend_app/util/ui/nav_bar_padding.dart';

class ChangelogPage extends StatelessWidget {
  const ChangelogPage();

  @override
  Widget build(BuildContext context) {
    return BaseDialogPage(
      title: t.changelogPage.title,
      body: FutureBuilder(
        future: rootBundle.loadString(Assets.changelog), // ignore: discarded_futures
        builder: (context, data) {
          if (!data.hasData) {
            return Container();
          }
          return Markdown(
            padding: EdgeInsets.only(
              left: 15,
              right: 15,
              top: 15,
              bottom: 15 + getNavBarPadding(context),
            ),
            data: data.data!,
          );
        },
      ),
    );
  }
}
