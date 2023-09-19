import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

//var log = print;
var print = log;

enum Redirects { noRedirect, builtIn, manual }

String cleaner(String str) {
  Map<String, String> utfs = {
    "\\u002F": "/",
    "\\u0026": "&",
    "\\u003D": "=",
    "\\u0021": "!",
    "\\u0022": "\"",
    "\\u0023": "#",
    "\\u0024": "\$",
    "\\u0025": "%",
    "\\u0028": "(",
    "\\u0029": ")",
    "\\u002A": "*",
    "\\u002B": "+",
    "\\u002C": ",",
    "\\u002D": "-",
    "\\u002E": ".",
    "\\u003A": ":",
    "\\u003B": ";",
    "\\u003C": "<",
    "\\u003E": ">",
    "\\u003F": "?",
    "\\u0040": "@",
    "\\u005B": "[",
    "\\u005C": "\\",
    "\\u005D": "]",
    "\\u005E": "^",
    "\\u005F": "_",
    "\\u0060": "`",
    "\\u007B": "{",
    "\\u007C": "|",
    "\\u007D": "}",
    "\\u007E": "~",
  };
  for (var ky in utfs.keys) {
    str = str.replaceAll(ky, utfs[ky]!);
  }
  return str;
}

class Session {
  final HttpClient _client = HttpClient();
  final Map<String, String> _cookies = {};
  final Map<String, String> _headers = {};

  Session();

  void setcookies(Map<String, String> cookies) {
    for (var x in cookies.keys) {
      String xt = x.toUpperCase();
      if (!_cookies.containsKey(xt)) {
        _cookies[xt] = cookies[x]!;
      }
    }
  }

  void setheaders(Map<String, String> headers) {
    for (var x in headers.keys) {
      String xt = x.toUpperCase();
      if (!_headers.containsKey(xt)) {
        _headers[xt] = headers[x]!;
      }
    }
  }

  Future<HttpClientResponse> gets(String durl, Redirects redirect) async {
    var url = Uri.parse(durl);
    print("(Session) Connecting to Host ... $durl");
    final request = await _client.getUrl(url);
    print("(Session) Connected to Host ... $durl");
    if (redirect == Redirects.builtIn) {
      request.followRedirects = true;
    } else {
      request.followRedirects = false;
    }
    print("Following Url Redirec? ${request.followRedirects}");
    request.headers.remove('User-Agent', 'Dart/3.0 (dart:io)');
    if (_cookies.isNotEmpty) {
      request.cookies.addAll(
          _cookies.entries.map((entry) => Cookie(entry.key, entry.value)));
    }
    if (_headers.isNotEmpty) {
      _headers.forEach((x, y) => request.headers.add(x, y));
    }
    var response = await request.close();
    print("Response Headers\n\\\t\n\t\\");
    print(response.headers.toString());

    for (var cookie in response.cookies) {
      _cookies[cookie.name] = cookie.value;
    }

    if (response.statusCode == 302 && redirect == Redirects.manual) {
      String temp = response.headers['location']![0];
      if (temp.startsWith("/")) {
        return await gets(durl, Redirects.manual);
      } else {
        return await gets(temp, Redirects.manual);
      }
    }

    return response;
  }

  Future<HttpClientResponse> posts(String durl, int redirect) async {
    final url = Uri.parse(durl);
    final request = await _client.postUrl(url);
    request.followRedirects = true;
    if (_cookies.isNotEmpty) {
      request.cookies.addAll(
          _cookies.entries.map((entry) => Cookie(entry.key, entry.value)));
    }
    if (_headers.isNotEmpty) {
      _headers.forEach((x, y) => request.headers.add(x, y));
    }

    final response = await request.close();

    for (var cookie in response.cookies) {
      _cookies[cookie.name] = cookie.value;
    }
    return response;
  }

  void close() {
    _client.close();
  }
}

class Run {
  Map<String, String> headers = {
    'accept': '*/*',
    "accept-encoding": "utf-8",
    "accept-language": "en-US,en;q=0.9",
    "dnt": "1",
    'scheme': 'https',
    "sec-fetch-dest": "document",
    "sec-fetch-user": "?1",
    'sec-ch-ua': '"Not/A)Brand";v="99", "Brave";v="115", "Chromium";v="115"',
    'Cache-Control': 'max-age=0',
    "upgrade-insecure-requests": "1",
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-site',
    'sec-gpc': '1',
    "user-agent":
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Safari/537.36",
  };

