import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:legalize/legalize.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/selection/selected_receiving_files_provider.dart';
import 'package:localsend_app/widget/fluent/custom_text_box.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:uuid/uuid.dart';

enum _QuickAction {
  counter,
  random;

  String get label {
    switch (this) {
      case _QuickAction.counter:
        return t.dialogs.quickActions.counter;
      case _QuickAction.random:
        return t.dialogs.quickActions.random;
    }
  }
}

class QuickActionsDialog extends StatefulWidget {
  const QuickActionsDialog({super.key});

  @override
  State<QuickActionsDialog> createState() => _QuickActionsDialogState();
}

class _QuickActionsDialogState extends State<QuickActionsDialog> with Refena {
  _QuickAction _action = _QuickAction.counter;

  // counter
  String _prefix = '';
  bool _padZero = false;
  bool _sortBeforehand = false;

  // random
  final _randomUuid = const Uuid().v4();

  // sanity check
  bool _isValid = true;

  bool _validate(String input) {
    if (!isValidFilename(input, os: Platform.operatingSystem) && input.isNotEmpty) {
      setState(() {
        _isValid = false;
      });
      return false;
    }

    if (!_isValid) {
      setState(() {
        _isValid = true;
      });
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(t.dialogs.quickActions.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 15,
            children: _QuickAction.values.map((mode) {
              return RadioButton(
                content: Text(mode.label),
                checked: _action == mode,
                onChanged: (_) {
                  setState(() {
                    _action = mode;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (_action == _QuickAction.counter) ...[
            Text(t.dialogs.quickActions.prefix),
            const SizedBox(height: 5),
            CustomTextBox(
              autofocus: true,
              onChanged: (s) {
                _validate(s);
                setState(() {
                  _prefix = s;
                });
              },
            ),
            const SizedBox(height: 5),
            Visibility(
                visible: !_isValid,
                child: Text(
                  t.sanitization.invalid,
                  style: TextStyle(color: Colors.warningPrimaryColor),
                )),
            const SizedBox(height: 10),
            Checkbox(
              content:Text( t.dialogs.quickActions.padZero),
              checked: _padZero,
              onChanged: (b) {
                setState(() {
                  _padZero = b == true;
                });
              },
            ),
            const SizedBox(height: 5),
            Checkbox(
              content: Text(t.dialogs.quickActions.sortBeforeCount),
              checked: _sortBeforehand,
              onChanged: (b) {
                setState(() {
                  _sortBeforehand = b == true;
                });
              },
            ),
            const SizedBox(height: 10),
            if (_padZero)
              Text('${t.general.example}: ${_prefix}04.jpg')
            else
              Text('${t.general.example}: ${_prefix}4.jpg'),
          ],
          if (_action == _QuickAction.random) Text('${t.general.example}: $_randomUuid.jpg'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            switch (_action) {
              case _QuickAction.counter:
                if (!_isValid) {
                  return;
                }
                ref.notifier(selectedReceivingFilesProvider).applyCounter(
                      prefix: _prefix,
                      padZero: _padZero,
                      sortFirst: _sortBeforehand,
                    );
                break;
              case _QuickAction.random:
                ref.notifier(selectedReceivingFilesProvider).applyRandom();
                break;
            }
            context.pop();
          },
          child: Text(t.general.confirm),
        ),
        Button(
          onPressed: () => context.pop(),
          child: Text(t.general.cancel),
        ),
      ],
    );
  }
}
