import 'package:auth_test/ui/views/auth/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthViewModel>.reactive(
      viewModelBuilder: AuthViewModel.new,
      builder: (context, model, child) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Auth View',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: model.signInWithGoogle,
                      child: model.isBusy
                          ? const CircularProgressIndicator()
                          : const Text('Sign in with google'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: model.signinWithApple,
                      child: model.isBusy
                          ? const CircularProgressIndicator()
                          : const Text('Sign in with Apple'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: model.signInAnonymously,
                      child: model.isBusy
                          ? const CircularProgressIndicator()
                          : const Text('Sign in Anonymously'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