  String saveFileName = "final.mp4";
  String? downloadUrl;
  Map urls = {
    "urls": {
      "videos": [],
      "audios": [],
      "others": [],
      "title": "",
      "of": "leyuskc"
    }
  };

  Session client = Session();
  Run() {
    client.setheaders(headers);
  }

  Future<Map>? youtube(String url) async {
    await client.gets("https://youtube.com", Redirects.builtIn);
    HttpClientResponse res = await client.gets(url, Redirects.builtIn);

    List<String> sepatators = ['"adaptiveFormats":', "}]", '},"playerAds":'];

    if (res.statusCode == 200) {
      String content = await res.transform(utf8.decoder).join();
      try {
        String b = content.split(sepatators[0])[1];
        b = "${b.split(sepatators[1])[0]}}]";
        dynamic dict = jsonDecode(b);
        for (var x in dict) {
          if (x["mimeType"].split("/")[0] == "video") {
            urls["urls"]["videos"].add(x);
          } else if (x["mimeType"].split("/")[0] == "audio") {
            urls["urls"]["audios"].add(x);
          } else {
            urls["urls"]["others"].add(x);
          }
        }
        String title = content
            .split(RegExp(r'<title[^>]*>'))[1]
            .split("</title>")[0]
            .replaceAll(RegExp(r"[^a-zA-Z0-9]"), "-")
            .replaceAll(RegExp(r"[-]+"), "-");
        if (title.length > 10) {
          title = title.substring(0, 10);
        }
        urls["urls"]["title"] = "${title}-youtube";
        return urls;
      } catch (e) {
        print("(youtbue) $e");
        return {"error": "$e"};
      }
    } else {
      return {"error": "400"};
    }
  }

  Future<void> download() async {
    print("(Run.download) Statring.... ");

    if (saveFileName.isEmpty || downloadUrl == null) {
      return;
    }
    print("(Run.download) Opening.... $saveFileName");
    File file = File(saveFileName);
    print("(Run.download) Connecting.... $downloadUrl");
    HttpClientResponse res = await client.gets(downloadUrl!, Redirects.builtIn);

    if (res.statusCode == 200 || res.statusCode == 206) {
      print("(Run.download) Writing.... $saveFileName");
      await res.pipe(file.openWrite());
    } else {
      log("Server responsed with ${res.statusCode}");
      return;
    }
    print("(Downloader) Completed Downloading video");
  }

  Future<Map>? tiktok(String url) async {
    await client.gets("https://www.tiktok.com/", Redirects.builtIn);
    HttpClientResponse res = await client.gets(url, Redirects.builtIn);
    List<String> sepatators = ['"playAddr":"', '","downloadAddr"'];
    if (res.statusCode == 200) {
      String content = await res.transform(utf8.decoder).join();
      print("content");
      try {
        String b = content.split(sepatators[0])[1];
        b = b.split(sepatators[1])[0];
        b = cleaner(b);
        String title = content
            .split(RegExp(r'<title[^>]*>'))[1]
            .split("</title>")[0]
            .replaceAll(RegExp(r"[^a-zA-Z0-9]"), "-")
            .replaceAll(RegExp(r"[-]+"), "-");
        title = "${title}-tiktok";
        if (title.length > 10) {
          title = title.substring(0, 10);
        }
        urls["urls"]["title"] = title;
        client.setheaders({
          'authority': 'v16-webapp-prime.tiktok.com',
          'origin': 'https://www.tiktok.com',
          'range': 'bytes=0-',
          'referer': 'https//www.tiktok.com/',
          'sec-fetch-dest': 'video',
        });
        print("TikTok is wokring. .. . . . .");
        urls["urls"]["videos"].add({"url": b, "quality": "hd-no-watermark"});
        return urls;
      } catch (e) {
        log("Their Was And Error $e");
        return {"error": "$e"};
      }
    }
    return {"error": "404"};
  }

