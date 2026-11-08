package chrome.url;

import chrome.Chrome;
import haxe.ds.StringMap;
import StringTools;

#if (js && html5)
import js.Browser;
#end

typedef URLInfo =
{
    var url:String;
    var protocol:String;
    var host:String;
    var hostname:String;
    var port:String;
    var pathname:String;
    var search:String;
    var hash:String;
    var origin:String;
    var username:String;
    var password:String;
}

class Manager
{
    public static var defaultProtocol:String = "https";
    public static var searchEngine:String = "https://www.google.com/search?q=";
    public static var maxHistory:Int = 100;
    public static var allowHTTP:Bool = true;
    public static var allowHTTPS:Bool = true;

    public static var currentURL(default, null):String = "";
    public static var lastURL(default, null):String = "";

    public static var onNavigate:String->Void;
    public static var onError:String->Void;
    public static var onHistoryChange:Array<String>->Void;
    public static var onFavoriteChange:Array<String>->Void;

    private static var history:Array<String> = [];
    private static var favorites:Array<String> = [];
    private static var historyIndex:Int = -1;

    public static function initialize():Void
    {
        currentURL = "";
        lastURL = "";
        history = [];
        favorites = [];
        historyIndex = -1;
    }

    public static function navigate(value:String, external:Bool = false):Bool
    {
        var url = resolve(value);

        if (!isValid(url))
            return fail("Invalid URL: " + value);

        lastURL = currentURL;
        currentURL = url;

        var success = external ? Chrome.open(url) : Chrome.navigate(url);

        if (!success)
        {
            currentURL = lastURL;
            return fail("Unable to navigate: " + url);
        }

        addHistory(url);

        if (onNavigate != null)
            onNavigate(url);

        return true;
    }

    public static function open(value:String):Bool
    {
        return navigate(value, true);
    }

    public static function resolve(value:String):String
    {
        if (value == null)
            return "";

        var input = StringTools.trim(value);

        if (input == "")
            return "";

        if (StringTools.startsWith(input, "http://")
            || StringTools.startsWith(input, "https://"))
            return input;

        if (StringTools.startsWith(input, "//"))
            return defaultProtocol + ":" + input;

        if (input.indexOf(" ") != -1 || input.indexOf(".") == -1)
            return searchEngine + StringTools.urlEncode(input);

        return defaultProtocol + "://" + input;
    }

