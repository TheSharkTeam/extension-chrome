package chrome.url;

import StringTools;
import haxe.ds.StringMap;

typedef ParsedURL =
{
    var href:String;
    var protocol:String;
    var username:String;
    var password:String;
    var hostname:String;
    var port:String;
    var host:String;
    var pathname:String;
    var search:String;
    var hash:String;
    var origin:String;
}

class URLParser
{
    public static var defaultProtocol:String = "https:";
    public static var allowCredentials:Bool = true;

    public static function parse(value:String, ?base:String):Null<ParsedURL>
    {
        if (value == null)
            return null;

        var input = StringTools.trim(value);

        if (input == "")
            return null;

        if (base != null && !hasScheme(input))
        {
            input = resolve(input, base);

            if (input == "")
                return null;
        }

        if (StringTools.startsWith(input, "//"))
            input = defaultProtocol + input;

        if (!hasScheme(input))
            input = defaultProtocol + "//" + input;

        var schemePattern = ~/^([a-z][a-z0-9+.-]*):\/\/(.*)$/i;

        if (!schemePattern.match(input))
            return null;

        var protocol = schemePattern.matched(1).toLowerCase() + ":";
        var remainder = schemePattern.matched(2);

        if (protocol != "http:" && protocol != "https:")
            return null;

        var authorityEnd = remainder.length;

        for (separator in ["/", "?", "#"])
        {
            var index = remainder.indexOf(separator);

            if (index != -1 && index < authorityEnd)
                authorityEnd = index;
        }

        var authority = remainder.substr(0, authorityEnd);
        var suffix = remainder.substr(authorityEnd);

        if (authority == "")
            return null;

        var username = "";
        var password = "";

        var at = authority.lastIndexOf("@");

        if (at != -1)
        {
            if (!allowCredentials)
                return null;

            var credentials = authority.substr(0, at);
            authority = authority.substr(at + 1);

            var colon = credentials.indexOf(":");

            if (colon == -1)
            {
                username = decode(credentials);
            }
            else
            {
                username = decode(credentials.substr(0, colon));
                password = decode(credentials.substr(colon + 1));
            }
        }

        var hostname = authority;
        var port = "";

        if (StringTools.startsWith(authority, "["))
        {
            var closing = authority.indexOf("]");

            if (closing == -1)
                return null;

            hostname = authority.substr(0, closing + 1);

            var rest = authority.substr(closing + 1);

            if (rest != "")
            {
                if (!StringTools.startsWith(rest, ":"))
                    return null;

                port = rest.substr(1);
            }

            if (!isValidIPv6(hostname))
                return null;
        }
        else
        {
            var colon = authority.lastIndexOf(":");

            if (colon != -1)
            {
                hostname = authority.substr(0, colon);
                port = authority.substr(colon + 1);
            }

            if (!isValidHostname(hostname))
                return null;
        }

        if (!isValidPort(port))
            return null;

        hostname = hostname.toLowerCase();

        if ((protocol == "http:" && port == "80")
            || (protocol == "https:" && port == "443"))
            port = "";

        var host = hostname;

        if (port != "")
            host += ":" + port;

        var hash = "";
        var search = "";

        var hashIndex = suffix.indexOf("#");

        if (hashIndex != -1)
        {
            hash = suffix.substr(hashIndex);
            suffix = suffix.substr(0, hashIndex);
        }

        var queryIndex = suffix.indexOf("?");

        if (queryIndex != -1)
        {
            search = suffix.substr(queryIndex);
            suffix = suffix.substr(0, queryIndex);
        }

        var pathname = suffix == "" ? "/" : suffix;

        if (!StringTools.startsWith(pathname, "/"))
            pathname = "/" + pathname;

        pathname = normalizePath(pathname);

        var origin = protocol + "//" + host;

        var auth = "";

        if (username != "" || password != "")
        {
            auth = encode(username);

            if (password != "")
                auth += ":" + encode(password);

            auth += "@";
        }

        var href = protocol + "//" + auth + host
            + pathname + search + hash;

        return {
            href: href,
            protocol: protocol,
            username: username,
            password: password,
            hostname: hostname,
            port: port,
            host: host,
            pathname: pathname,
            search: search,
            hash: hash,
            origin: origin
        };
    }

