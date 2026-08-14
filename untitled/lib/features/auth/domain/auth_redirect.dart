String? authRedirect({required bool signedIn, required String location}) {
  final onLogin = location == '/login';
  if (!signedIn) return onLogin ? null : '/login';
  if (onLogin) return '/home';
  return null;
}
