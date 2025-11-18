// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
        SnackBar(content: Text(response.message)),
      );
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _handleImageSelection() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galería'),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) await _uploadProfileImage(image);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) await _uploadProfileImage(image);
              },
            ),
            if (_user?.profileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                onTap: () => _deleteProfileImage(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    final response = await _userService.uploadProfileImage(imageFile);
    
    if (response.success && response.data != null) {
      setState(() => _user = response.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  Future<void> _deleteProfileImage() async {
    final response = await _userService.deleteProfileImage();
    
    if (response.success && response.data != null) {
      setState(() => _user = response.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text('Error al cargar perfil'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Foto de perfil
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _user!.profileImage != null
                    ? NetworkImage(_user!.profileImage!)
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
                child: _user!.profileImage == null
                    ? Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: _handleImageSelection,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Información del usuario
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Nombre', _user!.name),
                  _buildInfoRow('Teléfono', _user!.phone),
                  _buildInfoRow('Miembro desde', 
                    '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Opciones
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar perfil'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => _navigateToEditProfile(),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Cambiar contraseña'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => _navigateToChangePassword(),
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
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