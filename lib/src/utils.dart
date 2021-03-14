import 'package:chewie/src/interactive_viewer_video_zoom.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart'
    show Quad, Vector3, Matrix4, Quaternion;

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

GlobalKey<InteractiveViewerVideoZoomState> viewerKey = GlobalKey();

void scale(
    BuildContext context,
    TransformationControllerZoom transformationController,
    ChewieController chewieController,
    double factor) {
  final box = viewerKey.currentContext?.findRenderObject() as RenderBox?;
  if (box != null) {
    final size = box.size;

    final touchZone = Offset(size.width / 2, size.width / 2);

    final offsetA = transformationController.toScene(touchZone);

    transformationController.value =
        transformationController.value.scaled(factor);
    final offsetB = transformationController.toScene(touchZone);

    transformationController.value
        .translate(offsetB.dx - offsetA.dx, offsetB.dy - offsetA.dy);

    final Offset exceed = _exceedsBy(
        getBoundaries(Offset.zero & box.size),
        _transformViewport(
            transformationController.value.clone(), Offset.zero & box.size));

    if (exceed != Offset.zero) {
      transformationController.value.translate(-exceed.dx, -exceed.dy);
    }
  }
}

Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(Vector3(
      viewport.topLeft.dx,
      viewport.topLeft.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.topRight.dx,
      viewport.topRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomRight.dx,
      viewport.bottomRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomLeft.dx,
      viewport.bottomLeft.dy,
      0.0,
    )),
  );
}

Quad getBoundaries(Rect rect) {
  return Quad.points(
    Vector3(rect.left, rect.top, 0.0),
    Vector3(rect.right, rect.top, 0.0),
    Vector3(rect.right, rect.bottom, 0.0),
    Vector3(rect.left, rect.bottom, 0.0),
  );

  final Matrix4 rotationMatrix = Matrix4.identity()
    ..translate(rect.size.width / 2, rect.size.height / 2)
    ..translate(-rect.size.width / 2, -rect.size.height / 2);

  return Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
}

Offset _exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0,
    viewport.point1,
    viewport.point2,
    viewport.point3,
  ];

  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside =
        InteractiveViewerVideoZoom.getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return _round(largestExcess);
}

// Round the output values. This works around a precision problem where
// values that should have been zero were given as within 10^-10 of zero.
Offset _round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}
