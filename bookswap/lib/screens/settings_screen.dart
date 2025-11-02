// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/bottom_nav_bar.dart';

/// Screen displaying user settings and profile information.
/// Includes profile details, notification toggles, and logging out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser; // Access the current user data

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card to display user profile information
              Card(
                color: const Color(0xFF1E1E3C),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        title: Text(
                          user?.displayName ?? 'User', // Display the user's name
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          user?.email ?? 'No email', // Display the user's email
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      // Show email verification status and a button to resend
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            user?.isEmailVerified ?? false ? Icons.verified : Icons.warning,
                            color: user?.isEmailVerified ?? false ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.isEmailVerified ?? false ? 'Email Verified' : 'Email Not Verified',
                            style: TextStyle(
                              color: user?.isEmailVerified ?? false ? Colors.green : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!(user?.isEmailVerified ?? true)) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await authProvider.sendEmailVerification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Verification email sent! Please check your inbox.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              print('Error sending verification email: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to send verification email. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.email),
                          label: const Text('Resend Verification Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Changed from yellow (Colors.orange) to blue
                            foregroundColor: Colors.white, // Ensure text is white
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Consumer for NotificationProvider to manage reminder toggle
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return SwitchListTile(
                    title: const Text('Notification reminders'),
                    value: notificationProvider.reminderEnabled,
                    onChanged: (value) {
                      notificationProvider.setReminderEnabled(value); // Update provider and save
                    },
                    activeColor: Colors.blue, 
                  );
                },
              ),
              // Consumer for NotificationProvider to manage email updates toggle
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return SwitchListTile(
                    title: const Text('Email Updates'),
                    value: notificationProvider.emailUpdatesEnabled,
                    onChanged: (value) {
                      notificationProvider.setEmailUpdatesEnabled(value); // Update provider and save
                    },
                    activeColor: Colors.blue, 
                  );
                },
              ),
              // Dark Mode Toggle (already updated in previous step)
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(); // Toggle theme when switch is changed
                    },
                    activeColor: Colors.blue, 
                  );
                },
              ),
              // About section
              ListTile(
                title: const Text('About'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('About BookSwap'),
                      content: const Text('Swap books with other students easily.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              // Log Out button
              ListTile(
                title: const Text('Log Out'),
                trailing: const Icon(Icons.logout),
                onTap: () {
                  _showLogoutConfirmation(context);
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 3),
    );
  }

  /// Displays a confirmation dialog before logging the user out
  /// This prevents accidental logouts
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog without logging out
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Call the actual logout function after confirmation
              _performLogout(context);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  /// Performs the actual logout process
  /// 1. Calls signOut() on the AuthProvider
  /// 2. Closes the confirmation dialog
  /// 3. Navigates back to the welcome screen
  void _performLogout(BuildContext context) {
    // Get the AuthProvider instance and call its signOut method
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.signOut();

    // Close the confirmation dialog
    Navigator.pop(context);

    // Navigate to the welcome screen, replacing the current route stack
    // This ensures the user cannot navigate back to protected screens
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}