    public static function resolve(value:String, base:String):String
    {
        if (value == null)
            return "";

        var input = StringTools.trim(value);

        if (hasScheme(input))
            return input;

        var baseURL = parse(base);

        if (baseURL == null)
            return "";

        if (StringTools.startsWith(input, "//"))
            return baseURL.protocol + input;

        if (input == "")
            return baseURL.href;

        if (StringTools.startsWith(input, "#"))
            return removeHash(baseURL.href) + input;

        if (StringTools.startsWith(input, "?"))
            return baseURL.origin + baseURL.pathname + input;

        if (StringTools.startsWith(input, "/"))
            return baseURL.origin + input;

        var path = baseURL.pathname;
        var lastSlash = path.lastIndexOf("/");

        var directory = lastSlash == -1
            ? "/"
            : path.substr(0, lastSlash + 1);

        return baseURL.origin + directory + input;
    }

    public static function normalize(value:String, ?base:String):String
    {
        var parsed = parse(value, base);
        return parsed == null ? "" : parsed.href;
    }

    public static function isValid(value:String):Bool
    {
        return parse(value) != null;
    }

    public static function hasScheme(value:String):Bool
    {
        if (value == null)
            return false;

        return ~/^[a-z][a-z0-9+.-]*:/i.match(value);
    }

    public static function isSecure(value:String):Bool
    {
        var parsed = parse(value);
        return parsed != null && parsed.protocol == "https:";
    }

    public static function getOrigin(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.origin;
    }

    public static function getHostname(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.hostname;
    }

    public static function getPathname(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.pathname;
    }

    public static function getSearch(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.search;
    }

    public static function getHash(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.hash;
    }

    public static function getPort(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.port;
    }

    public static function getProtocol(value:String):String
    {
        var parsed = parse(value);
        return parsed == null ? "" : parsed.protocol;
    }

    public static function getParameters(value:String):StringMap<String>
    {
        var result = new StringMap<String>();
        var parsed = parse(value);

        if (parsed == null || parsed.search == "")
            return result;

        var query = parsed.search.substr(1);

        for (pair in query.split("&"))
        {
            if (pair == "")
                continue;

            var separator = pair.indexOf("=");

            var key = separator == -1
                ? pair
                : pair.substr(0, separator);

            var val = separator == -1
                ? ""
                : pair.substr(separator + 1);

            result.set(
                decode(StringTools.replace(key, "+", " ")),
                decode(StringTools.replace(val, "+", " "))
            );
        }

        return result;
    }

    public static function getParameter(
        value:String,
        name:String
    ):Null<String>
    {
        return getParameters(value).get(name);
    }

    public static function setParameter(
        value:String,
        name:String,
        parameter:String
    ):String
    {
        var parsed = parse(value);

        if (parsed == null)
            return "";

        var parameters = getParameters(value);
        parameters.set(name, parameter);

        return buildWithParameters(parsed, parameters);
    }

    public static function removeParameter(
        value:String,
        name:String
    ):String
    {
        var parsed = parse(value);

        if (parsed == null)
            return "";

        var parameters = getParameters(value);
        parameters.remove(name);

        return buildWithParameters(parsed, parameters);
    }

    public static function setHash(value:String, hash:String):String
    {
        var parsed = parse(value);

        if (parsed == null)
            return "";

        var clean = removeHash(parsed.href);

        if (hash == null || hash == "")
            return clean;

        return clean + (
            StringTools.startsWith(hash, "#") ? hash : "#" + hash
        );
    }

    public static function removeHash(value:String):String
    {
        if (value == null)
            return "";

        var index = value.indexOf("#");

        return index == -1 ? value : value.substr(0, index);
    }

