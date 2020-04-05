import 'dart:async';
import 'dart:math';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_candies_demo_library/src/data/tu_chong_source.dart';
import 'package:flutter_candies_demo_library/src/model/pic_swiper_item.dart';
import 'package:flutter_candies_demo_library/src/text/my_extended_text_selection_controls.dart';
import 'package:flutter_candies_demo_library/src/text/my_special_text_span_builder.dart';
import 'package:flutter_candies_demo_library/src/utils/util.dart';
import 'package:oktoast/oktoast.dart';
import 'dart:ui';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';
import 'item_builder.dart';

const String attachContent =
    '''[love]Extended text help you to build rich text quickly. any special text you will have with extended text.It's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love] if you meet any problem, please let me konw @zmtzawqlp .[sun_glasses]''';

@FFRoute(
    name: 'fluttercandies://picswiper',
    routeName: 'PicSwiper',
    argumentNames: ['index', 'pics', 'tuChongItem'],
    showStatusBar: false,
    pageRouteType: PageRouteType.transparent)
class PicSwiper extends StatefulWidget {
  final int index;
  final List<PicSwiperItem> pics;
  final TuChongItem tuChongItem;
  PicSwiper({
    this.index,
    this.pics,
    this.tuChongItem,
  });
  @override
  _PicSwiperState createState() => _PicSwiperState();
}

class _PicSwiperState extends State<PicSwiper> with TickerProviderStateMixin {
  final rebuildIndex = StreamController<int>.broadcast();
  final rebuildSwiper = StreamController<bool>.broadcast();
  final rebuildDetail = StreamController<double>.broadcast();
  final detailKeys = <int, ImageDetailInfo>{};
  AnimationController _doubleClickAnimationController;
  AnimationController _slideEndAnimationController;
  Animation<double> _slideEndAnimation;
  Animation<double> _doubleClickAnimation;
  Function _doubleClickAnimationListener;
  List<double> doubleTapScales = <double>[1.0, 2.0];
  GlobalKey<ExtendedImageSlidePageState> slidePagekey =
      GlobalKey<ExtendedImageSlidePageState>();
  int _currentIndex = 0;
  bool _showSwiper = true;
  double _imageDetailY = 0;
  Rect imageDRect;
  @override
  void initState() {
    _currentIndex = widget.index;
    _doubleClickAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);

