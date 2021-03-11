import 'dart:ui';

import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/cupertino_controls.dart';
import 'package:chewie/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({Key? key}) : super(key: key);

  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);

    double _calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget _buildControls(
      BuildContext context,
      ChewieController chewieController,
    ) {
      final controls = Theme.of(context).platform == TargetPlatform.android
          ? const MaterialControls()
          : const CupertinoControls(
              backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
              iconColor: Color.fromARGB(255, 200, 200, 200),
            );
      return chewieController.showControls
          ? chewieController.customControls ?? controls
          : Container();
    }

    Stack _buildPlayerWithControls(
        ChewieController chewieController, BuildContext context) {
      return Stack(
        children: <Widget>[
          chewieController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.aspectRatio ??
                  chewieController.videoPlayerController.value.aspectRatio,
              child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 25.0,
                  transformationController: _transformationController,
                  panEnabled: chewieController.allowZoom,
                  scaleEnabled: chewieController.allowZoom,
                  child: Stack(
                    children: [
                      VideoPlayer(chewieController.videoPlayerController),
                      chewieController.overlay ?? Container(),
                    ],
                  )),
            ),
          ),
          if (chewieController.allowZoom)
            Positioned(
              right: 0,
              top: 0,
              child: ZoomPlayer(
                transformationController: _transformationController,
              ),
            ),
          if (!chewieController.isFullScreen)
            _buildControls(context, chewieController)
          else
            SafeArea(
              child: _buildControls(context, chewieController),
            ),
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: _calculateAspectRatio(context),
          child: _buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }
}

class ZoomPlayer extends StatefulWidget {
  const ZoomPlayer({
    required this.transformationController,
    Key? key,
  }) : super(key: key);

  final TransformationController transformationController;

  @override
  _ZoomPlayerState createState() => _ZoomPlayerState();
}

class _ZoomPlayerState extends State<ZoomPlayer> {
  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    widget.transformationController.addListener(_listener);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ZoomPlayer oldWidget) {
    oldWidget.transformationController.removeListener(_listener);
    widget.transformationController.addListener(_listener);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double value =
        widget.transformationController.value.getMaxScaleOnAxis();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: value == 1.0 ? 0 : 1.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              "${(value * 100).toInt()}%",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
