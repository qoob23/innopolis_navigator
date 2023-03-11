import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Navigator2Page extends StatelessWidget {
  const Navigator2Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationProvider: PlatformRouteInformationProvider(
        initialRouteInformation: const RouteInformation(),
      ),
      routeInformationParser: const MyRouteInformationParser(),
      routerDelegate: NavigationService.routerDelegate,
    );
  }
}

class Routes {
  static const first = 'first';
  static const second = 'second';
  static const third = 'third';
}

class NavigationState {
  static const initial = NavigationState([Routes.first]);

  const NavigationState(this.routes);

  final List<String> routes;

  @override
  bool operator ==(Object? other) {
    return other is NavigationState && listEquals(routes, other.routes);
  }

  @override
  int get hashCode => Object.hashAll(routes);
}

class MyRouteInformationParser extends RouteInformationParser<NavigationState> {
  const MyRouteInformationParser();

  @override
  Future<NavigationState> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final location = routeInformation.location;
    if (location == null) return NavigationState.initial;

    return NavigationState(location.split('/'));
  }

  @override
  RouteInformation? restoreRouteInformation(NavigationState configuration) {
    return RouteInformation(location: configuration.routes.join('/'));
  }
}

class MyRouterDelegate extends RouterDelegate<NavigationState>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  NavigationState _currentConfiguration = NavigationState.initial;

  @override
  NavigationState? get currentConfiguration => _currentConfiguration;

  @override
  Future<void> setNewRoutePath(NavigationState configuration) async {
    _currentConfiguration = configuration;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        for (final name in _currentConfiguration.routes) _matchPageByName(name),
      ],
      onPopPage: (route, result) {
        final currentRoutes = _currentConfiguration.routes;
        if (currentRoutes.length == 1) {
          // root page, nothing to pop
          return false;
        }
        final newRoutes = currentRoutes
            .where(
              (name) => name != route.settings.name,
            )
            .toList();

        setNewRoutePath(NavigationState(newRoutes));
        route.didPop(result);
        return true;
      },
    );
  }

  Page<dynamic> _matchPageByName(String name) {
    Widget pageContent;
    switch (name) {
      case Routes.first:
        pageContent = const FirstPage();
        break;
      case Routes.second:
        pageContent = const SecondPage();
        break;
      case Routes.third:
        pageContent = const ThirdPage();
        break;
      default:
        pageContent = FallbackPage(name: name);
        break;
    }

    return MaterialPage(child: pageContent, name: name);
  }

  Future<void> pushRoute(String name) {
    final currentRoutes = currentConfiguration!.routes;
    final newRoutes = [...currentRoutes, name];
    final newConfiguration = NavigationState(newRoutes);
    return setNewRoutePath(newConfiguration);
  }
}

class NavigationService {
  static final routerDelegate = MyRouterDelegate();

  static void pushRoute(String name) {
    routerDelegate.pushRoute(name);
  }

  static Future<bool> pop() {
    return routerDelegate.popRoute();
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'First',
        ),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            NavigationService.pushRoute(Routes.second);
          },
          child: const Text('Push'),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Second',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                NavigationService.pushRoute(Routes.third);
              },
              child: const Text('Push third'),
            ),
            TextButton(
              onPressed: () {
                NavigationService.pushRoute('404');
              },
              child: const Text('Push 404'),
            ),
            TextButton(
              onPressed: () {
                NavigationService.pop();
              },
              child: const Text('Pop'),
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdPage extends StatelessWidget {
  const ThirdPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Third',
        ),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            NavigationService.pop();
          },
          child: const Text('Pop'),
        ),
      ),
    );
  }
}

class FallbackPage extends StatelessWidget {
  const FallbackPage({Key? key, required this.name}) : super(key: key);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fallback ($name)'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Pop'),
        ),
      ),
    );
  }
}
