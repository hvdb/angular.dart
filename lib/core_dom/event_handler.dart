part of angular.core.dom_internal;

typedef void EventFunction(event);

/**
 * [EventHandler] is responsible for handling events bound using on-* syntax
 * (i.e. `on-click="ctrl.doSomething();"`). The root of the application has an
 * EventHandler attached as does every [Component].
 *
 * Events bound within [Component] are handled by EventHandler attached to
 * their [ShadowRoot]. All other events are handled by EventHandler attached
 * to the application root ([Application]).
 *
 * **Note**: The expressions are executed within the closest context.
 *
 * Example:
 *
 *     <div foo>
 *       <button on-click="ctrl.say('Hello');">Button</button>;
 *     </div>
 *
 *     @Component(selector: '[foo]', publishAs: ctrl)
 *     class FooController {
 *       say(String something) => print(something);
 *     }
 *
 * When button is clicked, "Hello" will be printed in the console.
 */
@Injectable()
class EventHandler {
  dom.Node _rootNode;
  final Expando _expando;
  final ExceptionHandler _exceptionHandler;
  final _listeners = new HashMap<String, async.StreamSubscription>();

  EventHandler(this._rootNode, this._expando, this._exceptionHandler);

  /**
   * Register an event. This makes sure that  an event (of the specified name)
   * which bubbles to this node, gets processed by this [EventHandler].
   */
  void register(String eventName) {
    _listeners.putIfAbsent(eventName, () {
      return _rootNode.on[eventName].listen(_eventListener);
    });
  }

  void registerCallback(dom.Element element, String eventName, EventFunction callbackFn) {
    ElementProbe probe = _expando[element];
    probe.addListener(eventName, callbackFn);
    register(eventName);
  }

  async.Future releaseListeners() {
    return _listeners.forEach((_, async.StreamSubscription subscription) => subscription.cancel());
  }

  void walkDomTreeAndExecute(dom.Node element, dom.Event event) {
    while (element != null && element != _rootNode) {
      var expression, probe;
      if (element is dom.Element) {
        expression = element.attributes[eventNameToAttrName(event.type)];
        probe = _getProbe(element);
      }
      if (probe != null && probe.listeners[event.type] != null) {
        probe.listeners[event.type].forEach((fn) {
          try {
            fn(event);
          } catch (e, s) {
            _exceptionHandler(e, s);
          }
        });
      }
      if (probe != null && expression != null) {
        try {
          Scope scope = probe.scope;
          if (scope != null) scope.eval(expression, {r'$event': event});
        } catch (e, s) {
          _exceptionHandler(e, s);
        }
      }
      element = element.parentNode;
    }
  }

  void _eventListener(dom.Event event) {
    var element = event.target;
    walkDomTreeAndExecute(element, event);
  }

  ElementProbe _getProbe(dom.Node element) {
    while (element != _rootNode.parentNode) {
      ElementProbe probe = _expando[element];
      if (probe != null) return probe;
      element = element.parentNode;
    }
    return null;
  }

  /**
  * Converts event name into attribute. Event named 'someCustomEvent' needs to
  * be transformed into on-some-custom-event.
  */
  static String eventNameToAttrName(String eventName) {
    var part = eventName.replaceAllMapped(new RegExp("([A-Z])"), (Match match) {
      return '-${match.group(0).toLowerCase()}';
    });
    return 'on-${part}';
  }

  /**
  * Converts attribute into event name. Attribute 'on-some-custom-event'
  * corresponds to event named 'someCustomEvent'.
  */
  static String attrNameToEventName(String attrName) {
    var part = attrName.startsWith("on-") ? attrName.substring(3) : attrName;
    part = part.replaceAllMapped(new RegExp(r'\-(\w)'), (Match match) {
      return match.group(0).toUpperCase();
    });
    return part.replaceAll("-", "");
  }
}

@Injectable()
class ShadowRootEventHandler extends EventHandler {
  ShadowRootEventHandler(dom.ShadowRoot shadowRoot, Expando expando, ExceptionHandler excHandler)
      : super(shadowRoot, expando, excHandler);
}
