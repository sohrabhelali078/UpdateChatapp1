import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:client/constants/app_colors.dart';
import 'package:client/helpers/asset_images.dart';
import 'package:client/helpers/socket_io.dart';
import 'package:client/services/chat_service.dart';
import 'package:client/services/group_service.dart';
import 'package:client/widgets/button_widget.dart';
import 'package:client/widgets/item_group_widget.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async'; // Import for Timer

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.token});

  final String token;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List chats = [];
  List users = [];
  Map<String, dynamic> userInfo = {};
  bool fetchAgain = false;
  String groupName = '';
  List<String> selectedMembers = [];
  Timer? _timer; // Timer to periodically fetch messages

  @override
  void initState() {
    super.initState();
    userInfo = JwtDecoder.decode(widget.token);
    fetchChats();
    fetchUsers();
    _startMessagePolling();
    socket.emit('join-chat', 'all');
    socket.on('all', (data) {
      if (mounted) {
        setState(() {
          fetchAgain = data;
        });
      }
    });
  }

  void _startMessagePolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchChats();
    });
  }

  Future<void> fetchChats() async {
    final response = await GroupService.fetchGroups();
    final List fetchedChats = jsonDecode(response.body);
    // Filter chats where the logged-in user is a member
    setState(() {
      chats = fetchedChats.where((chat) {
        final List members = chat['members'] ?? [];
        return members.contains(userInfo['_id']);
      }).toList();
    });
  }

  Future<void> fetchUsers() async {
    final response = await GroupService.fetchUsers();
    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    } else {
      // Handle error
      print('Failed to fetch users');
    }
  }

  void _createGroup() async {
    if (groupName.isNotEmpty && selectedMembers.isNotEmpty) {
      // Add the current user to the list of selected members
      selectedMembers.add(userInfo['_id']);
      final response = await GroupService.createGroup({
        'name': groupName,
        'members': selectedMembers,
      });
      print('Create Group Response Status: ${response.statusCode}');
      print('Create Group Response Body: ${response.body}');
      fetchChats(); // Refresh chat list after group creation
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter group name and select members')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fetchAgain) {
      fetchChats();
      setState(() {
        fetchAgain = false;
      });
    }

    return Scaffold(
      body: chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AssetImages.logo,
                    scale: 2,
                    opacity: const AlwaysStoppedAnimation(.6),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "You haven't Groups yet",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ButtonWidget(func: _showCreateGroupModal, text: 'Create Group'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: chats.map(
                  (e) {
                    return ItemGroupWidget(
                      data: e,
                      token: widget.token,
                    );
                  },
                ).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupModal,
        backgroundColor: AppColors.primaryColor,
        heroTag: 'group',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showCreateGroupModal() {
    showDialog(
      context: context,
      builder: (context) {
        final filteredUsers = users.where((user) => user['_id'] != userInfo['_id']).toList();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Group'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          groupName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Members:'),
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? const Center(child: Text('No users available'))
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final userId = user['_id'] ?? '';
                                final userName = user['email'] ?? 'Unknown';
                                final isChecked = selectedMembers.contains(userId);
                                return ListTile(
                                  title: Text(userName),
                                  trailing: Checkbox(
                                    value: isChecked,
                                    onChanged: (bool? isChecked) {
                                      setState(() {
                                        if (isChecked == true) {
                                          selectedMembers.add(userId);
                                        } else {
                                          selectedMembers.remove(userId);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _createGroup(); // Call the create group method
                    Navigator.of(context).pop();
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
