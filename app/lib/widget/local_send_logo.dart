import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/assets.gen.dart';
import 'package:localsend_app/gen/strings.g.dart';

class LocalSendLogo extends StatelessWidget {
  final bool withText;
  final double size;

  const LocalSendLogo({required this.withText, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final logo = ColorFiltered(
      colorFilter: ColorFilter.mode(
        FluentTheme.of(context).accentColor,
        BlendMode.srcATop,
      ),
      child: Assets.img.logo512.image(width: size, height: size),
    );

    if (withText) {
      return Column(
        children: [
          logo,
          Text(
            t.appName,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return logo;
    }
  }
}
