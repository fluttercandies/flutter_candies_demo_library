import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker_saver/image_picker_saver.dart';

///
///  create by zmtzawqlp on 2020/1/31
///
double initScale({Size imageSize, Size size, double initialScale}) {
  var n1 = imageSize.height / imageSize.width;
  var n2 = size.height / size.width;
  if (n1 > n2) {
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    //final Size sourceSize = fittedSizes.source;
    Size destinationSize = fittedSizes.destination;
    return size.width / destinationSize.width;
  } else if (n1 / n2 < 1 / 4) {
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    //final Size sourceSize = fittedSizes.source;
    Size destinationSize = fittedSizes.destination;
    return size.height / destinationSize.height;
  }

  return initialScale;
}


///save netwrok image to photo
Future<bool> saveNetworkImageToPhoto(String url, {bool useCache: true}) async {
  if (kIsWeb) return false;
  var data = await getNetworkImageData(url, useCache: useCache);
  var filePath = await ImagePickerSaver.saveFile(fileData: data);
  return filePath != null && filePath != "";
}
