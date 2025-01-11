import 'package:fluent_ui/fluent_ui.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:routerino/routerino.dart';

class FavoriteDeleteDialog extends StatelessWidget {
  final FavoriteDevice favorite;

  const FavoriteDeleteDialog(this.favorite);

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.favoriteDeleteDialog.title),
      content: Text(t.dialogs.favoriteDeleteDialog.content(name: favorite.alias)),
      actions: [
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(t.general.delete),
        ),
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
      ],
    );
  }
}