    public static function setPathname(
        value:String,
        pathname:String
    ):String
    {
        var parsed = parse(value);

        if (parsed == null)
            return "";

        var path = pathname == null ? "/" : pathname;

        if (!StringTools.startsWith(path, "/"))
            path = "/" + path;

        return build(
            parsed.protocol,
            parsed.host,
            normalizePath(path),
            parsed.search,
            parsed.hash,
            parsed.username,
            parsed.password
        );
    }

    public static function build(
        protocol:String,
        host:String,
        pathname:String = "/",
        search:String = "",
        hash:String = "",
        username:String = "",
        password:String = ""
    ):String
    {
        if (protocol == null || host == null)
            return "";

        var scheme = StringTools.endsWith(protocol, ":")
            ? protocol
            : protocol + ":";

        var auth = "";

        if (username != "" || password != "")
        {
            auth = encode(username);

            if (password != "")
                auth += ":" + encode(password);

            auth += "@";
        }

        var path = pathname == null || pathname == ""
            ? "/"
            : pathname;

        if (!StringTools.startsWith(path, "/"))
            path = "/" + path;

        var query = search == null || search == ""
            ? ""
            : (StringTools.startsWith(search, "?") ? search : "?" + search);

        var fragment = hash == null || hash == ""
            ? ""
            : (StringTools.startsWith(hash, "#") ? hash : "#" + hash);

        return normalize(
            scheme + "//" + auth + host
            + path + query + fragment
        );
    }

    public static function encode(value:String):String
    {
        return StringTools.urlEncode(value);
    }

    public static function decode(value:String):String
    {
        if (value == null)
            return "";

        try
        {
            return StringTools.urlDecode(value);
        }
        catch (e:Dynamic)
        {
            return value;
        }
    }

    private static function buildWithParameters(
        parsed:ParsedURL,
        parameters:StringMap<String>
    ):String
    {
        var pairs:Array<String> = [];

        for (key in parameters.keys())
        {
            var value = parameters.get(key);

            pairs.push(
                encode(key) + "="
                + encode(value == null ? "" : value)
            );
        }

        pairs.sort(Reflect.compare);

        var query = pairs.length == 0
            ? ""
            : "?" + pairs.join("&");

        return build(
            parsed.protocol,
            parsed.host,
            parsed.pathname,
            query,
            parsed.hash,
            parsed.username,
            parsed.password
        );
    }

    private static function normalizePath(path:String):String
    {
        var segments = path.split("/");
        var result:Array<String> = [];

        for (segment in segments)
        {
            if (segment == ".")
                continue;

            if (segment == "..")
            {
                if (result.length > 0)
                    result.pop();

                continue;
            }

            if (segment != "")
                result.push(segment);
        }

        var normalized = "/" + result.join("/");

        if (StringTools.endsWith(path, "/")
            && !StringTools.endsWith(normalized, "/"))
            normalized += "/";

        return normalized;
    }

    private static function isValidHostname(hostname:String):Bool
    {
        if (hostname == null || hostname == "")
            return false;

        if (hostname.indexOf(" ") != -1)
            return false;

        if (hostname.indexOf(":") != -1)
            return false;

        return ~/^[a-z0-9._~-]+$/i.match(hostname);
    }

    private static function isValidIPv6(hostname:String):Bool
    {
        if (!StringTools.startsWith(hostname, "[")
            || !StringTools.endsWith(hostname, "]"))
            return false;

        var address = hostname.substr(1, hostname.length - 2);

        return address.indexOf(":") != -1
            && ~/^[0-9a-f:.]+$/i.match(address);
    }

    private static function isValidPort(port:String):Bool
    {
        if (port == "")
            return true;

        if (!~/^[0-9]+$/.match(port))
            return false;

        var number = Std.parseInt(port);

        return number != null && number >= 0 && number <= 65535;
    }
}
