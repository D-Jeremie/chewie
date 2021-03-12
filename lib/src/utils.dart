import 'package:flutter/widgets.dart';

import '../chewie.dart';

String formatDuration(Duration position) {
  final ms = position.inMilliseconds;

  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  final minutes = seconds ~/ 60;
  seconds = seconds % 60;

  final hoursString = hours >= 10
      ? '$hours'
      : hours == 0
          ? '00'
          : '0$hours';

  final minutesString = minutes >= 10
      ? '$minutes'
      : minutes == 0
          ? '00'
          : '0$minutes';

  final secondsString = seconds >= 10
      ? '$seconds'
      : seconds == 0
          ? '00'
          : '0$seconds';

  final formattedTime =
      '${hoursString == '00' ? '' : '$hoursString:'}$minutesString:$secondsString';

  return formattedTime;
}

void scale(
    BuildContext context,
    TransformationController transformationController,
    ChewieController chewieController,
    double factor) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null) {
    final size = box.size;

    final double aspectRatio = chewieController.aspectRatio ??
        chewieController.videoPlayerController.value.aspectRatio;

    final touchZone =
        Offset(size.width / 2, size.width * (1 / aspectRatio) / 2);

    final offsetA = transformationController.toScene(touchZone);

    transformationController.value =
        transformationController.value.scaled(factor);
    final offsetB = transformationController.toScene(touchZone);

    transformationController.value
        .translate(offsetB.dx - offsetA.dx, offsetB.dy - offsetA.dy);
  }
}
