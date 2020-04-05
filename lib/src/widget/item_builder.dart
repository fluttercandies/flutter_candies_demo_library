import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_candies_demo_library/src/data/tu_chong_repository.dart';
import 'package:flutter_candies_demo_library/src/data/tu_chong_source.dart';
import 'package:flutter_candies_demo_library/src/utils/screen_util.dart';
import 'package:like_button/like_button.dart';

Widget itemBuilder(BuildContext context, TuChongItem item, int index) {
  return Container(
    height: ScreenUtil.instance.setWidth(kIsWeb ? 400.0 : 200.0),
    child: Stack(
      children: <Widget>[
        Positioned(
          child: kIsWeb
              ? ListView.builder(
                  itemBuilder: (c, index) {
                    return ExtendedImage.network(
                      item.images[index].imageUrl,
                      fit: BoxFit.cover,
                      width: ScreenUtil.instance
                          .setWidth(kIsWeb ? 400.0 : double.infinity),
                      height:
                          ScreenUtil.instance.setWidth(kIsWeb ? 400.0 : 200.0),
                      clearMemoryCacheWhenDispose: true,
                    );
                  },
                  scrollDirection: Axis.horizontal,
                  itemCount: item.images.length,
                )
              : ExtendedImage.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  //height: 200.0,
                  height: double.infinity,
                  clearMemoryCacheWhenDispose: true,
                ),
        ),
        Positioned(
          left: 0.0,
          right: 0.0,
          bottom: 0.0,
          child: Container(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            height: 40.0,
            color: Colors.grey.withOpacity(0.5),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.comment,
                      color: Colors.amberAccent,
                    ),
                    Text(
                      item.comments.toString(),
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
                LikeButton(
                  size: 20.0,
                  isLiked: item.isFavorite,
                  likeCount: item.favorites,
                  countBuilder: (int count, bool isLiked, String text) {
                    var color = isLiked ? Colors.pinkAccent : Colors.grey;
                    Widget result;
                    if (count == 0) {
                      result = Text(
                        'love',
                        style: TextStyle(color: color),
                      );
                    } else {
                      result = Text(
                        count >= 1000
                            ? (count / 1000.0).toStringAsFixed(1) + 'k'
                            : text,
                        style: TextStyle(color: color),
                      );
                    }
                    return result;
                  },
                  likeCountAnimationType: item.favorites < 1000
                      ? LikeCountAnimationType.part
                      : LikeCountAnimationType.none,
                  onTap: (bool isLiked) {
                    return onLikeButtonTap(isLiked, item);
                  },
                ),
              ],
            ),
          ),
        )
      ],
    ),
  );
}

Widget buildWaterfallFlowItem(BuildContext c, TuChongItem item, int index,
    {bool konwSized = true}) {
  final fontSize = 12.0;

  Widget image = Stack(
    children: <Widget>[
      ExtendedImage.network(
        item.imageUrl,
        shape: BoxShape.rectangle,
        clearMemoryCacheWhenDispose: true,
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
        loadStateChanged: (value) {
          if (value.extendedImageLoadState == LoadState.loading) {
            Widget loadingWidget = Container(
              alignment: Alignment.center,
              color: Colors.grey.withOpacity(0.8),
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation(Theme.of(c).primaryColor),
              ),
            );
            if (!konwSized) {
              //todo: not work in web
              loadingWidget = AspectRatio(
                aspectRatio: 1.0,
                child: loadingWidget,
              );
            }
            return loadingWidget;
          } else if (value.extendedImageLoadState == LoadState.completed) {
            item.imageRawSize = Size(
                value.extendedImageInfo.image.width.toDouble(),
                value.extendedImageInfo.image.height.toDouble());
          }
          return null;
        },
      ),
      Positioned(
        top: 5.0,
        right: 5.0,
        child: Container(
          padding: EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.6),
            border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.0),
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: Text(
            '${index + 1}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, color: Colors.white),
          ),
        ),
      )
    ],
  );
  if (konwSized) {
    image = AspectRatio(
      aspectRatio: item.imageSize.width / item.imageSize.height,
      child: image,
    );
  } else if (item.imageRawSize != null) {
    image = AspectRatio(
      aspectRatio: item.imageRawSize.width / item.imageRawSize.height,
      child: image,
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      image,
      SizedBox(
        height: 5.0,
      ),
      buildTagsWidget(item),
      SizedBox(
        height: 5.0,
      ),
      buildBottomWidget(item),
    ],
  );
}

Widget buildTagsWidget(
  TuChongItem item, {
  int maxNum = 6,
}) {
  final fontSize = 12.0;
  return Wrap(
      runSpacing: 5.0,
      spacing: 5.0,
      children: item.tags.take(maxNum).map<Widget>((tag) {
        final color = item.tagColors[item.tags.indexOf(tag)];
        return Container(
          padding: EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.0),
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: Text(
            tag,
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: fontSize,
                color: color.computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black),
          ),
        );
      }).toList());
}

Widget buildBottomWidget(TuChongItem item, {bool showAvatar = true}) {
  final fontSize = 12.0;
  return Row(
    children: <Widget>[
      showAvatar
          ? ExtendedImage.network(
              item.avatarUrl,
              width: 25.0,
              height: 25.0,
              shape: BoxShape.circle,
              //enableLoadState: false,
              border:
                  Border.all(color: Colors.grey.withOpacity(0.4), width: 1.0),
              loadStateChanged: (state) {
                if (state.extendedImageLoadState == LoadState.completed) {
                  return null;
                }
                return Image.asset(
                  'assets/avatar.jpg',
                  package: 'flutter_candies_demo_library',
                );
              },
            )
          : Container(),
      Expanded(
        child: Container(),
      ),
      Row(
        children: <Widget>[
          Icon(
            Icons.comment,
            color: Colors.amberAccent,
            size: 18.0,
          ),
          SizedBox(
            width: 3.0,
          ),
          Text(
            item.comments.toString(),
            style: TextStyle(color: Colors.black, fontSize: fontSize),
          )
        ],
      ),
      SizedBox(
        width: 3.0,
      ),
      LikeButton(
        size: 18.0,
        isLiked: item.isFavorite,
        likeCount: item.favorites,
        countBuilder: (int count, bool isLiked, String text) {
          var color = isLiked ? Colors.pinkAccent : Colors.grey;
          Widget result;
          if (count == 0) {
            result = Text(
              'love',
              style: TextStyle(color: color, fontSize: fontSize),
            );
          } else {
            result = Text(
              count >= 1000 ? (count / 1000.0).toStringAsFixed(1) + 'k' : text,
              style: TextStyle(color: color, fontSize: fontSize),
            );
          }
          return result;
        },
        likeCountAnimationType: item.favorites < 1000
            ? LikeCountAnimationType.part
            : LikeCountAnimationType.none,
        onTap: (bool isLiked) {
          return onLikeButtonTap(isLiked, item);
        },
      ),
    ],
  );
}
