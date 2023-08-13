import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

 var log = print;
//var print = log;

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
    var url = Uri.parse(durl);
    print("(Session) Connecting to Host ... $durl");
    final request = await _client.getUrl(url);
    print("(Session) Connected to Host ... $durl");
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

    var response = await request.close();
    response.cookies.forEach((cookie) {
      _cookies[cookie.name] = cookie.value;
    });

    if (response.statusCode == 302 && redirect == Redirects.manual) {
        String temp = response.headers['location']![0];
        if(temp.startsWith("/")){
            return await gets(durl, Redirects.manual);
        }
        else{
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

  Future<Map>? youtube(String url) async {
    await client.gets("https://youtube.com", Redirects.builtIn);
    HttpClientResponse res = await client.gets(url, Redirects.builtIn);

    List<String> sepatators = ['"adaptiveFormats":', '},"playerAds":'];

    if (res.statusCode == 200) {
      Map urls = {"urls": {"videos": [], "audios": [], "others": []}};
      String content = await res.transform(utf8.decoder).join();
      try {
        String b = content.split(sepatators[0])[1];
        b = b.split(sepatators[1])[0];
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
        return urls;
      } catch (e) {
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
    url = url.replaceAll("tiktok_m", "unwatermarked");
    File file = File("test.mp4");
    client.setheaders(headers);
    HttpClientResponse res = await client.gets(url, Redirects.builtIn);
    if (res.statusCode == 200 || res.statusCode == 206) {
      await res.pipe(file.openWrite());
    } else {
      log("Error Writing to File ??");
    }
  }

  Future<void> download(String fileName,String url) async{
    print("(Downloader:) I got [+] $url");
    File file = File(fileName);
    HttpClientResponse res = await client.gets(url,Redirects.builtIn);
    if (res.statusCode == 200 || res.statusCode == 206) {
      await res.pipe(file.openWrite());

    } else {
       log("Server responsed with ${res.statusCode} for \n\t(URL)[+]$url");
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
      try {
        Map urls = {"urls": {"videos": [], "audios": [], "others": []}};
        String b = content.split(sepatators[0])[1];
        b = b.split(sepatators[1])[0];
        b = cleaner(b);
        await tiktokDownload(b);
        b = b.replaceAll("tiktok_m", "unwatermarked");
        urls["urls"]["videos"].add({"url":b,"quality":"hd"});
        return urls;
      } catch (e) {
        log("Their Was And Error $e");
        return {"error": "$e"};
      }
    }
    return {"error": "404"};
  }

  Future<Map>? facebook(String url) async {
    print("(FaceBook:) I got [+] $url");
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
    print("${client._headers}");
    print("From (Facebook) ${client._cookies}");
    HttpClientResponse res = await client.gets(url, Redirects.manual);
    print("Here hai tw");
    String a = await res.transform(utf8.decoder).join();
    Map urls = {"urls": {"videos": [], "audios": [], "others": []}};
    if (res.statusCode == 200) {
      String b = a.split(sepatators[0])[1];
      String c = b.split(sepatators[1])[0];
      List lis = jsonDecode(c);
      for (var dic in lis) {
        var t = dic;
        t["url"] = t["base_url"];
        t["quality"] = "hd";
        if (dic["mime_type"] == "video/mp4") {
          urls["urls"]["videos"].add(t);
        } else if (dic["mime_type"] == "audio/mp4") {
          urls["urls"]["audios"].add(t);
        }
      }
      print("Sending data hai tw ${urls['urls']['videos'][0]}");
      return urls;
    }

    return {"error": "400"};
  }

  Future<Map>? instagram(String url) async {
    HttpClientResponse res =
        await client.gets("https://www.instagram.com/tv", Redirects.builtIn);
    List<String> sepatators = ['"video_url":"', '","video_view_count"'];
    String urlId = url.split("/")[4];
    String api =
        "https://www.instagram.com/graphql/query/?query_hash=b3055c01b4b222b8a47dc12b090e4e64&variables=%7B%22child_comment_count%22%3A3%2C%22fetch_comment_count%22%3A40%2C%22has_threaded_comments%22%3Atrue%2C%22parent_comment_count%22%3A24%2C%22shortcode%22%3A%22$urlId%22%7D";

    res = await client.gets(api, Redirects.builtIn);
    String a = await res.transform(utf8.decoder).join();
    Map urls = {"urls": {"videos": [], "audios": [], "others": []}};
    try {
      String c = a.split(sepatators[0])[1];
      String d = c.split(sepatators[1])[0];

      d = cleaner(d);
      urls["urls"]["videos"].add({"url":d,"quality":"hd"});
      return urls;
    } catch (e) {
      log("Error from Instagram $e");
      return {"error": "$e"};
    }
  }

  Future<Map>? hlsParser(String fileData,String baseUrl) async{
    Map urls = {"urls": {"videos": [], "audios": [], "others": []}};
    String before = "";
    for(var line in fileData.split("\n")){
        if(line.toUpperCase() == "#EXTM3U"){
            continue;
        }
        else if(line.startsWith("#")){
            if(line.startsWith("#EXT-X-STREAM-INF:")){
                before = line;
            }
            else{
                if(line.contains("TYPE=AUDIO")){
                    Map t= {
                    "url":"$baseUrl/${line.split('URI="')[1].split('.')[0]}.aac",
                    "quality": "${line.split("HLS_AUDIO_")[1].split(".")[0]}kHz",
                    };     
                    urls["urls"]["audios"].add(t);
                }
            }
        }
        else {
            if(before.isNotEmpty){
                Map t= {
                    "url":"$baseUrl/${line.split('.')[0]}.ts",
                    "quality": before.split("RESOLUTION=")[1].split(",")[0],
                };     
                urls["urls"]["videos"].add(t);
            }
        }
    }
    return urls;
  }

  Future<Map>? reddit(String url) async {
    List<String> sepatators = [' src="https://v.redd.it/', '"'];
    String baseUrl = "https://v.redd.it";
    HttpClientResponse res = await client.gets("https://www.reddit.com", Redirects.builtIn);
    res = await client.gets(url, Redirects.builtIn);
    String a = await res.transform(utf8.decoder).join();
    String vidId = a.split(sepatators[0])[1].split(sepatators[1])[0];
    String newUrl = "$baseUrl/$vidId/";
    res  = await client.gets(newUrl,Redirects.builtIn);
    String hlsPlayList = await res.transform(utf8.decoder).join();
    return await hlsParser(hlsPlayList,"$baseUrl/${vidId.split('/')[0]}")!;
  }

  Future<Map>? twitter(String url) async {
    HttpClientResponse res = await client.gets("https://www.twitter.com", Redirects.manual);
    res = await client.gets(url, Redirects.manual);
    print("${res.statusCode}");
    print("Clientes Cookies Now :- ${client._cookies}");
    Map dic =jsonDecode(await res.transform(utf8.decoder).join());
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
    url = url.split("https://")[1];
    switch (url.split(".")[0]) {
      case "youtube" || "youtu":
        print("Calling Youtube....");
        return await youtube(temp)!;
      case "tiktok":
        print("Calling TikTok....");
        return await tiktok(temp)!;
      case "facebook" || "fb":
        print("Calling Facebook....");
        return await facebook(temp)!;
      case "instagram":
        print("Calling Instagram....");
        return await instagram(temp)!;
      case "reddit":
        print("Calling Reddit....");
        return await reddit(temp)!;
      case "twitter":
        print("Calling Twitter....");
        throw "\n\t=======================================\n\t|| Twitter Is not implemnted For Now ||\n\t=======================================\n ";
        // return await twitter(temp)!;
      default:
        print("Bad Url Format ");
        return {"error":"Bad Url"};
    }
  }
}

class Parse {
  Parse();
  Future<Map> linkGen(String url) async {
    Run a = Run();
    dynamic d = await a.determine(url);
    //     v---v---< just to be sure here
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