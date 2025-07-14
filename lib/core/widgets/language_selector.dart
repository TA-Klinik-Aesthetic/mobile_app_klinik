import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_export.dart';
import '../services/language_service.dart';

class LanguageSelector extends StatefulWidget {
  final bool showAsButton;
  final VoidCallback? onLanguageChanged;
  
  const LanguageSelector({
    super.key,
    this.showAsButton = false,
    this.onLanguageChanged,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  bool _isExpanded = false;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language') ?? 'en';
    
    if (mounted) {
      setState(() {
        _currentLanguage = savedLanguage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAsButton) {
      return _buildFloatingSelector();
    } else {
      return _buildDropdownSelector();
    }
  }

  Widget _buildFloatingSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(_isExpanded ? 12 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: appTheme.orange200.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: _isExpanded ? _buildExpandedSelector() : _buildCollapsedButton(),
    );
  }

  Widget _buildCollapsedButton() {
    // Get current language flag and code
    String currentFlag = _currentLanguage == 'id' ? '🇮🇩' : '🇺🇸';
    String currentCode = _currentLanguage.toUpperCase();
    
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: appTheme.whiteA700.withAlpha((0.6 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appTheme.black900, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentFlag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              currentCode,
              style: TextStyle(
                color: appTheme.black900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_right,
              size: 18,
              color: appTheme.black900,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('🇺🇸', 'en', 'EN'),
          const SizedBox(width: 8),
          _buildLanguageOption('🇮🇩', 'id', 'ID'),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = false;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String langCode, String name) {
    final isSelected = _currentLanguage == langCode;
    
    return InkWell(
      onTap: () async {
        if (!isSelected) {
          await _changeLanguage(langCode);
        }
        
        setState(() {
          _isExpanded = false;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appTheme.orange200 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: appTheme.orange200, width: 1)
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : appTheme.orange200,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSelector() {
    final languages = LanguageService.getSupportedLanguages();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: appTheme.whiteA700.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentLanguage,
          icon: Icon(Icons.language, color: theme.colorScheme.primary),
          style: TextStyle(color: theme.colorScheme.primary),
          items: languages.map((language) {
            return DropdownMenuItem<String>(
              value: language.code,
              child: Row(
                children: [
                  Text(language.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(language.name, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newLanguage) {
            if (newLanguage != null && newLanguage != _currentLanguage) {
              _changeLanguage(newLanguage);
            }
          },
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      print('🔄 Starting language change to: $languageCode');
      
      // 1. Update current language state immediately
      setState(() {
        _currentLanguage = languageCode;
      });

      // 2. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
      print('✅ Saved to SharedPreferences: $languageCode');

      // 3. Update AppLocalization
      await AppLocalization.setLanguage(languageCode);
      print('✅ Updated AppLocalization: $languageCode');

      // 4. Show confirmation immediately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageCode == 'id' 
                  ? 'Bahasa diubah ke Indonesia' 
                  : 'Language changed to English',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: appTheme.lightGreen,
          ),
        );
      }

      // 5. Notify parent to rebuild IMMEDIATELY
      if (widget.onLanguageChanged != null) {
        print('🔄 Triggering parent rebuild...');
        widget.onLanguageChanged!();
      }

      print('✅ Language changed successfully to: $languageCode');
    } catch (e) {
      print('❌ Error changing language: $e');
    }
  }
}