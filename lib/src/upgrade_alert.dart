import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final String gifImage;
  final String imagesUp;

  UpgradeAlert(
      {super.key,
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
      required this.gifImage,
      required this.imagesUp})
      : upgrader = upgrader ?? Upgrader.sharedInstance;

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
        showTheBottomSheet(
          context: context,
          title: appMessages.message(UpgraderMessage.title),
          message: widget.upgrader.body(appMessages),
          releaseNotes:
              shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null,
          gifImage: widget.gifImage,
          imagesUp: widget.imagesUp,
        );
      });
    }
  }

  void showTheBottomSheet({
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required String gifImage,
    required String imagesUp,
  }) {
showModalBottomSheet(
  context: context,
   isDismissible: false,

  builder: (BuildContext context) {
    return GestureDetector(
         behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) {}, // Ignores vertical drag gestures
    
      child: Container(
    
        color: Color(0xff0f0e0f),
        child: Container(
            padding: EdgeInsets.all(24.0),
    
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E), // Updated to your specified color #1e1e1e
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            //  border: Border.all(color: Colors.grey, width: 1)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    gifImage,
                    height: 50,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    imagesUp,
                    width: 100,
                    height: 100,
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Unlock the latest Choira features\n by updating the app NOW!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () => onUserUpdated(context, true),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(0xffF1B103),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    width: double.infinity,
                    height: 40,
                    child: Text(
                      "Update Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff262727),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  },
  isScrollControlled: true,
);

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
      widget.showReleaseNotes &&
      (widget.upgrader.releaseNotes?.isNotEmpty ?? false);
}
