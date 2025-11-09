// Add this method to show password reset dialog
void _showResetPasswordDialog(BuildContext context) {
  final emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email address',
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            await authProvider.resetPassword(emailController.text.trim());
            Navigator.pop(context);

            if (authProvider.error == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent!')),
              );
            }
          },
          child: const Text('SEND'),
        ),
      ],
    ),
  );
}
