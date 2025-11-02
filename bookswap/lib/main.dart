// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/post_book_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/edit_book_screen.dart';
import 'models/book_model.dart';

//Initializes Firebase and sets up the main app structure with providers.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BookSwapApp());
}

class BookSwapApp extends StatelessWidget {
  const BookSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()), // Notification provider
      ],
      child: Consumer<ThemeProvider>( // Consumer to watch for theme changes
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'BookSwap',
            theme: themeProvider.currentTheme, // Apply the current theme
            debugShowCheckedModeBanner: false,
            home: const WelcomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/mylistings': (context) => const MyListingsScreen(),
              '/chat': (context) => const ChatScreen(),
              '/profile': (context) => const SettingsScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/post_book': (context) => const PostBookScreen(),
              '/forgot_password': (context) => const ForgotPasswordScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/book_detail') {
                final BookListing book = settings.arguments as BookListing;
                return MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: book),
                );
              } else if (settings.name == '/edit_book') {
                final BookListing book = settings.arguments as BookListing;
                return MaterialPageRoute(
                  builder: (context) => EditBookScreen(book: book),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}