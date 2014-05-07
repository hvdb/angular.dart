part of angular.mock;

/**
 * Class which simplifies bootstraping of angular for unit tests.
 *
 * Simply inject [TestBed] into the test, then use [compile] to
 * match directives against the view.
 */
class TestBed {
  final Injector injector;
  final DirectiveInjector directiveInjector;
  final Scope rootScope;
  final Compiler compiler;
  final Parser _parser;
  final Expando expando;
  final EventHandler _eventHandler;

  Element rootElement;
  List<Node> rootElements;
  View rootView;

  TestBed(this.injector, this.directiveInjector, this.rootScope, this.compiler,
          this._parser, this.expando, this._eventHandler);
  TestBed.fromInjector(Injector i) :
    this(i, i.get(DirectiveInjector), i.get(RootScope), i.get(Compiler),
        i.get(Parser), i.get(Expando), i.get(EventHandler));


  /**
   * Use to compile HTML and activate its directives.
   *
   * If [html] parameter is:
   *
   *   - [String] then treat it as HTML
   *   - [Node] then treat it as the root node
   *   - [List<Node>] then treat it as a collection of nods
   *
   * After the compilation the [rootElements] contains an array of compiled root nodes,
   * and [rootElement] contains the first element from the [rootElemets].
   *
   * An option [scope] parameter can be supplied to link it with non root scope.
   */
  Element compile(html, {Scope scope, DirectiveMap directives}) {
    if (scope == null) scope = rootScope;
    if (html is String) {
      rootElements = toNodeList(html);
    } else if (html is Node) {
      rootElements = [html];
    } else if (html is List<Node>) {
      rootElements = html;
    } else {
      throw 'Expecting: String, Node, or List<Node> got $html.';
    }
    rootElement = rootElements.length > 0 && rootElements[0] is Element ? rootElements[0] : null;
    if (directives == null) {
      directives = injector.getByKey(DIRECTIVE_MAP_KEY);
    }
    rootView = compiler(rootElements, directives)(scope, injector.get(DirectiveInjector), rootElements);
    return rootElement;
  }

  /**
   * Convert an [html] String to a [List] of [Element]s.
   */
  List<Element> toNodeList(html) {
    var div = new DivElement();
    div.setInnerHtml(html, treeSanitizer: new NullTreeSanitizer());
    var nodes = [];
    for (var node in div.nodes) {
      nodes.add(node);
    }
    return nodes;
  }

  /**
   * Trigger a specific DOM element on a given node to test directives
   * which listen to events.
   */
  triggerEvent(element, {name, type : 'MouseEvent', event}) {
    var e = event == null ? new Event.eventType(type, name) : event;
    element.dispatchEvent(e);
    if (!_isAttachedToRenderDOM(element)) _eventHandler.walkDomTreeAndExecute(element, e);
    // Since we are manually triggering event we need to simulate apply();
    rootScope.apply();
  }

  /**
   * Select an [OPTION] in a [SELECT] with a given name and trigger the
   * appropriate DOM event. Used when testing [SELECT] controlls in forms.
   */
  selectOption(element, text) {
    element.querySelectorAll('option').forEach((o) => o.selected = o.text == text);
    triggerEvent(element, name: 'change');
    rootScope.apply();
  }

  getProbe(Node node) {
    while (node != null) {
      ElementProbe probe = expando[node];
      if (probe != null) return probe;
      node = node.parent;
    }
    throw 'Probe not found.';
  }

  getScope(Node node) => getProbe(node).scope;

  bool _isAttachedToRenderDOM(Node node) {
    var doc = window.document;
    while (node != doc) {
      if (node == null) return false;
      node = node.parentNode;
    }
    return true;
  }
}