    public static function isValid(value:String):Bool
    {
        if (value == null || value == "")
            return false;

        var pattern = ~/^(https?):\/\/([^\/\s?#]+)(?:[\/?#][^\s]*)?$/i;

        if (!pattern.match(value))
            return false;

        var protocol = pattern.matched(1).toLowerCase();

        if (protocol == "http" && !allowHTTP)
            return false;

        if (protocol == "https" && !allowHTTPS)
            return false;

        return true;
    }

    public static function normalize(value:String):String
    {
        var url = resolve(value);

        if (!isValid(url))
            return "";

        #if (js && html5)
        try
        {
            var parsed = new js.html.URL(url);
            return parsed.href;
        }
        catch (e:Dynamic)
        {
            return url;
        }
        #else
        return url;
        #end
    }

    public static function parse(value:String):Null<URLInfo>
    {
        var url = normalize(value);

        if (!isValid(url))
            return null;

        #if (js && html5)
        try
        {
            var parsed = new js.html.URL(url);

            return {
                url: parsed.href,
                protocol: parsed.protocol,
                host: parsed.host,
                hostname: parsed.hostname,
                port: parsed.port,
                pathname: parsed.pathname,
                search: parsed.search,
                hash: parsed.hash,
                origin: parsed.origin,
                username: parsed.username,
                password: parsed.password
            };
        }
        catch (e:Dynamic)
        {
            return null;
        }
        #else
        var pattern = ~/^(https?):\/\/([^\/?#]+)([^?#]*)(\?[^#]*)?(#.*)?$/i;

        if (!pattern.match(url))
            return null;

        var protocol = pattern.matched(1).toLowerCase() + ":";
        var host = pattern.matched(2);
        var path = pattern.matched(3);
        var search = pattern.matched(4);
        var hash = pattern.matched(5);

        var hostname = host;
        var port = "";

        var colon = host.lastIndexOf(":");

        if (colon != -1 && host.indexOf("]") == -1)
        {
            hostname = host.substr(0, colon);
            port = host.substr(colon + 1);
        }

        return {
            url: url,
            protocol: protocol,
            host: host,
            hostname: hostname,
            port: port,
            pathname: path == "" ? "/" : path,
            search: search == null ? "" : search,
            hash: hash == null ? "" : hash,
            origin: protocol + "//" + host,
            username: "",
            password: ""
        };
        #end
    }

    public static function getDomain(value:String):String
    {
        var info = parse(value);
        return info != null ? info.hostname : "";
    }

    public static function getProtocol(value:String):String
    {
        var info = parse(value);
        return info != null ? info.protocol : "";
    }

    public static function getPath(value:String):String
    {
        var info = parse(value);
        return info != null ? info.pathname : "";
    }

    public static function getOrigin(value:String):String
    {
        var info = parse(value);
        return info != null ? info.origin : "";
    }

    public static function getHash(value:String):String
    {
        var info = parse(value);
        return info != null ? info.hash : "";
    }

    public static function getQuery(value:String):StringMap<String>
    {
        var result = new StringMap<String>();
        var info = parse(value);

        if (info == null || info.search == "")
            return result;

        var query = StringTools.startsWith(info.search, "?")
            ? info.search.substr(1)
            : info.search;

        for (part in query.split("&"))
        {
            if (part == "")
                continue;

            var index = part.indexOf("=");
            var key = index == -1 ? part : part.substr(0, index);
            var val = index == -1 ? "" : part.substr(index + 1);

            result.set(
                StringTools.urlDecode(StringTools.replace(key, "+", " ")),
                StringTools.urlDecode(StringTools.replace(val, "+", " "))
            );
        }

        return result;
    }

    public static function getParameter(value:String, key:String):Null<String>
    {
        return getQuery(value).get(key);
    }

    public static function setParameter(
        value:String,
        key:String,
        parameter:String
    ):String
    {
        var info = parse(value);

        if (info == null)
            return "";

        var params = getQuery(value);
        params.set(key, parameter);

        return buildURL(info, params);
    }

    public static function removeParameter(value:String, key:String):String
    {
        var info = parse(value);

        if (info == null)
            return "";

        var params = getQuery(value);
        params.remove(key);

        return buildURL(info, params);
    }

    public static function buildURL(
        info:URLInfo,
        ?params:StringMap<String>
    ):String
    {
        var result = info.origin + info.pathname;

        if (params == null)
            params = getQuery(info.url);

        var pairs:Array<String> = [];

        for (key in params.keys())
        {
            var value = params.get(key);

            pairs.push(
                StringTools.urlEncode(key)
                + "="
                + StringTools.urlEncode(value == null ? "" : value)
            );
        }

        pairs.sort(Reflect.compare);

        if (pairs.length > 0)
            result += "?" + pairs.join("&");

        result += info.hash;

        return result;
    }

    public static function encode(value:String):String
    {
        return StringTools.urlEncode(value);
    }

    public static function decode(value:String):String
    {
        return StringTools.urlDecode(value);
    }

    public static function search(query:String):Bool
    {
        if (query == null || StringTools.trim(query) == "")
            return false;

        return navigate(searchEngine + encode(query));
    }

    public static function addFavorite(value:String):Bool
    {
        var url = normalize(value);

        if (!isValid(url) || favorites.indexOf(url) != -1)
            return false;

        favorites.push(url);
        notifyFavorites();

        return true;
    }

    public static function removeFavorite(value:String):Bool
    {
        var url = normalize(value);
        var index = favorites.indexOf(url);

        if (index == -1)
            return false;

        favorites.splice(index, 1);
        notifyFavorites();

        return true;
    }

    public static function isFavorite(value:String):Bool
    {
        return favorites.indexOf(normalize(value)) != -1;
    }

    public static function getFavorites():Array<String>
    {
        return favorites.copy();
    }

    public static function clearFavorites():Void
    {
        favorites = [];
        notifyFavorites();
    }

    public static function getHistory():Array<String>
    {
        return history.copy();
    }

    public static function clearHistory():Void
    {
        history = [];
        historyIndex = -1;
        notifyHistory();
    }

    public static function canGoBack():Bool
    {
        return historyIndex > 0;
    }

    public static function canGoForward():Bool
    {
        return historyIndex >= 0 && historyIndex < history.length - 1;
    }

    public static function back():Bool
    {
        if (!canGoBack())
            return false;

        if (!Chrome.back())
            return false;

        historyIndex--;
        lastURL = currentURL;
        currentURL = history[historyIndex];

        notifyHistory();

        if (onNavigate != null)
            onNavigate(currentURL);

        return true;
    }

    public static function forward():Bool
    {
        if (!canGoForward())
            return false;

        if (!Chrome.forward())
            return false;

        historyIndex++;
        lastURL = currentURL;
        currentURL = history[historyIndex];

        notifyHistory();

        if (onNavigate != null)
            onNavigate(currentURL);

        return true;
    }

    private static function addHistory(url:String):Void
    {
        if (historyIndex < history.length - 1)
            history = history.slice(0, historyIndex + 1);

        history.push(url);

        if (maxHistory > 0 && history.length > maxHistory)
            history.splice(0, history.length - maxHistory);

        historyIndex = history.length - 1;
        notifyHistory();
    }

    private static function notifyHistory():Void
    {
        if (onHistoryChange != null)
            onHistoryChange(history.copy());
    }

    private static function notifyFavorites():Void
    {
        if (onFavoriteChange != null)
            onFavoriteChange(favorites.copy());
    }

    private static function fail(message:String):Bool
    {
        if (onError != null)
            onError(message);

        return false;
    }

    public static function destroy():Void
    {
        initialize();

        onNavigate = null;
        onError = null;
        onHistoryChange = null;
        onFavoriteChange = null;
    }
}