    _slideEndAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _slideEndAnimationController.addListener(() {
      _imageDetailY = _slideEndAnimation.value;
      if (_imageDetailY == 0) {
        _showSwiper = true;
        rebuildSwiper.add(_showSwiper);
      }
      rebuildDetail.sink.add(_imageDetailY);
    });
    super.initState();
  }

  @override
  void dispose() {
    rebuildIndex.close();
    rebuildSwiper.close();
    rebuildDetail.close();
    _doubleClickAnimationController.dispose();
    _slideEndAnimationController.dispose();
    clearGestureDetailsCache();
    //cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    imageDRect = Offset.zero & size;
    Widget result = Material(

        /// if you use ExtendedImageSlidePage and slideType =SlideType.onlyImage,
        /// make sure your page is transparent background
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExtendedImageGesturePageView.builder(
              controller: PageController(
                initialPage: widget.index,
              ),
              itemBuilder: (BuildContext context, int index) {
                var item = widget.pics[index].picUrl;

                Widget image = ExtendedImage.network(
                  item,
                  fit: BoxFit.contain,
                  enableSlideOutPage: true,
                  mode: ExtendedImageMode.gesture,
                  heroBuilderForSlidingPage: (Widget result) {
                    if (index < min(9, widget.pics.length)) {
                      return Hero(
                        tag: item,
                        child: result,
                        flightShuttleBuilder: (BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext) {
                          final Hero hero =
                              flightDirection == HeroFlightDirection.pop
                                  ? fromHeroContext.widget
                                  : toHeroContext.widget;
                          return hero.child;
                        },
                      );
                    } else {
                      return result;
                    }
                  },
                  initGestureConfigHandler: (state) {
                    var initialScale = 1.0;

                    if (state.extendedImageInfo != null &&
                        state.extendedImageInfo.image != null) {
                      initialScale = initScale(
                          size: size,
                          initialScale: initialScale,
                          imageSize: Size(
                              state.extendedImageInfo.image.width.toDouble(),
                              state.extendedImageInfo.image.height.toDouble()));
                    }
                    return GestureConfig(
                        inPageView: true,
                        initialScale: initialScale,
                        maxScale: max(initialScale, 5.0),
                        animationMaxScale: max(initialScale, 5.0),
                        initialAlignment: InitialAlignment.center,
                        //you can cache gesture state even though page view page change.
                        //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                        cacheGesture: false);
                  },
                  onDoubleTap: (ExtendedImageGestureState state) {
                    ///you can use define pointerDownPosition as you can,
                    ///default value is double tap pointer down postion.
                    final pointerDownPosition = state.pointerDownPosition;
                    var begin = state.gestureDetails.totalScale;
                    double end;

                    //remove old
                    _doubleClickAnimation
                        ?.removeListener(_doubleClickAnimationListener);

                    //stop pre
                    _doubleClickAnimationController.stop();

                    //reset to use
                    _doubleClickAnimationController.reset();

                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }

                    _doubleClickAnimationListener = () {
                      //print(_animation.value);
                      state.handleDoubleTap(
                          scale: _doubleClickAnimation.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    _doubleClickAnimation = _doubleClickAnimationController
                        .drive(Tween<double>(begin: begin, end: end));

                    _doubleClickAnimation
                        .addListener(_doubleClickAnimationListener);

                    _doubleClickAnimationController.forward();
                  },
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState == LoadState.completed) {
                      final imageDRect = getDestinationRect(
                        rect: Offset.zero & size,
                        inputSize: Size(
                          state.extendedImageInfo.image.width.toDouble(),
                          state.extendedImageInfo.image.height.toDouble(),
                        ),
                        fit: BoxFit.contain,
                      );

                      detailKeys[index] ??= ImageDetailInfo(
                        imageDRect: imageDRect,
                        pageSize: size,
                        imageInfo: state.extendedImageInfo,
                      );
                      final imageDetailInfo = detailKeys[index];
                      return StreamBuilder(
                        builder: (context, data) {
                          return ExtendedImageGesture(
                            state,
                            canScaleImage: (_) => _imageDetailY == 0,
                            imageBuilder: (image) {
                              return Stack(
                                children: <Widget>[
                                  Positioned.fill(
                                    child: image,
                                    top: _imageDetailY,
                                    bottom: -_imageDetailY,
                                  ),
                                  Positioned(
                                    left: 0.0,
                                    right: 0.0,
                                    top: imageDetailInfo.imageBottom +
                                        _imageDetailY,
                                    child: Opacity(
                                      opacity: _imageDetailY == 0
                                          ? 0
                                          : min(
                                              1,
                                              _imageDetailY.abs() /
                                                  (imageDetailInfo
                                                          .maxImageDetailY /
                                                      4.0),
                                            ),
                                      child: ImageDetail(
                                        imageDetailInfo,
                                        index,
                                        widget.tuChongItem,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        initialData: _imageDetailY,
                        stream: rebuildDetail.stream,
                      );
                    }
                    return null;
                  },
                );
                image = GestureDetector(
                  child: image,
                  onTap: () {
                    // if (translateY != 0) {
                    //   translateY = 0;
                    //   rebuildDetail.sink.add(translateY);
                    // }
                    // else
                    {
                      slidePagekey.currentState.popPage();
                      Navigator.pop(context);
                    }
                  },
                );

                return image;
              },
              itemCount: widget.pics.length,
              onPageChanged: (int index) {
                _currentIndex = index;
                rebuildIndex.add(index);
                if (_imageDetailY != 0) {
                  _imageDetailY = 0;
                  rebuildDetail.sink.add(_imageDetailY);
                }
                _showSwiper = true;
                rebuildSwiper.add(_showSwiper);
              },
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
//              //move page only when scale is not more than 1.0
              // canMovePage: (GestureDetails gestureDetails) {
              //   //gestureDetails.totalScale <= 1.0
              //   //return translateY == 0.0;

              // }
              //physics: ClampingScrollPhysics(),
            ),
            StreamBuilder<bool>(
              builder: (c, d) {
                if (d.data == null || !d.data) return Container();

                return Positioned(
                  top: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child:
                      MySwiperPlugin(widget.pics, _currentIndex, rebuildIndex),
                );
              },
              initialData: true,
              stream: rebuildSwiper.stream,
            )
          ],
        ));

    result = ExtendedImageSlidePage(
      key: slidePagekey,
      child: result,
      slideAxis: SlideAxis.both,
      slideType: SlideType.onlyImage,
      slideScaleHandler: (
        Offset offset, {
        ExtendedImageSlidePageState state,
      }) {
        //image is ready and it's not sliding.
        if (detailKeys[_currentIndex] != null && state.scale == 1.0) {
          //don't slide page if scale of image is more than 1.0
          if (state != null &&
              state.imageGestureState.gestureDetails.totalScale > 1.0) {
            return 1.0;
          }
          //or slide down into detail mode
          if (offset.dy < 0 || _imageDetailY < 0) {
            return 1.0;
          }
        }

        return null;
      },
      slideOffsetHandler: (
        Offset offset, {
        ExtendedImageSlidePageState state,
      }) {
        //image is ready and it's not sliding.
        if (detailKeys[_currentIndex] != null && state.scale == 1.0) {
          //don't slide page if scale of image is more than 1.0

          if (state != null &&
              state.imageGestureState.gestureDetails.totalScale > 1.0) {
            return Offset.zero;
          }

          //or slide down into detail mode
          if (offset.dy < 0 || _imageDetailY < 0) {
            _imageDetailY += offset.dy;

            // print(offset.dy);
            _imageDetailY =
                max(-detailKeys[_currentIndex].maxImageDetailY, _imageDetailY);
            rebuildDetail.sink.add(_imageDetailY);
            return Offset.zero;
          }

          if (_imageDetailY != 0) {
            _imageDetailY = 0;
            _showSwiper = true;
            rebuildSwiper.add(_showSwiper);
            rebuildDetail.sink.add(_imageDetailY);
          }
        }
        return null;
      },
      slideEndHandler: (
        Offset offset, {
        ExtendedImageSlidePageState state,
        ScaleEndDetails details,
      }) {
        if (_imageDetailY != 0 && state.scale == 1) {
          if (!_slideEndAnimationController.isAnimating) {
// get magnitude from gesture velocity
            final magnitude = details.velocity.pixelsPerSecond.distance;

            // do a significant magnitude

            if (doubleCompare(magnitude, minMagnitude) >= 0) {
              final direction =
                  details.velocity.pixelsPerSecond / magnitude * 1000;

              _slideEndAnimation =
                  _slideEndAnimationController.drive(Tween<double>(
                begin: _imageDetailY,
                end: (_imageDetailY + direction.dy)
                    .clamp(-detailKeys[_currentIndex].maxImageDetailY, 0.0),
              ));
              _slideEndAnimationController.reset();
              _slideEndAnimationController.forward();
            }
          }
          return false;
        }

        return null;
      },
      onSlidingPage: (state) {
        ///you can change other widgets' state on page as you want
        ///base on offset/isSliding etc
        //var offset= state.offset;
        var showSwiper = !state.isSliding;
        if (showSwiper != _showSwiper) {
          // do not setState directly here, the image state will change,
          // you should only notify the widgets which are needed to change
          // setState(() {
          // _showSwiper = showSwiper;
          // });

          _showSwiper = showSwiper;
          rebuildSwiper.add(_showSwiper);
        }
      },
    );

    return result;
  }
}

class MySwiperPlugin extends StatelessWidget {
  final List<PicSwiperItem> pics;
  final int index;
  final StreamController<int> reBuild;
  MySwiperPlugin(this.pics, this.index, this.reBuild);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      builder: (BuildContext context, data) {
        return DefaultTextStyle(
          style: TextStyle(color: Colors.blue),
          child: Container(
            height: 50.0,
            width: double.infinity,
            color: Colors.grey.withOpacity(0.2),
            child: Row(
              children: <Widget>[
                Container(
                  width: 10.0,
                ),
                Text(
                  '${data.data + 1}',
                ),
                Text(
                  ' / ${pics.length}',
                ),
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                    child: Text(pics[data.data].des ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0, color: Colors.blue))),
                SizedBox(
                  width: 10.0,
                ),
                !kIsWeb
                    ? GestureDetector(
                        child: Container(
                          padding: EdgeInsets.only(right: 10.0),
                          alignment: Alignment.center,
                          child: Text(
                            'Save',
                            style:
                                TextStyle(fontSize: 16.0, color: Colors.blue),
                          ),
                        ),
                        onTap: () {
                          saveNetworkImageToPhoto(pics[index].picUrl)
                              .then((bool done) {
                            showToast(done ? 'save succeed' : 'save failed',
                                position:
                                    ToastPosition(align: Alignment.topCenter));
                          });
                        },
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
      initialData: index,
      stream: reBuild.stream,
    );
  }
}

class ImageDetailInfo {
  ImageDetailInfo({
    @required this.imageDRect,
    @required this.pageSize,
    @required this.imageInfo,
  });

  final key = GlobalKey<State>();

  final Rect imageDRect;

  final Size pageSize;

  final ImageInfo imageInfo;

  double get imageBottom => imageDRect.bottom - 20;

  double _maxImageDetailY;
  double get maxImageDetailY {
    try {
      //
      return _maxImageDetailY ??= max(
          (key.currentContext.size.height - (pageSize.height - imageBottom)),
          0.1);
    } catch (e) {
      //currentContext is not ready
      return 100.0;
    }
  }
}

class ImageDetail extends StatelessWidget {
  final ImageDetailInfo info;
  final int index;
  final TuChongItem tuChongItem;
  ImageDetail(
    this.info,
    this.index,
    this.tuChongItem,
  );
  @override
  Widget build(BuildContext context) {
    var content =
        tuChongItem.content ?? (tuChongItem.excerpt ?? tuChongItem.title);
    content += attachContent * 2;
    Widget result = Container(
      // constraints: BoxConstraints(minHeight: 25.0),
      key: info.key,
      margin: EdgeInsets.only(
        left: 5,
        right: 5,
      ),
      padding: EdgeInsets.all(20.0),
      child: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildTagsWidget(
                tuChongItem,
                maxNum: tuChongItem.tags.length,
              ),
              SizedBox(
                height: 15.0,
              ),
              ExtendedText(
                content,
                onSpecialTextTap: (dynamic parameter) {
                  if (parameter.startsWith('\$')) {
                    launch('https://github.com/fluttercandies');
                  } else if (parameter.startsWith('@')) {
                    launch('mailto:zmtzawqlp@live.com');
                  }
                },
                specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                //overflow: ExtendedTextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 10,
                overFlowTextSpan: kIsWeb
                    ? null
                    : OverFlowTextSpan(
                        children: <TextSpan>[
                          TextSpan(text: '  \u2026  '),
                          TextSpan(
                              text: 'more detail',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  launch(
                                      'https://github.com/fluttercandies/extended_text');
                                })
                        ],
                      ),
                selectionEnabled: true,
                textSelectionControls:
                    MyExtendedMaterialTextSelectionControls(),
              ),
              SizedBox(
                height: 20.0,
              ),
              Divider(height: 1),
              SizedBox(
                height: 20.0,
              ),
              buildBottomWidget(
                tuChongItem,
                showAvatar: true,
              ),
            ],
          ),
          Positioned(
            top: -30.0,
            left: -15.0,
            child: FloatText(
              '${(index + 1).toString().padLeft(tuChongItem.images.length.toString().length, '0')}/${tuChongItem.images.length}',
            ),
          ),
          Positioned(
            top: -30.0,
            right: -15.0,
            child: FloatText(
              '${info.imageInfo.image.width} * ${info.imageInfo.image.height}',
            ),
          ),
          Positioned(
              top: -33.0,
              right: 0,
              left: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                ],
              )),
        ],
      ),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
            color: Colors.grey,
          ),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 15.0, spreadRadius: 20.0),
          ]),
    );

    return ExtendedTextSelectionPointerHandler(
      //default behavior
      // child: result,
      //custom your behavior
      builder: (states) {
        return GestureDetector(
          onTap: () {
            //do not pop page
          },
          child: Listener(
            child: result,
            behavior: HitTestBehavior.translucent,
            onPointerDown: (value) {
              for (var state in states) {
                if (!state.containsPosition(value.position)) {
                  //clear other selection
                  state.clearSelection();
                }
              }
            },
            onPointerMove: (value) {
              //clear other selection
              for (var state in states) {
                state.clearSelection();
              }
            },
          ),
        );
      },
    );
  }
}

class FloatText extends StatelessWidget {
  FloatText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.6),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(5.0),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