  Future<Map>? facebook(String url) async {
    Map<String, String> headers = {
      'authority': 'www.facebook.com',
      'method': 'GET',
      'accept':
          'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    };
    List<String> sepatators = [
      '"all_video_dash_prefetch_representations":[{"representations":',
      ',"video_id"'
    ];
    client.setheaders(headers);
    HttpClientResponse res = await client.gets(url, Redirects.manual);
    String content = await res.transform(utf8.decoder).join();

    if (res.statusCode == 200) {
      String b = content.split(sepatators[0])[1];
      String c = b.split(sepatators[1])[0];
      List lis = jsonDecode(c);
      for (var dic in lis) {
        var t = dic;
        t["url"] = t["base_url"];
        if (dic["mime_type"] == "video/mp4") {
          t["quality"] = '${t["height"]}x${t["width"]}';
          urls["urls"]["videos"].add(t);
        } else if (dic["mime_type"] == "audio/mp4") {
          t["quality"] = '${t["bandwidth"] / 1000}kHz';
          urls["urls"]["audios"].add(t);
        }
      }
      String title = content
          .split(RegExp(r'<title[^>]*>'))[1]
          .split("</title>")[0]
          .replaceAll(RegExp(r"[^a-zA-Z0-9]"), "-")
          .replaceAll(RegExp(r"[-]+"), "-");
      title = "${title}-facebook";
      if (title.length > 10) {
        title = title.substring(0, 10);
      }
      urls["urls"]["title"] = title;
      return urls;
    }

    return {"error": "400"};
  }

  Future<Map>? instagram(String url) async {
    HttpClientResponse res = await client.gets(url, Redirects.builtIn);
    String content = await res.transform(utf8.decoder).join();
    String title = content
        .split(RegExp(r'<title[^>]*>'))[1]
        .split("</title>")[0]
        .replaceAll(RegExp(r"[^a-zA-Z0-9]"), "-")
        .replaceAll(RegExp(r"[-]+"), "-");
    if (title.length > 10) {
      title = title.substring(0, 10);
    }
    List<String> sepatators = ['"video_url":"', '","video_view_count"'];
    String urlId = url.split("/")[4];
    String api =
        "https://www.instagram.com/graphql/query/?query_hash=b3055c01b4b222b8a47dc12b090e4e64&variables=%7B%22child_comment_count%22%3A3%2C%22fetch_comment_count%22%3A40%2C%22has_threaded_comments%22%3Atrue%2C%22parent_comment_count%22%3A24%2C%22shortcode%22%3A%22$urlId%22%7D";

    res = await client.gets(api, Redirects.builtIn);
    content = await res.transform(utf8.decoder).join();

    try {
      String c = content.split(sepatators[0])[1];
      String d = c.split(sepatators[1])[0];

      d = cleaner(d);
      urls["urls"]["videos"].add({"url": d, "quality": "hd"});

      title = "${title}-instagram";
      urls["urls"]["title"] = title;
      return urls;
    } catch (e) {
      log("Error from Instagram $e");
      return {"error": "$e"};
    }
  }

  Future<Map>? hlsParser(String fileData, String baseUrl, String title) async {
    print("(hlsParser) Ok I am here.... with $baseUrl");
    String before = "";
    for (var line in fileData.split("\n")) {
      if (line.toUpperCase() == "#EXTM3U") {
        continue;
      } else if (line.startsWith("#")) {
        if (line.startsWith("#EXT-X-STREAM-INF:")) {
          before = line;
        } else {
          if (line.contains("TYPE=AUDIO")) {
            Map t = {
              "url": "$baseUrl/${line.split('URI="')[1].split('.')[0]}.aac",
              "quality": "${line.split("HLS_AUDIO_")[1].split(".")[0]}kHz",
            };
            urls["urls"]["audios"].add(t);
          }
        }
      } else {
        if (before.isNotEmpty) {
          Map t = {
            "url": "$baseUrl/${line.split('.')[0]}.ts",
            "quality": before.split("RESOLUTION=")[1].split(",")[0],
          };
          urls["urls"]["videos"].add(t);
        }
      }
    }
    print("(Reddit HLS Downloader ) $urls");

    title = "${title}-reddit";
    urls["urls"]["title"] = title;
    return urls;
  }

  Future<Map>? reddit(String url) async {
    List<String> sepatators = [' src="https://v.redd.it/', '"'];
    String baseUrl = "https://v.redd.it";
    HttpClientResponse res =
        await client.gets("https://www.reddit.com", Redirects.builtIn);
    print("(reddit) Calling hls Server...");
    res = await client.gets(url, Redirects.builtIn);
    print("(reddit) Called hls Server...");
    String content = await res.transform(utf8.decoder).join();
    String vidId = content.split(sepatators[0])[1].split(sepatators[1])[0];
    String newUrl = "$baseUrl/$vidId/";
    print("(reddit) Calling files hls Server...");
    res = await client.gets(newUrl, Redirects.builtIn);
    print("(reddit) Called files hls Server...");
    String hlsPlayList = await res.transform(utf8.decoder).join();
    print("(reddit) Splitting ...");
    String title = "video_from_reddit_by_leyuskc";
    try {
      title = content
          .split('<shreddit-title title="')[1]
          .split('">')[0]
          .replaceAll(RegExp(r"[^a-zA-Z0-9]"), "-")
          .replaceAll(RegExp(r"[-]+"), "-");
      if (title.length > 10) {
        title = title.substring(0, 10);
      }
    } catch (e) {
      print("(reddit) error in reddit $e");
    }
    print("(reddit) returining hls...");
    return await hlsParser(
        hlsPlayList, "$baseUrl/${vidId.split('/')[0]}", title)!;
  }

  Future<Map>? twitter(String url) async {
    HttpClientResponse res =
        await client.gets("https://www.twitter.com", Redirects.manual);
    res = await client.gets(url, Redirects.manual);
    print("${res.statusCode}");
    print("Clientes Cookies Now :- ${client._cookies}");
    Map dic = jsonDecode(await res.transform(utf8.decoder).join());
    print("${dic}");
    // print(res);
    // print(res.headers);
    return {};
  }

  Future<Map>? determine(String url) async {
    String temp = url;
    if (url.contains("www.")) {
      url = url.replaceFirstMapped("www.", (x) => "");
    }
    if(url.contains("vt.")){
      url = url.replaceFirstMapped("vt.", (x) => "");
    }
    url = url.split("https://")[1];
    print(url);
    switch (url.split(".")[0]) {
      case "youtube" || "youtu":
        print("Calling Youtube....");
        urls["of"] = "youtube";
        return await youtube(temp)!;
      case "tiktok":
        print("Calling TikTok....");
        urls["of"] = "tiktok";
        return await tiktok(temp)!;
      case "facebook" || "fb":
        print("Calling Facebook....");
        urls["of"] = "facebook";
        return await facebook(temp)!;
      case "instagram":
        print("Calling Instagram....");
        urls["of"] = "instagram";
        return await instagram(temp)!;
      case "reddit":
        print("Calling Reddit....");
        urls["of"] = "reddit";
        return await reddit(temp)!;
      case "twitter":
        print("Calling Twitter....");
        urls["of"] = "twitter";
        String st = """
        ╔═════════════════════════════════════╗
        ║ Twitter Is not implemnted For Now   ║
        ╚═════════════════════════════════════╝
        """;
        throw st;
      // return await twitter(temp)!;
      default:
        print("Bad Url Format ");
        return {"error": "Bad Url"};
    }
  }
}

class Parse {
  Parse();
  Future<Map> linkGen(String url) async {
    Run a = Run();
    dynamic d = await a.determine(url);
    return d;
  }
}

// Rough ... . .. .

// List<String> urls = [
//   "https://youtu.be/hcsX5Qd2GLo",
//   "https://www.tiktok.com/@miraculous_bogaboo000/video/7249121848166731013?is_from_webapp=1",
//   "https://www.facebook.com/watch/?v=632518552179712",
//   "https://www.instagram.com/reel/CpKyiMhpM6M/?utm_source=ig_web_button_share_sheet",
// ];
// for (var t in urls) {
//   dynamic a = Run();
//   dynamic d = await a.determine(t);
//   if (d.containsKey("urls")) {
//     for (var url in d["urls"]["videos"]) {
//       print("\n URLS:- [+]\n\t $url");
//     }
//   }
// }
