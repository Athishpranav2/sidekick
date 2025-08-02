import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearController = TextEditingController();
  final _departmentSearchController = TextEditingController();

  bool _isLoading = false;
  String? _selectedDepartment;
  String? _selectedYear;
  List<String> _filteredDepartments = [];

  final List<String> _departments = [
    'Computer Science and Engineering',
    'Electronics and Communication Engineering',
    'Electrical and Electronics Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Aeronautical Engineering',
    'Automobile Engineering',
    'Biomedical Engineering',
    'Chemical Engineering',
    'Information Technology',
    'Production Engineering',
    'Textile Technology',
    'Applied Electronics and Instrumentation',
    'Fashion Design and Technology',
    'Computer Applications (MCA)',
    'Business Administration (MBA)',
  ];

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Graduate',
  ];

  @override
  void initState() {
    super.initState();
    _filteredDepartments = _departments;
    _initializeFields();
  }

  void _initializeFields() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _selectedDepartment = user.department;
      _selectedYear = user.year;
      _departmentController.text = user.department ?? '';
      _yearController.text = user.year ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    _departmentSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<UserProvider>().updateProfile(
        displayName: _nameController.text.trim(),
        department: _selectedDepartment,
        year: _selectedYear,
      );

      if (mounted) {
        // Haptic feedback for successful save
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildNavigationBar(),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 44,
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CupertinoActivityIndicator(
                          color: Color(0xFF007AFF),
                        ),
                      )
                    : const Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.systemRed,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),
            _buildFormGroup([
              _buildTextInputCell(
                controller: _nameController,
                placeholder: 'Full Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Academic Information'),
            const SizedBox(height: 16),
            _buildFormGroup([
              _buildPickerCell(
                label: 'Department',
                value: _selectedDepartment,
                placeholder: 'Select Department',
                onTap: () => _showDepartmentPicker(),
              ),
              _buildDivider(),
              _buildPickerCell(
                label: 'Year',
                value: _selectedYear,
                placeholder: 'Select Year',
                onTap: () => _showYearPicker(),
              ),
            ]),
            const SizedBox(height: 100), // Extra space for better scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFormGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextInputCell({
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        validator: validator,
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildPickerCell({
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  color: value != null ? Colors.white : const Color(0xFF8E8E93),
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 0.5,
      color: const Color(0xFF38383A),
    );
  }

  void _showDepartmentPicker() {
    HapticFeedback.selectionClick();
    _departmentSearchController.clear();
    setState(() {
      _filteredDepartments = _departments;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => _buildDepartmentSearchModal(),
    );
  }

  void _filterDepartments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDepartments = _departments;
      } else {
        _filteredDepartments = _departments
            .where((dept) => dept.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showYearPicker() {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => _buildIOSPicker(
        title: 'Year',
        items: _years,
        selectedValue: _selectedYear,
        onSelectedItemChanged: (int selectedIndex) {
          setState(() {
            _selectedYear = _years[selectedIndex];
            _yearController.text = _selectedYear!;
          });
        },
      ),
    );
  }

  Widget _buildDepartmentSearchModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF38383A), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Text(
                  'Select Department',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _departmentSearchController,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                decoration: const InputDecoration(
                  hintText: 'Search departments...',
                  hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 17),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterDepartments,
              ),
            ),
          ),
          // Department list
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredDepartments.length,
              itemBuilder: (context, index) {
                final department = _filteredDepartments[index];
                final isSelected = department == _selectedDepartment;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFDC2626).withOpacity(0.1)
                        : null,
                  ),
                  child: ListTile(
                    title: Text(
                      department,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFDC2626)
                            : Colors.white,
                        fontSize: 17,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: AppColors.systemRed,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDepartment = department;
                        _departmentController.text = department;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSPicker({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    int initialIndex = selectedValue != null ? items.indexOf(selectedValue) : 0;
    if (initialIndex == -1) initialIndex = 0;

    return Container(
      height: 320,
      padding: const EdgeInsets.only(top: 6.0),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      color: const Color(0xFF1C1C1E),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF38383A), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.systemRed,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: const Color(0xFF1C1C1E),
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex,
                ),
                onSelectedItemChanged: onSelectedItemChanged,
                children: items.map((String item) {
                  return Center(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
