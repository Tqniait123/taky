import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _organizationColorKey = 'organization_primary_color';
  static const String _organizationSecondaryColorKey = 'organization_secondary_color';
  static const String _organizationNameKey = 'organization_name';

  static Future<void> saveOrganizationColors(int primaryColor, int secondaryColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_organizationColorKey, primaryColor);
    await prefs.setInt(_organizationSecondaryColorKey, secondaryColor);
  }

  static Future<void> saveOrganizationName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_organizationNameKey, name);
  }

  static Future<int?> getOrganizationPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_organizationColorKey);
  }

  static Future<int?> getOrganizationSecondaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_organizationSecondaryColorKey);
  }

  static Future<String?> getOrganizationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_organizationNameKey);
  }

  static Future<void> clearOrganizationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_organizationColorKey);
    await prefs.remove(_organizationSecondaryColorKey);
    await prefs.remove(_organizationNameKey);
  }
}