import 'package:flutter/foundation.dart';
import 'package:flutter_candies_demo_library/src/data/mock_data.dart';
import 'package:flutter_candies_demo_library/src/data/tu_chong_source.dart';
import 'package:http_client_helper/http_client_helper.dart';
import 'dart:async';
import 'dart:convert';

import 'package:loading_more_list_library/loading_more_list_library.dart';

Future<bool> onLikeButtonTap(bool isLiked, TuChongItem item) {
  ///send your request here
  return Future<bool>.delayed(const Duration(milliseconds: 50), () {
    item.isFavorite = !item.isFavorite;
    item.favorites = item.isFavorite ? item.favorites + 1 : item.favorites - 1;
    return item.isFavorite;
  });
}

class TuChongRepository extends LoadingMoreBase<TuChongItem> {
  int pageindex = 1;
  bool _hasMore = true;
  bool forceRefresh = false;
  @override
  bool get hasMore => (_hasMore && length < 300) || forceRefresh;

  @override
  Future<bool> refresh([bool clearBeforeRequest = false]) async {
    _hasMore = true;
    pageindex = 1;
    //force to refresh list when you don't want clear list before request
    //for the case, if your list already has 20 items.
    forceRefresh = !clearBeforeRequest;
    var result = await super.refresh(clearBeforeRequest);
    forceRefresh = false;
    return result;
  }

  @override
  Future<bool> loadData([bool isloadMoreAction = false]) async {
    var url = '';
    if (isEmpty) {
      url = 'https://api.tuchong.com/feed-app';
    } else {
      final lastPostId = this[length - 1].postId;
      url =
          'https://api.tuchong.com/feed-app?post_id=$lastPostId&page=$pageindex&type=loadmore';
    }
    var isSuccess = false;
    try {
      //to show loading more clearly, in your app,remove this
      await Future.delayed(Duration(milliseconds: 500));
      List<TuChongItem> feedList;
      if (!kIsWeb) {
        final result = await HttpClientHelper.get(url);
        feedList = TuChongSource.fromJson(json.decode(result.body)).feedList;
      } else {
        feedList = mockSource.feedList
            .getRange(length, length + 20)
            .toList();
      }

      if (pageindex == 1) {
        clear();
      }

      for (var item in feedList) {
        if (item.hasImage && !contains(item) && hasMore) add(item);
      }

      _hasMore = feedList.isNotEmpty;
      pageindex++;
//      this.clear();
//      _hasMore=false;
      isSuccess = true;
    } catch (exception, stack) {
      isSuccess = false;
      print(exception);
      print(stack);
    }
    return isSuccess;
  }
}
