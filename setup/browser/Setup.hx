package browser;

import chrome.Chrome;
import chrome.input.WebInput;

#if (js && html5)
import js.Browser;
import js.html.Element;
import js.html.Event;
#end

typedef BrowserConfig =
{
    ?url:String,
    ?x:Int,
    ?y:Int,
    ?width:Int,
    ?height:Int,
    ?visible:Bool,
    ?enableInput:Bool,
    ?autoOpen:Bool,
    ?target:String
}

class Setup
{
    public static var initialized(default, null):Bool = false;
    public static var running(default, null):Bool = false;

    public static var defaultURL:String = "https://example.com";
    public static var defaultWidth:Int = 800;
    public static var defaultHeight:Int = 600;

    public static var onReady:Void->Void;
    public static var onClose:Void->Void;
    public static var onError:String->Void;

    private static var config:BrowserConfig;

    #if (js && html5)
    private static var resizeHandler:Event->Void;
    private static var unloadHandler:Event->Void;
    #end

    public static function initialize(?options:BrowserConfig):Bool
    {
        if (initialized)
            return true;

        config = options != null ? options : {};

        Chrome.initialize();

        if (config.enableInput != false)
            WebInput.initialize();

        #if (js && html5)
        resizeHandler = handleResize;
        unloadHandler = handleUnload;

        Browser.window.addEventListener("resize", resizeHandler);
        Browser.window.addEventListener("pagehide", unloadHandler);
        #end

        initialized = true;
        running = true;

        if (config.autoOpen == true)
        {
            if (!open())
            {
                shutdown();
                return false;
            }
        }

        if (onReady != null)
            onReady();

        return true;
    }

    public static function open(?url:String):Bool
    {
        if (!initialized || !running)
            return fail("Browser setup is not initialized.");

        var address = resolveURL(url);

        if (!Chrome.isValidURL(address))
            return fail("Invalid browser URL: " + address);

        var x = config.x != null ? config.x : 0;
        var y = config.y != null ? config.y : 0;
        var width = config.width != null ? config.width : defaultWidth;
        var height = config.height != null ? config.height : defaultHeight;

        if (width <= 0 || height <= 0)
            return fail("Browser dimensions must be greater than zero.");

        #if (js && html5)
        if (!Chrome.createFrame(address, x, y, width, height))
            return fail("Unable to create browser frame.");

        if (config.visible == false)
            Chrome.hide();

        return true;
        #else
        return Chrome.open(
            address,
            config.target != null ? config.target : "_blank"
        );
        #end
    }

    public static function navigate(url:String):Bool
    {
        if (!initialized || !running)
            return fail("Browser setup is not initialized.");

        if (!Chrome.isValidURL(url))
            return fail("Invalid browser URL: " + url);

        return Chrome.navigate(url);
    }

    public static function reload():Void
    {
        if (initialized && running)
            Chrome.reload();
    }

    public static function back():Bool
    {
        if (!initialized || !running)
            return false;

        return Chrome.back();
    }

    public static function forward():Bool
    {
        if (!initialized || !running)
            return false;

        return Chrome.forward();
    }

    public static function show():Void
    {
        if (initialized)
            Chrome.show();
    }

    public static function hide():Void
    {
        if (initialized)
            Chrome.hide();
    }

    public static function resize(width:Int, height:Int):Bool
    {
        if (!initialized || width <= 0 || height <= 0)
            return false;

        config.width = width;
        config.height = height;

        Chrome.setSize(width, height);

        return true;
    }

    public static function move(x:Int, y:Int):Void
    {
        if (!initialized)
            return;

        config.x = x;
        config.y = y;

        Chrome.setPosition(x, y);
    }

    public static function update():Void
    {
        if (!initialized || !running)
            return;

        if (config.enableInput != false)
            WebInput.update();
    }

    public static function setInputEnabled(value:Bool):Void
    {
        if (!initialized)
            return;

        config.enableInput = value;

        if (value)
        {
            if (!WebInput.initialized)
                WebInput.initialize();

            WebInput.setEnabled(true);
        }
        else
        {
            WebInput.setEnabled(false);
        }
    }

    public static function isSupported():Bool
    {
        return Chrome.isSupported();
    }

    public static function getURL():String
    {
        return Chrome.getURL();
    }

    public static function getConfig():BrowserConfig
    {
        if (config == null)
            return {};

        return {
            url: config.url,
            x: config.x,
            y: config.y,
            width: config.width,
            height: config.height,
            visible: config.visible,
            enableInput: config.enableInput,
            autoOpen: config.autoOpen,
            target: config.target
        };
    }

    public static function shutdown():Void
    {
        if (!initialized)
            return;

        #if (js && html5)
        Browser.window.removeEventListener("resize", resizeHandler);
        Browser.window.removeEventListener("pagehide", unloadHandler);
        #end

        WebInput.destroy();
        Chrome.destroy();

        running = false;
        initialized = false;
        config = null;

        if (onClose != null)
            onClose();
    }

    private static function resolveURL(?url:String):String
    {
        if (url != null && StringTools.trim(url) != "")
            return StringTools.trim(url);

        if (config != null && config.url != null)
        {
            var configured = StringTools.trim(config.url);

            if (configured != "")
                return configured;
        }

        return defaultURL;
    }

    private static function fail(message:String):Bool
    {
        if (onError != null)
            onError(message);

        return false;
    }

    #if (js && html5)
    private static function handleResize(event:Event):Void
    {
        if (!initialized || config == null)
            return;

        if (config.width == null || config.height == null)
            return;

        Chrome.setSize(config.width, config.height);
    }

    private static function handleUnload(event:Event):Void
    {
        shutdown();
    }
    #end
}
