import 'package:flutter/material.dart';
import 'package:map/esp_controller.dart';
import 'dart:ui' as ui;
import 'dart:math';

import 'map_object.dart';
import 'map_painter.dart';

class MapWidget extends StatefulWidget {
  final double zoomLevel;
  final ImageProvider imageProvider;
  final EspController espController;

  MapWidget({@required this.zoomLevel, @required this.imageProvider})
      : espController = EspController();

  @override
  State<StatefulWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  double _zoomLevel;
  ImageProvider _imageProvider;

  List<MapObject> _objects = [
    MapObject(
      child: Icon(
        Icons.location_on,
        color: Colors.redAccent.shade700,
      ),
      offset: Offset(0, 0),
      size: Size(25, 25),
    ),
  ];

  bool _objectDisplay = false;

  ui.Image _image;
  bool _resolved;
  Offset _centerOffset;

  double _maxHorizontalDelta;
  double _maxVerticalDelta;

  Offset _normalized;
  bool _denormalize = false;

  Size _actualImageSize;
  Size _viewportSize;
  bool isDrag = false;

  double abs(double value) {
    return value < 0 ? value * (-1) : value;
  }

  void _getActualImageDimensions() {
    _actualImageSize = Size(
        (_image.width / ui.window.devicePixelRatio) * _zoomLevel,
        (_image.height / ui.window.devicePixelRatio) * _zoomLevel);

    // print("deviceRatio ${ui.window.devicePixelRatio}");
    // print("image w= ${_image.width}, image h= ${_image.height}");
    // print(
    //     "actualImage w= ${_actualImageSize.width}, image h= ${_actualImageSize.height}");
  }

