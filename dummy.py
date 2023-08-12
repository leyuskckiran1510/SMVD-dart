"""
Author :- Leyuskc
Github Url:- https://github.com/leyuskckiran1510/telegram

"""


import requests
from urllib.parse import unquote
import time
import itertools
from threading import Thread
import uuid
import json
from pprint import pprint


class Run:
    cok = {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "accept-encoding": "utf-8",
        "accept-language": "en-US,en;q=0.9",
        "dnt": "1",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "none",
        "sec-fetch-user": "?1",
        "sec-gpc": "1",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Safari/537.36",
    }

    def __init__(self):
        self.ses = requests.Session()
        self.ses.headers = self.cok

    def youtube(self, url):
        self.ses.get("https://youtube.com")
        res = self.ses.get(url)
        a = res.content
        text = ""
        urls_dic = {"video": {}, "audio": {}}
        try:
            b = a.decode().split('"streamingData":')
            c = b[1].split(',{"itag":251,')[0] + "]}"
            d = json.loads(c)
            for i in d["adaptiveFormats"]:
                if i["mimeType"].split("/")[0] == "video":
                    urls_dic[i["mimeType"].split("/")[0]][i["quality"]] = eval(f"unquote('{i['url']}')")
                else:
                    urls_dic[i["mimeType"].split("/")[0]][str(i["bitrate"])] = eval(f"unquote('{i['url']}')")
            return urls_dic
        except KeyError as e:
            return {
                "error": "This video requires age confirmation so; please login to youtube by yourself; can't be downloded"
            }
        except IndexError as e:
            return {"error": "It's not a valid link "}
        except Exception as e:
            id = uuid.uuid1()
            with open("errors.txt", "a") as fl:
                fl.write(f"id : {e}" + "\n" + "*" * 10 + "\n")
            return {"error": f"Their seems to be a problem contact https://t.me/leyuskc; With this id {id}"}

    def tiktok(self, url):
        self.ses.get("https://www.tiktok.com/", allow_redirects=False)
        response = self.ses.get(url, allow_redirects=False)
        try:
            a = str(response.content)
            b = a.split('"downloadAddr":"')[1]
            b = b.split('","shareCover"')[0]
            a = eval(f"unquote('{b}')")
            a = a.encode("ascii", "ignore").decode("unicode_escape")
            url = {
                "video": {"url": a},
                "audio": {
                    "Audio and video files are in same link as file is small and easy to stream": "Audio is by default in video link"
                },
            }
            return url
        except KeyError as e:
            return {
                "error": "This video requires age confirmation so; please login to youtube by yourself; can't be downloded"
            }
        except IndexError as e:
            return {"error": "It's not a valid link "}
        except Exception as e:
            id = uuid.uuid1()
            with open("errors.txt", "a") as fl:
                fl.write(f"id : {e}" + "\n" + "*" * 10 + "\n")
            return {"error": f"Their seems to be a problem contact https://t.me/leyuskc; With this id {id}"}

    def facebook(self, url):
        sepatators = ['"extensions":{"prefetch_dash_segments":', '}},"sequen']  # '",is_final":false']
        add = ['{"hello":{"hi":', "}}"]
        res = self.ses.get(url)
        a = res.text
        urls_dic = {"video": {}, "audio": {}}
        try:
            b = a.split(sepatators[0])
            c = add[0] + b[1].split(sepatators[1])[0] + "}}"
            # print(c)
            d = json.loads(c)
            for i in d["hello"]["hi"][0].keys():
                for j in d["hello"]["hi"][0][i]:
                    urls_dic[i]["url"] = j["url"]
                    break
        except KeyError as e:
            return {
                "error": "This video requires age confirmation so; please login to youtube by yourself; can't be downloded"
            }
        except IndexError as e:
            return {"error": "It's not a valid link "}
        except Exception as e:
            id = uuid.uuid1()
            with open("errors.txt", "a") as fl:
                fl.write(f"id : {e}" + "\n" + "*" * 10 + "\n")
            return {"error": f"Their seems to be a problem contact https://t.me/leyuskc; With this id {id}"}
        return urls_dic

    def instagram(self, url):
        res = self.ses.get("https://www.instagram.com/tv")
        sepatators = ['"video_url":"', '","video_view_count"']
        res = self.ses.get(url)
        a = res.text
        try:
            c = a.split(sepatators[0])[1]
            d = c.split(sepatators[1])[0]
            st = eval(f"unquote('{d}')")
            url = {
                "video": {"url": st},
                "audio": {
                    "Audio and video files are in same link as file is small and easy to stream": "Audio is by default in video link"
                },
            }
            return url
        except IndexError as e:
            return {
                "error": "Can't use same url multiple time in Short Time Interval Instagram bans IP Sorry try next url."
            }
        except Exception as e:
            id = uuid.uuid1()
            with open("errors.txt", "a") as fl:
                fl.write(f"id : {e}" + "\n" + "*" * 10 + "\n")
            return {"error": f"Their seems to be a problem contact https://t.me/leyuskc; With this id {id}"}

    def reddit(self, url):
        pass

    def twitter(self, url):
        pass

    def urls(self, url, inline=False):
        try:
            st = url
            if "www." not in url:
                st = url.split("https://")[1]
            domain = st.split(".")
        except IndexError as e:
            return "Typing..."
        dic = {
            "youtube": self.youtube,
            "youtu": self.youtube,
            "tiktok": self.tiktok,
            "facebook": self.facebook,
            "fb": self.facebook,
            "instagram": self.instagram,
        }
        for i in domain:
            if i in dic.keys():
                if not inline:
                    return dic[i](url)
                else:
                    txt = dic[i](url)
                    if "error" not in txt.keys():
                        keys = [i for i in txt.keys()]
                        vid = txt[keys[0]][list(txt[keys[0]].keys())[0]]
                        aud = txt[keys[1]][list(txt[keys[1]].keys())[0]]
                        txt = "Video URL [=>] " + vid + "\n Audio URL [=>] " + aud
                        return txt
                    else:
                        return txt["error"]

        return "Not A valid URL"


if __name__ == "__main__":
    a = Run()
    d = a.urls("https://youtu.be/hcsX5Qd2GLo")
    print(d)
