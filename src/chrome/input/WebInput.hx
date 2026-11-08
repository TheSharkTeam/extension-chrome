package chrome.input;

#if (js && html5)
import js.Browser;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.html.WheelEvent;
import js.html.Event;
#end

class WebInput
{
    public static var enabled:Bool = true;
    public static var initialized(default, null):Bool = false;

    public static var mouseX(default, null):Float = 0;
    public static var mouseY(default, null):Float = 0;
    public static var mouseDown(default, null):Bool = false;
    public static var mouseButton(default, null):Int = -1;

    public static var touchX(default, null):Float = 0;
    public static var touchY(default, null):Float = 0;
    public static var touching(default, null):Bool = false;
    public static var touchCount(default, null):Int = 0;

    public static var scrollX(default, null):Float = 0;
    public static var scrollY(default, null):Float = 0;

    public static var ctrl(default, null):Bool = false;
    public static var shift(default, null):Bool = false;
    public static var alt(default, null):Bool = false;
    public static var meta(default, null):Bool = false;

    public static var onKeyDown:String->Void;
    public static var onKeyUp:String->Void;
    public static var onMouseDown:Int->Void;
    public static var onMouseUp:Int->Void;
    public static var onMouseMove:(Float, Float)->Void;
    public static var onScroll:(Float, Float)->Void;
    public static var onTouchStart:(Float, Float)->Void;
    public static var onTouchMove:(Float, Float)->Void;
    public static var onTouchEnd:Void->Void;
    public static var onTextInput:String->Void;

    private static var pressedKeys:Map<String, Bool> = new Map();
    private static var justPressedKeys:Map<String, Bool> = new Map();
    private static var justReleasedKeys:Map<String, Bool> = new Map();

    #if (js && html5)
    private static var keyDownHandler:KeyboardEvent->Void;
    private static var keyUpHandler:KeyboardEvent->Void;
    private static var mouseDownHandler:MouseEvent->Void;
    private static var mouseUpHandler:MouseEvent->Void;
    private static var mouseMoveHandler:MouseEvent->Void;
    private static var wheelHandler:WheelEvent->Void;
    private static var touchStartHandler:TouchEvent->Void;
    private static var touchMoveHandler:TouchEvent->Void;
    private static var touchEndHandler:TouchEvent->Void;
    private static var touchCancelHandler:TouchEvent->Void;
    private static var inputHandler:Event->Void;
    private static var blurHandler:Event->Void;
    #end

    public static function initialize():Void
    {
        if (initialized)
            return;

        enabled = true;
        reset();

        #if (js && html5)
        keyDownHandler = handleKeyDown;
        keyUpHandler = handleKeyUp;
        mouseDownHandler = handleMouseDown;
        mouseUpHandler = handleMouseUp;
        mouseMoveHandler = handleMouseMove;
        wheelHandler = handleWheel;
        touchStartHandler = handleTouchStart;
        touchMoveHandler = handleTouchMove;
        touchEndHandler = handleTouchEnd;
        touchCancelHandler = handleTouchEnd;
        inputHandler = handleInput;
        blurHandler = handleBlur;

        Browser.window.addEventListener("keydown", keyDownHandler);
        Browser.window.addEventListener("keyup", keyUpHandler);
        Browser.window.addEventListener("mousedown", mouseDownHandler);
        Browser.window.addEventListener("mouseup", mouseUpHandler);
        Browser.window.addEventListener("mousemove", mouseMoveHandler);
        Browser.window.addEventListener("wheel", wheelHandler);
        Browser.window.addEventListener("touchstart", touchStartHandler);
        Browser.window.addEventListener("touchmove", touchMoveHandler);
        Browser.window.addEventListener("touchend", touchEndHandler);
        Browser.window.addEventListener("touchcancel", touchCancelHandler);
        Browser.window.addEventListener("blur", blurHandler);
        Browser.document.addEventListener("input", inputHandler);
        #end

        initialized = true;
    }

    public static function update():Void
    {
        justPressedKeys = new Map();
        justReleasedKeys = new Map();

        scrollX = 0;
        scrollY = 0;
    }

    public static function isKeyDown(key:String):Bool
    {
        return enabled && pressedKeys.exists(normalizeKey(key));
    }

    public static function isKeyJustPressed(key:String):Bool
    {
        return enabled && justPressedKeys.exists(normalizeKey(key));
    }

    public static function isKeyJustReleased(key:String):Bool
    {
        return enabled && justReleasedKeys.exists(normalizeKey(key));
    }

    public static function getPressedKeys():Array<String>
    {
        var result:Array<String> = [];

        for (key in pressedKeys.keys())
            result.push(key);

        return result;
    }

    public static function isMouseDown(button:Int = 0):Bool
    {
        return enabled && mouseDown && mouseButton == button;
    }

    public static function isTouching():Bool
    {
        return enabled && touching;
    }

    public static function getMousePosition():{x:Float, y:Float}
    {
        return {
            x: mouseX,
            y: mouseY
        };
    }

    public static function getTouchPosition():{x:Float, y:Float}
    {
        return {
            x: touchX,
            y: touchY
        };
    }

    public static function setEnabled(value:Bool):Void
    {
        enabled = value;

        if (!enabled)
            reset();
    }

