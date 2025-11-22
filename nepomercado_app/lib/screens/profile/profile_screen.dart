
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user.dart';
import '../../services/user_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    final response = await _userService.getMyProfile();
    
    if (response.success && response.data != null) {
      setState(() => _user = response.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFFE9965C), 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _handleImageSelection() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C5C).withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: Color(0xFF0F4C5C)),
                    const SizedBox(width: 12),
                    Text(
                      'Cambiar foto de perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F4C5C),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF3A9188)),
                title: Text(
                  'Galería',
                  style: TextStyle(color: Color(0xFF202124)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) await _uploadProfileImage(image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Color(0xFF3A9188)),
                title: Text(
                  'Cámara',
                  style: TextStyle(color: Color(0xFF202124)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) await _uploadProfileImage(image);
                },
              ),
              if (_user?.profileImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Color(0xFFE9965C)),
                  title: Text(
                    'Eliminar foto',
                    style: TextStyle(color: Color(0xFFE9965C)),
                  ),
                  onTap: () => _deleteProfileImage(),
                ),
              // Botón cancelar
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF0F4C5C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF0F4C5C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    final response = await _userService.uploadProfileImage(imageFile);
    
    if (response.success && response.data != null) {
      setState(() => _user = response.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFF3A9188), 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFFE9965C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _deleteProfileImage() async {
    final response = await _userService.deleteProfileImage();
    
    if (response.success && response.data != null) {
      setState(() => _user = response.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFF3A9188), 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFFE9965C), 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Color(0xFF202124),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)),
        foregroundColor: const Color(0xFF0F4C5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF3A9188)),
            onPressed: _loadUserProfile,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EDE4), 
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0F4C5C),
              ),
            )
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Color(0xFFE9965C)),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar perfil',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF0F4C5C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: _loadUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A9188),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Foto de perfil
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3A9188),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _user!.profileImage != null
                      ? CachedNetworkImage(
                          imageUrl: _user!.profileImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF4EDE4),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF3A9188),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF4EDE4),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF3A9188),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF4EDE4),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF3A9188),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A9188),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    onPressed: _handleImageSelection,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Información del usuario
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow('Nombre', _user!.name),
                  const Divider(color: Color(0xFFF4EDE4)),
                  _buildInfoRow('Teléfono', _user!.phone ?? 'No especificado'),
                  const Divider(color: Color(0xFFF4EDE4)),
                  _buildInfoRow('Miembro desde', 
                    '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Opciones
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: Color(0xFF3A9188)),
                  title: Text(
                    'Editar perfil',
                    style: TextStyle(color: Color(0xFF202124)),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF3A9188)),
                  onTap: () => _navigateToEditProfile(),
                ),
                const Divider(height: 1, color: Color(0xFFF4EDE4)),
                ListTile(
                  leading: Icon(Icons.lock, color: Color(0xFF3A9188)),
                  title: Text(
                    'Cambiar contraseña',
                    style: TextStyle(color: Color(0xFF202124)),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF3A9188)),
                  onTap: () => _navigateToChangePassword(),
                ),
              ],
            ),
          ),

          // Información adicional
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C5C).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Color(0xFF0F4C5C), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu perfil verificado te ayuda a generar confianza con otros usuarios',
                    style: TextStyle(
                      color: Color(0xFF0F4C5C),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F4C5C),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _user!),
      ),
    );
    
    if (result == true) {
      _loadUserProfile(); // Recargar si se actualizó
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
    );
  }
}