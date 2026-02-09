import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'database_helper.dart';

void main() {
  runApp(const CareNestApp());
}

class CareNestApp extends StatelessWidget {
  const CareNestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
          displayMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4A5568)),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4A5568)),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3498DB), Color(0xFF8E44AD)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_filled,
                          size: 100,
                          color: Color(0xFF3498DB),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'CareNest',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Connected Living, Caring Community',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both username and password', style: TextStyle(fontSize: 14)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _dbHelper.getUser(_usernameController.text);
      
      if (user != null && user['password'] == _passwordController.text) {
        // Login successful
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainDashboard(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password', style: TextStyle(fontSize: 14)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.', style: TextStyle(fontSize: 14)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3498DB), Color(0xFF2C3E50)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_filled,
                        size: 80,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome to CareNest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your Connected Community',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: const TextStyle(fontSize: 14),
                              prefixIcon: Icon(PhosphorIcons.user(), size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(fontSize: 14),
                              prefixIcon: Icon(PhosphorIcons.lock(), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6366F1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CommunityScreen(),
    const ActivitiesScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeInOut);
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIcons.warning(), color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text('Emergency Alert', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you experiencing an emergency? Help is on the way.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Create emergency alert in database
              try {
                final dbHelper = DatabaseHelper();
                await dbHelper.createEmergencyAlert({
                  'user_id': 1, // Hardcoded user ID for demo
                  'alert_type': 'emergency',
                  'message': 'Emergency alert triggered by user',
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency alert sent! Staff has been notified.', style: TextStyle(fontSize: 14)),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to send emergency alert', style: TextStyle(fontSize: 14)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Emergency', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showEmergencyDialog,
          backgroundColor: Colors.red,
          icon: Icon(PhosphorIcons.warning(), size: 20),
          label: const Text('Emergency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.house(), size: 20),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.users(), size: 20),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.calendar(), size: 20),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.chatCircle(), size: 20),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.user(), size: 20),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final activities = await _dbHelper.getActivities();
      final notifications = await _dbHelper.getNotifications(1); // Hardcoded user ID for demo
      
      setState(() {
        _activities = activities.take(3).toList(); // Show only 3 recent activities
        _notifications = notifications.take(3).toList(); // Show only 3 recent notifications
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.bell(), size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF8E44AD)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(PhosphorIcons.sun(), size: 24, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good Morning!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Welcome back to CareNest',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildQuickActionCard(
                    'Health Updates',
                    PhosphorIcons.heart(),
                    const Color(0xFFE74C3C),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HealthScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    'Events',
                    PhosphorIcons.calendar(),
                    const Color(0xFF9B59B6),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EventsScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    'Wellness',
                    PhosphorIcons.leaf(),
                    const Color(0xFF1ABC9C),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WellnessScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    'Family',
                    PhosphorIcons.usersThree(),
                    const Color(0xFFF39C12),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FamilyScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Recent Updates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 15),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ..._notifications.map((notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildUpdateCard(
                        notification['title'] ?? 'Notification',
                        notification['message'] ?? 'No message',
                        PhosphorIcons.bell(),
                        const Color(0xFF6366F1),
                      ),
                    )).toList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Feed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 20),
            _buildPostCard(
              'Sarah Johnson',
              '2 hours ago',
              'Had a wonderful time at today\'s gardening club! The roses are blooming beautifully.',
              Icons.local_florist,
              const Color(0xFFE91E63),
            ),
            const SizedBox(height: 15),
            _buildPostCard(
              'Robert Williams',
              '5 hours ago',
              'Looking forward to the book club meeting tomorrow. We\'re discussing "The Great Gatsby"!',
              Icons.menu_book,
              const Color(0xFF9C27B0),
            ),
            const SizedBox(height: 15),
            _buildPostCard(
              'Margaret Davis',
              'Yesterday',
              'Thank you everyone for the warm welcome! I\'m so happy to be part of this community.',
              Icons.favorite,
              const Color(0xFFFF5722),
            ),
            const SizedBox(height: 20),
            const Text(
              'Interest Groups',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildGroupCard('Book Club', Icons.auto_stories, 24, const Color(0xFF673AB7)),
            const SizedBox(height: 10),
            _buildGroupCard('Gardening Club', Icons.yard, 18, const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
            _buildGroupCard('Arts & Crafts', Icons.palette, 32, const Color(0xFFFF9800)),
            const SizedBox(height: 10),
            _buildGroupCard('Chess Club', Icons.castle, 15, const Color(0xFF795548)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF3498DB),
        icon: const Icon(Icons.add, size: 28),
        label: const Text('New Post', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildPostCard(String name, String time, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: const TextStyle(fontSize: 17, color: Color(0xFF34495E)),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_outlined, size: 22),
                label: const Text('Like', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 15),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.comment_outlined, size: 22),
                label: const Text('Comment', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String name, IconData icon, int members, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 5),
                Text(
                  '$members members',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Color(0xFFBDC3C7)),
        ],
      ),
    );
  }
}

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3498DB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 20),
            _buildEventCard(
              'Movie Night',
              'Friday, 7:00 PM',
              'Main Hall',
              'Classic film screening',
              Icons.movie,
              const Color(0xFF3498DB),
            ),
            const SizedBox(height: 15),
            _buildEventCard(
              'Yoga Class',
              'Monday, 9:00 AM',
              'Wellness Center',
              'Gentle stretching for all levels',
              Icons.self_improvement,
              const Color(0xFF1ABC9C),
            ),
            const SizedBox(height: 15),
            _buildEventCard(
              'Bingo Night',
              'Wednesday, 6:30 PM',
              'Recreation Room',
              'Prizes and refreshments',
              Icons.grid_4x4,
              const Color(0xFFF39C12),
            ),
            const SizedBox(height: 15),
            _buildEventCard(
              'Art Workshop',
              'Thursday, 2:00 PM',
              'Art Studio',
              'Watercolor painting basics',
              Icons.brush,
              const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 30),
            const Text(
              'Daily Schedule',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildScheduleItem('8:00 AM', 'Breakfast', Icons.restaurant),
            _buildScheduleItem('10:00 AM', 'Morning Exercise', Icons.directions_walk),
            _buildScheduleItem('12:00 PM', 'Lunch', Icons.lunch_dining),
            _buildScheduleItem('2:00 PM', 'Afternoon Activities', Icons.celebration),
            _buildScheduleItem('5:30 PM', 'Dinner', Icons.dinner_dining),
            _buildScheduleItem('7:00 PM', 'Evening Entertainment', Icons.theater_comedy),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, String time, String location, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 5),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 5),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF95A5A6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String activity, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF3498DB)),
          const SizedBox(width: 15),
          Text(
            time,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(fontSize: 17, color: Color(0xFF34495E)),
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3498DB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMessageCard(
            'Care Team',
            'Your wellness check is scheduled for tomorrow morning',
            '10 min ago',
            Icons.medical_services,
            const Color(0xFFE74C3C),
            true,
          ),
          const SizedBox(height: 10),
          _buildMessageCard(
            'Family - Emma',
            'Hi Mom! Hope you\'re having a great day. Love you!',
            '1 hour ago',
            Icons.family_restroom,
            const Color(0xFF9B59B6),
            true,
          ),
          const SizedBox(height: 10),
          _buildMessageCard(
            'Activity Coordinator',
            'Don\'t forget about movie night this Friday!',
            '2 hours ago',
            Icons.event,
            const Color(0xFF3498DB),
            false,
          ),
          const SizedBox(height: 10),
          _buildMessageCard(
            'Dining Services',
            'Tomorrow\'s lunch menu: Grilled chicken and vegetables',
            'Yesterday',
            Icons.restaurant_menu,
            const Color(0xFFF39C12),
            false,
          ),
          const SizedBox(height: 10),
          _buildMessageCard(
            'Community Manager',
            'Welcome to CareNest! Let us know if you need anything.',
            '2 days ago',
            Icons.home_filled,
            const Color(0xFF1ABC9C),
            false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF3498DB),
        icon: const Icon(Icons.create, size: 28),
        label: const Text('New Message', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildMessageCard(String sender, String message, String time, IconData icon, Color color, bool unread) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: unread ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: unread ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: unread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sender,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF7F8C8D),
                    fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3498DB),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3498DB), Color(0xFF8E44AD)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'John Anderson',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Resident since 2023',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoSection('Personal Information', [
              _buildInfoItem(Icons.cake, 'Date of Birth', 'March 15, 1948'),
              _buildInfoItem(Icons.room, 'Room Number', 'A-204'),
              _buildInfoItem(Icons.phone, 'Phone', '(555) 123-4567'),
              _buildInfoItem(Icons.email, 'Email', 'john.anderson@email.com'),
            ]),
            const SizedBox(height: 20),
            _buildInfoSection('Emergency Contacts', [
              _buildInfoItem(Icons.person, 'Emma Anderson (Daughter)', '(555) 987-6543'),
              _buildInfoItem(Icons.person, 'Michael Anderson (Son)', '(555) 456-7890'),
            ]),
            const SizedBox(height: 20),
            _buildInfoSection('Medical Information', [
              _buildInfoItem(Icons.local_hospital, 'Primary Doctor', 'Dr. Sarah Mitchell'),
              _buildInfoItem(Icons.medical_information, 'Blood Type', 'O+'),
              _buildInfoItem(Icons.healing, 'Allergies', 'Penicillin'),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 26),
                label: const Text('Edit Profile', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 15),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 26, color: const Color(0xFF3498DB)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF95A5A6)),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3498DB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotificationCard(
            'Wellness Check Reminder',
            'Your weekly wellness check is scheduled for tomorrow at 10 AM',
            '5 min ago',
            Icons.health_and_safety,
            const Color(0xFFE74C3C),
            true,
          ),
          const SizedBox(height: 10),
          _buildNotificationCard(
            'New Message',
            'You have a new message from Emma (Family)',
            '1 hour ago',
            Icons.message,
            const Color(0xFF9B59B6),
            true,
          ),
          const SizedBox(height: 10),
          _buildNotificationCard(
            'Event Reminder',
            'Movie Night starts in 2 hours - Main Hall',
            '3 hours ago',
            Icons.event,
            const Color(0xFF3498DB),
            false,
          ),
          const SizedBox(height: 10),
          _buildNotificationCard(
            'Medication Reminder',
            'Time to take your evening medication',
            'Yesterday',
            Icons.medication,
            const Color(0xFFF39C12),
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String title, String message, String time, IconData icon, Color color, bool unread) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: unread ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: unread ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: unread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Updates', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE74C3C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 60, color: Colors.white),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Health Status',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'All vitals normal',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Recent Vitals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildVitalCard('Blood Pressure', '120/80 mmHg', Icons.monitor_heart, const Color(0xFFE74C3C)),
            const SizedBox(height: 10),
            _buildVitalCard('Heart Rate', '72 bpm', Icons.favorite, const Color(0xFF9B59B6)),
            const SizedBox(height: 10),
            _buildVitalCard('Temperature', '98.6°F', Icons.thermostat, const Color(0xFF3498DB)),
            const SizedBox(height: 10),
            _buildVitalCard('Oxygen Level', '98%', Icons.air, const Color(0xFF1ABC9C)),
            const SizedBox(height: 30),
            const Text(
              'Upcoming Appointments',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildAppointmentCard(
              'Dr. Sarah Mitchell',
              'General Checkup',
              'Tomorrow, 10:00 AM',
              Icons.medical_services,
            ),
            const SizedBox(height: 10),
            _buildAppointmentCard(
              'Dr. James Wilson',
              'Cardiology Consultation',
              'Next Week, Wednesday 2:00 PM',
              Icons.monitor_heart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF95A5A6)),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(String doctor, String type, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 35, color: const Color(0xFFE74C3C)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 5),
                Text(
                  type,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF95A5A6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9B59B6),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLargeEventCard(
            'Annual Summer Festival',
            'Saturday, June 15th',
            '2:00 PM - 6:00 PM',
            'Outdoor Garden Area',
            'Join us for our biggest event of the year! Live music, food, games, and entertainment for everyone.',
            Icons.celebration,
            const Color(0xFF9B59B6),
          ),
          const SizedBox(height: 15),
          _buildLargeEventCard(
            'Classical Music Concert',
            'Friday, June 21st',
            '7:00 PM - 9:00 PM',
            'Main Auditorium',
            'Professional musicians performing beloved classical compositions.',
            Icons.music_note,
            const Color(0xFF3498DB),
          ),
          const SizedBox(height: 15),
          _buildLargeEventCard(
            'Cooking Class: Italian Cuisine',
            'Wednesday, June 26th',
            '3:00 PM - 5:00 PM',
            'Community Kitchen',
            'Learn to make authentic Italian pasta with our chef instructor.',
            Icons.restaurant,
            const Color(0xFFE74C3C),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeEventCard(String title, String date, String time, String location, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEventDetail(Icons.calendar_today, date),
          const SizedBox(height: 8),
          _buildEventDetail(Icons.access_time, time),
          const SizedBox(height: 8),
          _buildEventDetail(Icons.location_on, location),
          const SizedBox(height: 15),
          Text(
            description,
            style: const TextStyle(fontSize: 17, color: Color(0xFF7F8C8D), height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Register for Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF95A5A6)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 17, color: Color(0xFF34495E)),
        ),
      ],
    );
  }
}

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.spa, size: 60, color: Colors.white),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Wellness Journey',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Stay healthy and active',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Wellness Activities',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildWellnessCard(
              'Morning Yoga',
              'Daily at 8:00 AM',
              'Gentle stretches and breathing exercises',
              Icons.self_improvement,
              const Color(0xFF1ABC9C),
            ),
            const SizedBox(height: 10),
            _buildWellnessCard(
              'Walking Group',
              'Monday, Wednesday, Friday at 10:00 AM',
              'Leisurely walks around the facility',
              Icons.directions_walk,
              const Color(0xFF3498DB),
            ),
            const SizedBox(height: 10),
            _buildWellnessCard(
              'Meditation Session',
              'Tuesday and Thursday at 4:00 PM',
              'Mindfulness and relaxation',
              Icons.eco,
              const Color(0xFF9B59B6),
            ),
            const SizedBox(height: 10),
            _buildWellnessCard(
              'Water Aerobics',
              'Saturday at 11:00 AM',
              'Low-impact pool exercises',
              Icons.pool,
              const Color(0xFF3498DB),
            ),
            const SizedBox(height: 30),
            const Text(
              'Wellness Tips',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildTipCard('Stay hydrated - drink at least 8 glasses of water daily', Icons.local_drink),
            const SizedBox(height: 10),
            _buildTipCard('Get 7-8 hours of quality sleep each night', Icons.bedtime),
            const SizedBox(height: 10),
            _buildTipCard('Practice deep breathing for 5 minutes daily', Icons.air),
            const SizedBox(height: 10),
            _buildTipCard('Spend time outdoors when weather permits', Icons.wb_sunny),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessCard(String title, String schedule, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 5),
                Text(
                  schedule,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF95A5A6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF1ABC9C)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 17, color: Color(0xFF34495E)),
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF39C12),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, size: 60, color: Colors.white),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Family Connection',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Stay connected with loved ones',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Family Members',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildFamilyMemberCard(
              'Emma Anderson',
              'Daughter',
              'Last contact: Yesterday',
              Icons.person,
              const Color(0xFF9B59B6),
            ),
            const SizedBox(height: 10),
            _buildFamilyMemberCard(
              'Michael Anderson',
              'Son',
              'Last contact: 3 days ago',
              Icons.person,
              const Color(0xFF3498DB),
            ),
            const SizedBox(height: 10),
            _buildFamilyMemberCard(
              'Sophie Anderson',
              'Granddaughter',
              'Last contact: Last week',
              Icons.person,
              const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 30),
            const Text(
              'Shared Memories',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 15),
            _buildMemoryCard(
              'Family Dinner Photos',
              'Emma shared 5 new photos',
              '2 days ago',
              Icons.photo_library,
            ),
            const SizedBox(height: 10),
            _buildMemoryCard(
              'Birthday Video',
              'Michael sent a birthday message',
              'Last week',
              Icons.video_library,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.video_call, size: 28),
                label: const Text('Schedule Video Call', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39C12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(String name, String relation, String lastContact, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 5),
                Text(
                  relation,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                const SizedBox(height: 3),
                Text(
                  lastContact,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF95A5A6)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message, size: 28, color: Color(0xFF3498DB)),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(String title, String description, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: const Color(0xFFF39C12)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Color(0xFFBDC3C7)),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3498DB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'General',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 15),
          _buildSettingItem(Icons.text_fields, 'Text Size', 'Large', context),
          _buildSettingItem(Icons.volume_up, 'Sound', 'On', context),
          _buildSettingItem(Icons.vibration, 'Vibration', 'On', context),
          _buildSettingItem(Icons.language, 'Language', 'English', context),
          const SizedBox(height: 30),
          const Text(
            'Accessibility',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 15),
          _buildSettingItem(Icons.mic, 'Voice Commands', 'Enabled', context),
          _buildSettingItem(Icons.hearing, 'Hearing Aid Mode', 'Off', context),
          _buildSettingItem(Icons.contrast, 'High Contrast', 'Off', context),
          _buildSettingItem(Icons.record_voice_over, 'Text to Speech', 'On', context),
          const SizedBox(height: 30),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 15),
          _buildSettingItem(Icons.notifications, 'Push Notifications', 'On', context),
          _buildSettingItem(Icons.email, 'Email Notifications', 'On', context),
          _buildSettingItem(Icons.warning, 'Emergency Alerts', 'On', context),
          const SizedBox(height: 30),
          const Text(
            'Privacy & Security',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 15),
          _buildSettingItem(Icons.lock, 'Change Password', '', context),
          _buildSettingItem(Icons.privacy_tip, 'Privacy Settings', '', context),
          _buildSettingItem(Icons.shield, 'Security', '', context),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, size: 26),
              label: const Text('Sign Out', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String value, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF3498DB)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Color(0xFF95A5A6)),
            ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFFBDC3C7)),
        ],
      ),
    );
  }
}
