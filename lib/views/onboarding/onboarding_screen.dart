import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../home/home_screen.dart';
import '../../providers/user_provider.dart';
// Make sure this import path is correct for your project structure
import 'onboarding_logic.dart';

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~ REUSABLE WIDGET (Self-Contained) ~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class SearchableDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> items;
  final Function(String) onSelected;
  final String? initialValue;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.initialValue,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _filteredItems = widget.items;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });

    _controller.addListener(() {
      _filterItems(_controller.text);
    });
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
      });
    } else {
      setState(() {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
    // Rebuild overlay with new filtered items
    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    if (mounted && _focusNode.hasFocus) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 8.0,
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return InkWell(
                    onTap: () {
                      _controller.text = item;
                      widget.onSelected(item);
                      _focusNode.unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(widget.icon, color: Colors.grey[400], size: 22),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFDC2626),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~ MAIN ONBOARDING SCREEN WIDGET ~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers and state
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final _usernameFormKey = GlobalKey<FormState>();
  final _nameFormKey = GlobalKey<FormState>();

  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedGender; // Added state for gender

  // Username checking state
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  String? _usernameError;
  Timer? _debounceTimer;
  List<String> _usernameSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUserData();
    _setupUsernameListener();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      _displayNameController.text = user!.displayName!;
      _usernameSuggestions = OnboardingLogic.generateUsernameSuggestions(
        user.displayName!,
      );
    }
  }

  void _setupUsernameListener() {
    _usernameController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _checkUsernameAvailability();
      });
    });
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = null;
      });
      return;
    }

    // Validate format first
    final formatError = OnboardingLogic.validateUsername(username);
    if (formatError != null) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = formatError;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await OnboardingLogic.isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = isAvailable;
          _usernameError = isAvailable ? null : 'Username is already taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = false;
          _usernameError = 'Error checking username';
        });
      }
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await OnboardingLogic.completeOnboarding(
        username: _usernameController.text.trim(),
        department: _selectedDepartment!,
        year: _selectedYear!,
        gender: _selectedGender!, // Pass the selected gender
        displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
      );

      _showCustomSnackBar('Welcome to Sidekick! 🎉', true);

      // Refresh user provider
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await userProvider.fetchUserData(user.uid);
        }
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      _showCustomSnackBar('Setup failed: ${e.toString()}', false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCustomSnackBar(String message, bool isSuccess) {
    final size = MediaQuery.of(context).size;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.02,
        ),
        content: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.02,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(size.width * 0.03),
            border: Border.all(
              color: isSuccess ? const Color(0xFFDC2626) : Colors.orange,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.015),
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFDC2626) : Colors.orange,
                  borderRadius: BorderRadius.circular(size.width * 0.015),
                ),
                child: Icon(
                  isSuccess ? Icons.check : Icons.info_outline,
                  color: Colors.white,
                  size: size.width * 0.04,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 0) {
      _navigateToPage(1);
    } else if (_currentPage == 1) {
      if (_nameFormKey.currentState!.validate()) {
        _navigateToPage(2);
      }
    } else if (_currentPage == 2) {
      if (_usernameFormKey.currentState!.validate() && _isUsernameAvailable) {
        _navigateToPage(3);
      } else if (!_isUsernameAvailable) {
        _showCustomSnackBar('Please choose an available username', false);
      }
    } else if (_currentPage == 3) {
      // New gender page logic
      if (_selectedGender != null) {
        _navigateToPage(4);
      } else {
        _showCustomSnackBar('Please select your gender', false);
      }
    } else if (_currentPage == 4) {
      // Final page
      if (_selectedDepartment != null && _selectedYear != null) {
        _completeOnboarding();
      } else {
        _showCustomSnackBar('Please select your department and year', false);
      }
    }
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _resetAnimations();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _navigateToPage(_currentPage - 1);
    }
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final contentWidth = isTablet ? 500.0 : size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                _buildHeader(size, isTablet, user),
                _buildProgressBar(size),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent manual swipe
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildWelcomePage(size, isTablet),
                      _buildNamePage(size, isTablet),
                      _buildUsernamePage(size, isTablet),
                      _buildGenderPage(size, isTablet), // New page added
                      _buildDetailsPage(size, isTablet),
                    ],
                  ),
                ),
                _buildNavigation(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size, bool isTablet, User? user) {
    return Padding(
      padding: EdgeInsets.all(size.width * 0.05),
      child: Row(
        children: [
          if (user != null) ...[
            CircleAvatar(
              radius: size.width * 0.045,
              backgroundColor: const Color(0xFF1C1C1E),
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? Icon(
                      Icons.person,
                      size: size.width * 0.05,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getHeaderTitle(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getHeaderSubtitle(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: size.width * 0.032,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.03,
              vertical: size.height * 0.008,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(size.width * 0.04),
            ),
            child: Text(
              '${_currentPage + 1}/5', // Updated page count
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: size.width * 0.03,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentPage) {
      case 0:
        return 'Welcome! 👋';
      case 1:
        return 'What\'s your name?';
      case 2:
        return 'Pick a username';
      case 3:
        return 'What\'s your gender?'; // New header title
      case 4:
        return 'Almost done!'; // Page number shifted
      default:
        return 'Setup';
    }
  }

  String _getHeaderSubtitle() {
    switch (_currentPage) {
      case 0:
        return 'Let\'s get you set up';
      case 1:
        return 'How should we call you?';
      case 2:
        return 'Choose something unique';
      case 3:
        return 'This helps personalize your experience'; // New subtitle
      case 4:
        return 'Tell us about your studies'; // Page number shifted
      default:
        return 'Setting up your profile';
    }
  }

  Widget _buildProgressBar(Size size) {
    return Container(
      height: size.height * 0.003,
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(size.height * 0.0015),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width:
                size.width *
                0.9 *
                ((_currentPage + 1) / 5), // Updated page count
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(size.height * 0.0015),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(Size size, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: size.width * (isTablet ? 0.2 : 0.3),
                height: size.width * (isTablet ? 0.2 : 0.3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(size.width * 0.075),
                  border: Border.all(color: const Color(0xFFDC2626), width: 2),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: size.width * (isTablet ? 0.1 : 0.15),
                  color: const Color(0xFFDC2626),
                ),
              ),
              SizedBox(height: size.height * 0.06),
              Text(
                'Welcome to Sidekick',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.06 : 0.08),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                'Your PSG Tech community',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.035 : 0.045),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.04),
              Text(
                'Connect with classmates, join study groups, and never miss what\'s happening on campus.',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.03 : 0.04),
                  color: Colors.grey[500],
                  height: 1.5,
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNamePage(Size size, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Form(
            key: _nameFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s your name?',
                  style: TextStyle(
                    fontSize: size.width * (isTablet ? 0.055 : 0.07),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  'This is how others will see you',
                  style: TextStyle(
                    fontSize: size.width * (isTablet ? 0.03 : 0.04),
                    color: Colors.grey[400],
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: size.height * 0.06),
                TextFormField(
                  controller: _displayNameController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * (isTablet ? 0.035 : 0.045),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: size.width * (isTablet ? 0.03 : 0.04),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.grey[400],
                      size: size.width * (isTablet ? 0.05 : 0.06),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      borderSide: const BorderSide(
                        color: Color(0xFFDC2626),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.025,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernamePage(Size size, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Form(
            key: _usernameFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.08),
                Text(
                  'Pick a username',
                  style: TextStyle(
                    fontSize: size.width * (isTablet ? 0.055 : 0.07),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  'Choose something unique and memorable',
                  style: TextStyle(
                    fontSize: size.width * (isTablet ? 0.03 : 0.04),
                    color: Colors.grey[400],
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: size.height * 0.06),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * (isTablet ? 0.035 : 0.045),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'username',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: size.width * (isTablet ? 0.03 : 0.04),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixText: '@',
                    prefixStyle: TextStyle(
                      color: const Color(0xFFDC2626),
                      fontSize: size.width * (isTablet ? 0.035 : 0.045),
                      fontWeight: FontWeight.w600,
                    ),
                    suffixIcon: _isCheckingUsername
                        ? Padding(
                            padding: EdgeInsets.all(size.width * 0.03),
                            child: SizedBox(
                              width: size.width * 0.04,
                              height: size.width * 0.04,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          )
                        : _isUsernameAvailable &&
                              _usernameController.text.isNotEmpty
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: size.width * 0.06,
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      borderSide: BorderSide(
                        color: _usernameError != null
                            ? Colors.red
                            : const Color(0xFF2C2C2E),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      borderSide: BorderSide(
                        color: _usernameError != null
                            ? Colors.red
                            : const Color(0xFF2C2C2E),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      borderSide: BorderSide(
                        color: _usernameError != null
                            ? Colors.red
                            : const Color(0xFFDC2626),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.025,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    final error = OnboardingLogic.validateUsername(value);
                    if (error != null) return error;
                    if (_usernameError != null) {
                      return _usernameError;
                    }
                    if (!_isUsernameAvailable) {
                      return 'Username is not available';
                    }
                    return null;
                  },
                ),
                if (_usernameError != null ||
                    (_isUsernameAvailable &&
                        _usernameController.text.isNotEmpty)) ...[
                  SizedBox(height: size.height * 0.015),
                  Row(
                    children: [
                      Icon(
                        _usernameError != null
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _usernameError != null
                            ? Colors.red
                            : Colors.green,
                        size: size.width * 0.04,
                      ),
                      SizedBox(width: size.width * 0.02),
                      Expanded(
                        child: Text(
                          _usernameError ?? 'Username is available!',
                          style: TextStyle(
                            color: _usernameError != null
                                ? Colors.red
                                : Colors.green,
                            fontSize: size.width * 0.032,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_usernameSuggestions.isNotEmpty &&
                    _usernameController.text.isEmpty) ...[
                  SizedBox(height: size.height * 0.04),
                  Text(
                    'Suggestions based on your name:',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  Wrap(
                    spacing: size.width * 0.02,
                    runSpacing: size.height * 0.01,
                    children: _usernameSuggestions.map((suggestion) {
                      return GestureDetector(
                        onTap: () {
                          _usernameController.text = suggestion;
                          _checkUsernameAvailability();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.03,
                            vertical: size.height * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(
                              size.width * 0.05,
                            ),
                            border: Border.all(color: const Color(0xFF2C2C2E)),
                          ),
                          child: Text(
                            '@$suggestion',
                            style: TextStyle(
                              color: const Color(0xFFDC2626),
                              fontSize: size.width * 0.032,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ~~~~~ NEW GENDER SELECTION PAGE ~~~~~
  Widget _buildGenderPage(Size size, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us your gender',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.055 : 0.07),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                'This helps in tailoring your app experience.',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.03 : 0.04),
                  color: Colors.grey[400],
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: size.height * 0.08),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGenderCard(size, 'Male', Icons.male_rounded),
                  SizedBox(width: size.width * 0.05),
                  _buildGenderCard(size, 'Female', Icons.female_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(Size size, String gender, IconData icon) {
    final bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size.width * 0.35,
        height: size.width * 0.35,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDC2626).withOpacity(0.15)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(size.width * 0.06),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDC2626)
                : const Color(0xFF2C2C2E),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: size.width * 0.12,
              color: isSelected ? const Color(0xFFDC2626) : Colors.grey[400],
            ),
            SizedBox(height: size.height * 0.015),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Widget _buildDetailsPage(Size size, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.08),
              Text(
                'Almost done!',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.055 : 0.07),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                'Tell us about your studies at PSG Tech',
                style: TextStyle(
                  fontSize: size.width * (isTablet ? 0.03 : 0.04),
                  color: Colors.grey[400],
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: size.height * 0.06),
              SearchableDropdown(
                label: 'Department',
                hint: 'Type or select your department',
                icon: Icons.school_outlined,
                items: OnboardingLogic.departments,
                onSelected: (value) {
                  setState(() => _selectedDepartment = value);
                },
              ),
              SizedBox(height: size.height * 0.03),
              SearchableDropdown(
                label: 'Year of Study',
                hint: 'Type or select your year',
                icon: Icons.calendar_today_outlined,
                items: OnboardingLogic.years,
                onSelected: (value) {
                  setState(() => _selectedYear = value);
                },
              ),
              SizedBox(height: size.height * 0.04),
              Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(size.width * 0.04),
                  border: Border.all(color: const Color(0xFF2C2C2E)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: size.width * 0.08,
                      height: size.width * 0.08,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(size.width * 0.02),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        color: const Color(0xFFDC2626),
                        size: size.width * 0.045,
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect with your batch',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * (isTablet ? 0.025 : 0.035),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: size.height * 0.005),
                          Text(
                            'We\'ll help you find classmates and study groups from your department and year.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: size.width * (isTablet ? 0.022 : 0.032),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.05,
        0,
        size.width * 0.05,
        size.height * 0.04,
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _isLoading ? null : _previousPage,
              child: Container(
                width: size.width * 0.12,
                height: size.width * 0.12,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(size.width * 0.06),
                  border: Border.all(color: const Color(0xFF2C2C2E)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: size.width * 0.05,
                ),
              ),
            )
          else
            SizedBox(width: size.width * 0.12),
          const Spacer(),
          GestureDetector(
            onTap: _isLoading ? null : _nextPage,
            child: Container(
              height: size.height * 0.07,
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(size.height * 0.035),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.25),
                    blurRadius: size.width * 0.05,
                    offset: Offset(0, size.height * 0.01),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading) ...[
                    SizedBox(
                      width: size.width * 0.05,
                      height: size.width * 0.05,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                  ],
                  Text(
                    _getButtonText(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (!_isLoading) ...[
                    SizedBox(width: size.width * 0.02),
                    Icon(
                      _currentPage == 4 ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                      size: size.width * 0.05,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Get Started';
      case 1:
      case 2:
      case 3: // Updated button text logic
        return 'Continue';
      case 4:
        return 'Complete Setup';
      default:
        return 'Next';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
