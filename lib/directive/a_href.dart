part of angular.directive;

/**
 * Modifies the default behavior of the HTML `<a>` element to prevent navigation from the current page when the `href`
 * attribute is empty. `Selector: a[href]`
 *
 * This change permits the easy creation of action links with the [OnClick] directive, without changing the location
 * or causing a page reload.
 *
 * # Example
 *
 *     <a href="" ng-click="model.save()">Save</a>
 */
@Decorator(selector: 'a[href]')
class AHref {
  final dom.Element element;
  final NgElement ngElement;

  AHref(this.element, this.ngElement, VmTurnZone zone) {
    if (element.attributes["href"] == "") {
      zone.runOutsideAngular(() {
        ngElement.addEventListener('click', (event) {
          if (element.attributes["href"] == "") {
            event.preventDefault();
          }
        });
      });
    }
  }
}
