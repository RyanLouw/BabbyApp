import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
class AuthScreen extends ConsumerStatefulWidget { const AuthScreen({super.key}); @override ConsumerState<AuthScreen> createState() => _AuthScreenState(); }
class _AuthScreenState extends ConsumerState<AuthScreen> {
  final email = TextEditingController(), password = TextEditingController(); bool register = false, busy = false; String? error;
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async { setState(() {busy=true; error=null;}); try { final repo=ref.read(authRepositoryProvider); if(register) { await repo.register(email.text,password.text); } else { await repo.signIn(email.text,password.text); } if(mounted) context.go('/home'); } on Exception { setState(() => error='We could not sign you in. Check your details and try again.'); } finally {if(mounted)setState(()=>busy=false);} }
  @override Widget build(context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Icon(Icons.child_friendly, size: 64, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text('Babby Care', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center), const Text('Calm care tracking, together.', textAlign: TextAlign.center), const SizedBox(height: 32),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText:'Email')),
    const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText:'Password')),
    if(error!=null) Padding(padding: const EdgeInsets.only(top:12),child:Text(error!, style: TextStyle(color:Theme.of(context).colorScheme.error))), const SizedBox(height: 20),
    FilledButton(onPressed: busy?null:submit, child: busy?const SizedBox.square(dimension:24,child:CircularProgressIndicator()):Text(register?'Create account':'Sign in')),
    TextButton(onPressed: ()=>setState(()=>register=!register), child: Text(register?'Already have an account? Sign in':'New here? Create account')),
    TextButton(onPressed: ()=>ref.read(authRepositoryProvider).reset(email.text), child: const Text('Forgot password?')),
  ]))))));
}
