String routeFromMessage(Map<String, dynamic> data) {
  final route = (data['route'] as String?) ?? '/';
  return route.startsWith('/') ? route : '/$route';
}
