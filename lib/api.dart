import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project1/notify_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static Future<List<NotifyModel>> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String uuidValue = prefs.getString('uuid') ?? '';
    String subsValue = prefs.getString('subs') ?? '';
    String catValue = prefs.getString('ids') ?? '';

    print('Funcion JSON');

    //String link =
    //  'https://torellojove.cat/webnova/app/push.php?uuid=$uuidValue&subs=$subsValue&cat=$catValue';

    String link = 'https://torellojove.cat/webnova/app/test.php';

    link = link.replaceAll('"', '');

    print('link: $link');

    var request = Request('GET', Uri.parse(link));

    print('idsjson: ' + uuidValue);
    print('uuidjson: ' + catValue);

    //String url = "https://torellojove.cat/webnova/app/push.php?uuid="+Wuuid+"&subs="+Wsubs+"&cat="+Wids;

    StreamedResponse response = await request.send();

    List<NotifyModel> data = [];

    try {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(await response.stream.bytesToString());
        data = List.generate(
            jsonData.length, (index) => NotifyModel.fromJson(jsonData[index]));

        return data;
      }
      throw Exception(response.reasonPhrase);
    } catch (e) {
      print(e);
      return data;
    }
  }

  Future<String?> getImageFromApiAndShowNotification(String url) async {
    var response = await get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Image downloaded successfully
      // print(filePath);
      return await saveImageToTemporaryDirectory(response.bodyBytes);
    } else {
      // Failed to download image
      // Handle error
      return null;
    }
  }

  Future<String> saveImageToTemporaryDirectory(List<int> imageBytes) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    String imagePath = '$tempPath/ico4.png';
    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageBytes);
    return imagePath;
  }
}
