import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'upgrade_messages.dart';
import 'upgrader.dart';

enum UpgradeDialogStyle { cupertino, material }

class UpgradeAlert extends StatefulWidget {
  final Upgrader upgrader;
  final bool canDismissDialog;
  final UpgradeDialogStyle dialogStyle;
  final BoolCallback? onIgnore;
  final BoolCallback? onLater;
  final BoolCallback? onUpdate;
  final BoolCallback? shouldPopScope;
  final bool showIgnore;
  final bool showLater;
  final bool showReleaseNotes;
  final TextStyle? cupertinoButtonTextStyle;
  final GlobalKey? dialogKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? child;

  UpgradeAlert({
    super.key,
    Upgrader? upgrader,
    this.canDismissDialog = false,
    this.dialogStyle = UpgradeDialogStyle.material,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
    this.cupertinoButtonTextStyle,
    this.dialogKey,
    this.navigatorKey,
    this.child,
  }) : upgrader = upgrader ?? Upgrader.sharedInstance;

  @override
  UpgradeAlertState createState() => UpgradeAlertState();
}

class UpgradeAlertState extends State<UpgradeAlert> {
  bool displayed = false;

  @override
  void initState() {
    super.initState();
    widget.upgrader.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: widget.upgrader.evaluationReady,
      stream: widget.upgrader.evaluationStream,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            snapshot.data!) {
          if (!displayed) {
            final checkContext = widget.navigatorKey?.currentContext ?? context;
            checkVersion(context: checkContext);
          }
        }
        return widget.child ?? const SizedBox.shrink();
      },
    );
  }

  void checkVersion({required BuildContext context}) {
    final shouldDisplay = widget.upgrader.shouldDisplayUpgrade();
    if (shouldDisplay) {
      displayed = true;
      final appMessages = widget.upgrader.determineMessages(context);

      Future.delayed(const Duration(milliseconds: 0), () {
        showTheScaffold(
          key: widget.dialogKey ?? const Key('upgrader_scaffold'),
          context: context,
          title: appMessages.message(UpgraderMessage.title),
          message: widget.upgrader.body(appMessages),
          releaseNotes: shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null,
        );
      });
    }
  }

  void showTheScaffold({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
  }) {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title ?? 'Update Available'),
          leading: widget.canDismissDialog ? IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ) : null,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(message),
              if (releaseNotes != null) Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text('Release Notes:\n$releaseNotes'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (widget.showIgnore) TextButton(
                onPressed: () => onUserIgnored(context, true),
                child: Text('Ignore'),
              ),
              if (widget.showLater) TextButton(
                onPressed: () => onUserLater(context, true),
                child: Text('Later'),
              ),
              TextButton(
                onPressed: () => onUserUpdated(context, true),
                child: Text('Update'),
              ),
            ],
          ),
        ),
      );
    }));
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    final doProcess = widget.onIgnore?.call() ?? true;
    if (doProcess) {
      widget.upgrader.saveIgnored();
    }
    if (shouldPop) {
      Navigator.of(context).pop();
      displayed = false;
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    widget.onLater?.call();
    if (shouldPop) {
      Navigator.of(context).pop();
      displayed = false;
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    final doProcess = widget.onUpdate?.call() ?? true;
    if (doProcess) {
      widget.upgrader.sendUserToAppStore();
    }
    if (shouldPop) {
      Navigator.of(context).pop();
      displayed = false;
    }
  }

  bool get shouldDisplayReleaseNotes =>
      widget.showReleaseNotes && (widget.upgrader.releaseNotes?.isNotEmpty ?? false);
}