  Offset t;
  int count = 0;

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.zoomLevel;
    _imageProvider = widget.imageProvider;
    _resolved = false;
    _centerOffset = Offset(0, 0);
    /* Connection */
    widget.espController.httpConnect();
    widget.espController.espData.listen((data) {
      double x = data[0];
      double y = data[1];
      if (x <= 1 && y <= 1) {
        Offset pointTransform = _transform(x, y);
        Offset transformInDevicePixels = _globalToLocalOffset(pointTransform);
        _objects[0].offset = pointTransform;
        dragMapOrNot(transformInDevicePixels);
        _objectDisplay = true;
      } else {
        _objectDisplay = false;
      }
      setState(() {
        isDrag = false;
      });
    });
  }

  dragMapOrNot(Offset offset) {
    if (offset.dx > _viewportSize.width)
      _centerOffset =
          _centerOffset.translate(offset.dx - _viewportSize.width + 20, 0);
    if (offset.dx < 0)
      _centerOffset = _centerOffset.translate(offset.dx - 20, 0);
    if (offset.dy > _viewportSize.height)
      _centerOffset =
          _centerOffset.translate(0, offset.dy - _viewportSize.height + 20);
    if (offset.dy < 0)
      _centerOffset = _centerOffset.translate(0, offset.dy - 20);
  }

  void _resolveImageProvider() {
    ImageStream stream =
        _imageProvider.resolve(createLocalImageConfiguration(context));
    stream.addListener(ImageStreamListener((info, _) {
      _image = info.image;
      _resolved = true;
      _getActualImageDimensions();
      setState(() {});
    }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageProvider();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != _imageProvider) {
      _imageProvider = widget.imageProvider;
      _resolveImageProvider();
    }
    double normalizedDx =
        _maxHorizontalDelta == 0 ? 0 : _centerOffset.dx / _maxHorizontalDelta;
    double normalizedDy =
        _maxVerticalDelta == 0 ? 0 : _centerOffset.dy / _maxVerticalDelta;
    _normalized = Offset(normalizedDx, normalizedDy);
    _denormalize = true;
    _zoomLevel = widget.zoomLevel;
    _getActualImageDimensions();
    isDrag = true;
  }

  /// This is used to convert map objects relative global offsets from the map center
  /// to the local viewport offset from the top left viewport corner.
  Offset _globalToLocalOffset(Offset value) {
    double hDelta = (_actualImageSize.width / 2) * (value.dx);
    double vDelta = (_actualImageSize.height / 2) * (value.dy);
    double dx = (hDelta - _centerOffset.dx) + (_viewportSize.width / 2);
    double dy = (vDelta - _centerOffset.dy) + (_viewportSize.height / 2);
    return Offset(dx, dy);
  }

  /// This is used to convert global coordinates of long press event on the map to relative global offsets from the map center
  Offset _localToGlobalOffset(Offset value) {
    double dx = value.dx - _viewportSize.width / 2;
    double dy = value.dy - _viewportSize.height / 2;
    double dh = dx + _centerOffset.dx;
    double dv = dy + _centerOffset.dy;
    return Offset(
      dh / (_actualImageSize.width / 2),
      dv / (_actualImageSize.height / 2),
    );
  }

  Offset _transform(double x, double y) {
    double w = x * 2 - 1;
    double h = y * 2 - 1;
    return Offset(w, h);
  }

  @override
  Widget build(BuildContext context) {
    return _resolved
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _viewportSize = Size(
                  min(constraints.maxWidth, _actualImageSize.width),
                  min(constraints.maxHeight, _actualImageSize.height));
              _maxHorizontalDelta =
                  (_actualImageSize.width - _viewportSize.width) / 2 + 30;
              _maxVerticalDelta =
                  (_actualImageSize.height - _viewportSize.height) / 2 + 30;
              bool reactOnHorizontalDrag =
                  _maxHorizontalDelta > _maxVerticalDelta;
              bool reactOnPan =
                  (_maxHorizontalDelta > 0 && _maxVerticalDelta > 0);
              if (_denormalize) {
                _centerOffset = Offset(_maxHorizontalDelta * _normalized.dx,
                    _maxVerticalDelta * _normalized.dy);
                _denormalize = false;
              }

              return GestureDetector(
                onPanUpdate: reactOnPan ? handleDrag : null,
                onHorizontalDragUpdate:
                    reactOnHorizontalDrag && !reactOnPan ? handleDrag : null,
                onVerticalDragUpdate:
                    !reactOnHorizontalDrag && !reactOnPan ? handleDrag : null,
                child: Center(
                  child: Stack(
                    children: <Widget>[
                          CustomPaint(
                            size: _viewportSize,
                            painter:
                                MapPainter(_image, _zoomLevel, _centerOffset),
                          ),
                        ] +
                        _buildObjects(),
                  ),
                ),
              );
            },
          )
        : SizedBox();
  }

  void handleDrag(DragUpdateDetails updateDetails) {
    Offset newOffset = _centerOffset.translate(
        -updateDetails.delta.dx, -updateDetails.delta.dy);
    if (abs(newOffset.dx) <= _maxHorizontalDelta &&
        abs(newOffset.dy) <= _maxVerticalDelta)
      setState(() {
        isDrag = true;
        _centerOffset = newOffset;
      });
  }

  void addMapObject(MapObject object) => setState(() {
        _objects.add(object);
      });

  void removeMapObject(MapObject object) => setState(() {
        _objects.remove(object);
      });

  List<Widget> _buildObjects() {
    return _objectDisplay
        ? _objects
            .map(
              (MapObject object) => AnimatedPositioned(
                duration:  Duration(milliseconds: isDrag? 0: 1000),
                left: _globalToLocalOffset(object.offset).dx -
                    (object.size == null ? 0 : (object.size.width) / 2),
                top: _globalToLocalOffset(object.offset).dy -
                    (object.size == null ? 0 : (object.size.height) - 2),
                child: Container(
                  child: object.child,
                ),
              ),
            )
            .toList()
        : [];
  }

  @override
  void dispose() {
    super.dispose();
    widget.espController.dispose();
  }
}
