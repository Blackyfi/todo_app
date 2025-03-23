import 'package:flutter/material.dart';
import 'package:todo_app/common/widgets/current_time_display.dart';

class AppBarWithTime extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  
  const AppBarWithTime({
    Key? key,
    required this.title,
    this.actions,
    this.bottom,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> finalActions = <Widget>[
      const CurrentTimeDisplay(),
      const SizedBox(width: 8),
    ];
    
    if (actions != null) {
      finalActions.addAll(actions!);
    }
    
    return AppBar(
      title: Text(title),
      actions: finalActions,
      bottom: bottom,
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(
    bottom != null ? kToolbarHeight + bottom!.preferredSize.height : kToolbarHeight
  );
}