    public static function reset():Void
    {
        pressedKeys = new Map();
        justPressedKeys = new Map();
        justReleasedKeys = new Map();

        mouseX = 0;
        mouseY = 0;
        mouseDown = false;
        mouseButton = -1;

        touchX = 0;
        touchY = 0;
        touching = false;
        touchCount = 0;

        scrollX = 0;
        scrollY = 0;

        ctrl = false;
        shift = false;
        alt = false;
        meta = false;
    }

    private static function normalizeKey(key:String):String
    {
        if (key == null)
            return "";

        return key.toLowerCase();
    }

    #if (js && html5)
    private static function handleKeyDown(event:KeyboardEvent):Void
    {
        if (!enabled)
            return;

        var key = normalizeKey(event.key);

        if (!pressedKeys.exists(key))
        {
            justPressedKeys.set(key, true);
            pressedKeys.set(key, true);
        }

        updateModifiers(event);

        if (onKeyDown != null)
            onKeyDown(key);
    }

    private static function handleKeyUp(event:KeyboardEvent):Void
    {
        if (!enabled)
            return;

        var key = normalizeKey(event.key);

        pressedKeys.remove(key);
        justReleasedKeys.set(key, true);

        updateModifiers(event);

        if (onKeyUp != null)
            onKeyUp(key);
    }

    private static function updateModifiers(event:KeyboardEvent):Void
    {
        ctrl = event.ctrlKey;
        shift = event.shiftKey;
        alt = event.altKey;
        meta = event.metaKey;
    }

    private static function handleMouseDown(event:MouseEvent):Void
    {
        if (!enabled)
            return;

        mouseDown = true;
        mouseButton = event.button;

        mouseX = event.clientX;
        mouseY = event.clientY;

        if (onMouseDown != null)
            onMouseDown(mouseButton);
    }

    private static function handleMouseUp(event:MouseEvent):Void
    {
        if (!enabled)
            return;

        mouseDown = false;
        mouseButton = -1;

        mouseX = event.clientX;
        mouseY = event.clientY;

        if (onMouseUp != null)
            onMouseUp(event.button);
    }

    private static function handleMouseMove(event:MouseEvent):Void
    {
        if (!enabled)
            return;

        mouseX = event.clientX;
        mouseY = event.clientY;

        if (onMouseMove != null)
            onMouseMove(mouseX, mouseY);
    }

    private static function handleWheel(event:WheelEvent):Void
    {
        if (!enabled)
            return;

        scrollX += event.deltaX;
        scrollY += event.deltaY;

        if (onScroll != null)
            onScroll(event.deltaX, event.deltaY);
    }

    private static function handleTouchStart(event:TouchEvent):Void
    {
        if (!enabled)
            return;

        touchCount = event.touches.length;
        touching = touchCount > 0;

        if (touching)
        {
            var touch = event.touches.item(0);

            touchX = touch.clientX;
            touchY = touch.clientY;

            if (onTouchStart != null)
                onTouchStart(touchX, touchY);
        }
    }

    private static function handleTouchMove(event:TouchEvent):Void
    {
        if (!enabled)
            return;

        touchCount = event.touches.length;
        touching = touchCount > 0;

        if (touching)
        {
            var touch = event.touches.item(0);

            touchX = touch.clientX;
            touchY = touch.clientY;

            if (onTouchMove != null)
                onTouchMove(touchX, touchY);
        }
    }

    private static function handleTouchEnd(event:TouchEvent):Void
    {
        if (!enabled)
            return;

        touchCount = event.touches.length;
        touching = touchCount > 0;

        if (touching)
        {
            var touch = event.touches.item(0);

            touchX = touch.clientX;
            touchY = touch.clientY;
        }
        else if (onTouchEnd != null)
        {
            onTouchEnd();
        }
    }

    private static function handleInput(event:Event):Void
    {
        if (!enabled || onTextInput == null)
            return;

        var target:Dynamic = event.target;

        if (target != null && Reflect.hasField(target, "value"))
        {
            var value:Dynamic = Reflect.field(target, "value");

            if (value != null)
                onTextInput(Std.string(value));
        }
    }

    private static function handleBlur(event:Event):Void
    {
        reset();
    }
    #end

    public static function destroy():Void
    {
        if (!initialized)
            return;

        #if (js && html5)
        Browser.window.removeEventListener("keydown", keyDownHandler);
        Browser.window.removeEventListener("keyup", keyUpHandler);
        Browser.window.removeEventListener("mousedown", mouseDownHandler);
        Browser.window.removeEventListener("mouseup", mouseUpHandler);
        Browser.window.removeEventListener("mousemove", mouseMoveHandler);
        Browser.window.removeEventListener("wheel", wheelHandler);
        Browser.window.removeEventListener("touchstart", touchStartHandler);
        Browser.window.removeEventListener("touchmove", touchMoveHandler);
        Browser.window.removeEventListener("touchend", touchEndHandler);
        Browser.window.removeEventListener("touchcancel", touchCancelHandler);
        Browser.window.removeEventListener("blur", blurHandler);
        Browser.document.removeEventListener("input", inputHandler);
        #end

        reset();

        onKeyDown = null;
        onKeyUp = null;
        onMouseDown = null;
        onMouseUp = null;
        onMouseMove = null;
        onScroll = null;
        onTouchStart = null;
        onTouchMove = null;
        onTouchEnd = null;
        onTextInput = null;

        initialized = false;
    }
}
