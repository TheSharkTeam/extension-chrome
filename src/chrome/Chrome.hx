package chrome;

import lime.system.System;

#if (js && html5)
import js.Browser;
import js.html.IFrameElement;
#end

class Chrome
{
    public static var version(default, null):String = "1.0.0";
    public static var currentURL(default, null):String = "";
    public static var history(default, null):Array<String> = [];
    public static var historyIndex(default, null):Int = -1;
    public static var enabled:Bool = true;
    public static var visible(default, null):Bool = false;

    #if (js && html5)
    private static var frame:IFrameElement;
    #end

    public static function initialize():Void
    {
        destroy();

        enabled = true;
        currentURL = "";
        history = [];
        historyIndex = -1;
    }

    public static function open(url:String, target:String = "_blank"):Bool
    {
        if (!enabled || !isValidURL(url))
            return false;

        currentURL = url;
        addHistory(url);
        System.openURL(url, target);

        return true;
    }

    public static function navigate(url:String):Bool
    {
        if (!enabled || !isValidURL(url))
            return false;

        #if (js && html5)
        if (frame != null)
        {
            frame.src = url;
            currentURL = url;
            addHistory(url);
            return true;
        }
        #end

        return open(url);
    }

    public static function createFrame(
        url:String,
        x:Int = 0,
        y:Int = 0,
        width:Int = 800,
        height:Int = 600
    ):Bool
    {
        if (!enabled || !isValidURL(url))
            return false;

        #if (js && html5)
        destroyFrame();

        frame = Browser.document.createIFrameElement();
        frame.src = url;
        frame.style.position = "absolute";
        frame.style.left = x + "px";
        frame.style.top = y + "px";
        frame.style.width = width + "px";
        frame.style.height = height + "px";
        frame.style.border = "none";
        frame.style.zIndex = "9999";

        Browser.document.body.appendChild(frame);

        currentURL = url;
        visible = true;
        addHistory(url);

        return true;
        #else
        return false;
        #end
    }

    public static function setPosition(x:Int, y:Int):Void
    {
        #if (js && html5)
        if (frame != null)
        {
            frame.style.left = x + "px";
            frame.style.top = y + "px";
        }
        #end
    }

    public static function setSize(width:Int, height:Int):Void
    {
        #if (js && html5)
        if (frame != null)
        {
            frame.style.width = width + "px";
            frame.style.height = height + "px";
        }
        #end
    }

    public static function show():Void
    {
        #if (js && html5)
        if (frame != null)
        {
            frame.style.display = "block";
            visible = true;
        }
        #end
    }

    public static function hide():Void
    {
        #if (js && html5)
        if (frame != null)
        {
            frame.style.display = "none";
            visible = false;
        }
        #end
    }

    public static function reload():Void
    {
        #if (js && html5)
        if (frame != null)
        {
            frame.src = currentURL;
            return;
        }
        #end

        if (currentURL != "")
            System.openURL(currentURL);
    }

    public static function back():Bool
    {
        if (historyIndex <= 0)
            return false;

        historyIndex--;
        return loadHistoryURL();
    }

    public static function forward():Bool
    {
        if (historyIndex >= history.length - 1)
            return false;

        historyIndex++;
        return loadHistoryURL();
    }

    public static function canGoBack():Bool
    {
        return historyIndex > 0;
    }

    public static function canGoForward():Bool
    {
        return historyIndex >= 0
            && historyIndex < history.length - 1;
    }

    public static function getURL():String
    {
        return currentURL;
    }

    public static function getHistory():Array<String>
    {
        return history.copy();
    }

    public static function clearHistory():Void
    {
        history = [];
        historyIndex = -1;
    }

    public static function isValidURL(url:String):Bool
    {
        if (url == null)
            return false;

        var value = StringTools.trim(url);

        if (value == "")
            return false;

        var pattern = ~/^https?:\/\/[^\/\s?#]+(?:[\/?#][^\s]*)?$/i;

        return pattern.match(value);
    }

    public static function isSupported():Bool
    {
        #if (js && html5)
        return true;
        #else
        return false;
        #end
    }

    public static function destroyFrame():Void
    {
        #if (js && html5)
        if (frame != null)
        {
            if (frame.parentNode != null)
                frame.parentNode.removeChild(frame);

            frame = null;
        }
        #end

        visible = false;
    }

    public static function destroy():Void
    {
        destroyFrame();

        currentURL = "";
        history = [];
        historyIndex = -1;
    }

    private static function addHistory(url:String):Void
    {
        if (historyIndex < history.length - 1)
            history = history.slice(0, historyIndex + 1);

        history.push(url);
        historyIndex = history.length - 1;
    }

    private static function loadHistoryURL():Bool
    {
        if (historyIndex < 0 || historyIndex >= history.length)
            return false;

        currentURL = history[historyIndex];

        #if (js && html5)
        if (frame != null)
        {
            frame.src = currentURL;
            return true;
        }
        #end

        System.openURL(currentURL);
        return true;
    }
}
