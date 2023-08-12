import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

enum Redirects { noRedirect, builtIn, manual }

class Session {
  final HttpClient _client = HttpClient();
  final Map<String, String> _cookies = {};
  final Map<String, String> _headers = {};

  Session();

  void setcookies(Map<String, String> cookies) {
    Map<String, String> temp = {};
    cookies.keys.forEach((x) => temp[x.toUpperCase()] = cookies[x]!);
    cookies = temp;
    if (cookies.isNotEmpty) {
      String upd(String key, String value) {
        if (cookies.containsKey(key)) {
          return cookies[key]!;
        }
        return value;
      }

      _cookies.updateAll(upd);
      cookies.keys.forEach((x) => {
            if (!_cookies.containsKey(x)) {_cookies[x] = cookies[x]!}
          });
    }
  }

  void setheaders(Map<String, String> headers) {
    Map<String, String> temp = {};
    headers.keys.forEach((x) => temp[x.toUpperCase()] = headers[x]!);
    headers = temp;
    if (headers.isNotEmpty) {
      String upd(String key, String value) {
        if (headers.containsKey(key)) {
          return headers[key]!;
        }
        return value;
      }

      _headers.updateAll(upd);
      headers.keys.forEach((x) => {
            if (!_headers.containsKey(x)) {_headers[x] = headers[x]!}
          });
    }
  }

  Future<HttpClientResponse> gets(String durl, Redirects redirect) async {
    final url = Uri.parse(durl);
    final request = await _client.getUrl(url);
    if (redirect == Redirects.builtIn) {
      request.followRedirects = true;
    } else {
      request.followRedirects = false;
    }
    request.headers.remove('User-Agent', 'Dart/3.0 (dart:io)');
    if (_cookies.isNotEmpty) {
      request.cookies.addAll(
          _cookies.entries.map((entry) => Cookie(entry.key, entry.value)));
    }
    if (_headers.isNotEmpty) {
      _headers.forEach((x, y) => request.headers.add(x, y));
    }

    final response = await request.close();
    if (response.statusCode == 302 && redirect == Redirects.manual) {
      log("Manula redirection to -> ${response.headers['location']![0]} as inbuilt redirect is crappy..");
      return await gets(response.headers['location']![0], Redirects.manual);
    }
    response.cookies.forEach((cookie) {
      _cookies[cookie.name] = cookie.value;
    });
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

    response.cookies.forEach((cookie) {
      _cookies[cookie.name] = cookie.value;
    });
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
  Session client = Session();
  Run() {
    client.setheaders(headers);
  }

  Future<dynamic>? youtube(String url) async {
    await client.gets("https://youtube.com", Redirects.builtIn);
    HttpClientResponse res = await client.gets(url, Redirects.builtIn);

    List<String> sepatators = [
      '"adaptiveFormats":',
     '},"playerAds":'
    ];

    if (res.statusCode == 200) {
      Map urls = {
        "urls": {"videos": [], "audios": [], "others": []}
      };
      String content = await res.transform(utf8.decoder).join();
      try {
        String b = content.split(sepatators[0])[1];
        b = b.split(sepatators[1])[0];
        dynamic dict = jsonDecode(b);
        for (var x in dict) {
          if (x["mimeType"].split("/")[0] == "video") {
            urls["urls"]["videos"].add(x["url"]);
          } else if (x["mimeType"].split("/")[0] == "audio") {
            urls["urls"]["audios"].add(x["url"]);
          } else {
            urls["urls"]["others"].add(x["urls"]);
          }
        }
        return urls;
      } catch (e) {
        log("$e");
        return {"error": "$e"};
      }
    } else {
      return {"error": "400"};
    }
  }

  Future<void> tiktokDownload(String url) async {
    Map<String, String> headers = {
      'authority': 'v16-webapp-prime.tiktok.com',
      'origin': 'https://www.tiktok.com',
      'range': 'bytes=0-',
      'referer': 'https//www.tiktok.com/',
      'sec-fetch-dest': 'video',
    };
    File file = File("test.mp4");
    client.setheaders(headers);
    HttpClientResponse res = await client.gets(url, Redirects.noRedirect);
    if (res.statusCode == 200 || res.statusCode == 206) {
      await res.pipe(file.openWrite());
      log("TikTok Downloaded to file");
    } else {
      log("TikTok Download Failed ${res.statusCode}");
    }
  }

  Future<Map>? tiktok(String url) async {
    await client.gets("https://www.tiktok.com/", Redirects.noRedirect);
    HttpClientResponse res = await client.gets(url, Redirects.noRedirect);
    if (res.statusCode == 200) {
      String content = await res.transform(utf8.decoder).join();
      try {
        Map urls = {
          "urls": {"videos": [], "audios": []}
        };
        String b = content.split('"downloadAddr":"')[1];
        b = b.split('","shareCover"')[0];
        b = b.replaceAll(RegExp(r"\\u002F"), "/");
        log("Downloadgin .. .. .");
        await tiktokDownload(b);
        urls["urls"]["videos"].add(b);
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
    String a = await res.transform(utf8.decoder).join();
    Map urls = {
      "urls": {"videos": [], "audios": []}
    };
    if (res.statusCode == 200) {
      String b = a.split(sepatators[0])[1];
      String c = b.split(sepatators[1])[0];
      List lis = jsonDecode(c);
      for (Map dic in lis) {
        if (dic["mime_type"] == "video/mp4") {
          urls["urls"]["videos"].add(dic["base_url"]);
        } else if (dic["mime_type"] == "audio/mp4") {
          urls["urls"]["audios"].add(dic["base_url"]);
        }
      }
      return urls;
    }

    return {"error": "400"};
  }

  Future<Map>? instagram(String url) async {
    HttpClientResponse res =
        await client.gets("https://www.instagram.com/tv", Redirects.builtIn);
    List<String> sepatators = ['"video_url":"', '","video_view_count"'];
    res = await client.gets(url, Redirects.builtIn);
    String a = await res.transform(utf8.decoder).join();
    Map urls = {
      "urls": {"videos": [], "audios": []}
    };
    try {
      String c = a.split(sepatators[0])[1];
      String d = c.split(sepatators[1])[0];
      urls["urls"]["video"].add(d);
      return urls;
    } catch (e) {
      log("Error from Instagram $e");
      return {"error": "$e"};
    }
  }
}

class Parse {
  Parse(this.url);
  final String url;

  Future<String> link() async {
    dynamic a = Run();
    // dynamic d = await a.youtube("https://youtu.be/hcsX5Qd2GLo");
    // dynamic d = await a.tiktok("https://www.tiktok.com/@ggkaam610/video/7260425464211098898?is_from_webapp=1&sender_device=pc");
    dynamic d =
        await a.facebook("https://www.facebook.com/watch/?v=632518552179712");
    for (var url in d["urls"]["videos"]) {
      print("\n URLS:- [+]\n\t $url");
    }
    return "";
  }
}
