import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:client/constants/app_colors.dart';
import 'package:client/constants/app_dimensions.dart';
import 'package:client/constants/app_styles.dart';
import 'package:client/helpers/asset_images.dart';
import 'package:client/helpers/socket_io.dart';
import 'package:client/services/group_service.dart';
import 'package:client/widgets/appbar_widget.dart';
import 'package:client/widgets/icon_appbar_widget.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class GroupMessageScreen extends StatefulWidget {
  const GroupMessageScreen({
    super.key,
    required this.token,
    required this.chat,
  });

  final String token;
  final Map chat;

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  List messages = [];
  List members = [];
  Map<String, dynamic> userInfo = {};
  Timer? _timer; // Timer to periodically fetch messages

  @override
  void initState() {
    super.initState();
    userInfo = JwtDecoder.decode(widget.token);
    fetchMessages();
    _startMessagePolling();
    fetchMembers();
    socket.emit('join-chat', widget.chat['_id']);
    socket.on(widget.chat['_id'], (message) {
      if (mounted) {
        setState(() {
          messages.add(message);
        });
      }
    });
  }

  void _startMessagePolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchMessages();
    });
  }

  Future<void> sendMessage() async {
    final reqBody = {
      "groupId": widget.chat['_id'],
      "sender": userInfo['_id'],
      "content": _contentController.text,
    };

    final response = await GroupService.sendMessage(
      widget.chat['_id'],
      widget.token,
      _contentController.text,
    );
    socket.emit('on-chat', jsonDecode(response.body));
    _contentController.clear();
    socket.emit('all', true);
  }

  Future<void> fetchMessages() async {
    final response = await GroupService.fetchMessages(widget.chat['_id']);
    if (response.statusCode == 200) {
      setState(() {
        messages = jsonDecode(response.body);
      });
    } else {
      // Handle error
      print('Failed to fetch messages');
    }
  }

  Future<void> fetchMembers() async {
    final response = await GroupService.fetchMembers(widget.chat['_id']);
    if (response.statusCode == 200) {
      setState(() {
        members = jsonDecode(response.body);
      });

      print(members);
    } else {
      // Handle error
      print('Failed to fetch members');
    }
  }

  Future<void> deleteMembers(String memberId) async {
    final response = await GroupService.removeMember(widget.chat['_id'], memberId);
      fetchMembers();
      Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _showGroupMembersModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Group Members'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ElevatedButton(
                        child: Text(member['email'] ?? 'Unknown'),
                        onPressed: () {
                          deleteMembers(member['_id']);
                        },
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        avatar: AssetImages.avatar,
        text: widget.chat['name'] ?? 'Group Chat',
        actions: [
          IconAppBarWidget(
            icon: Icons.more_vert,
            func: _showGroupMembersModal, // Show the modal on press
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messages.map((e) {
                    final isSentByCurrentUser = e['sender'] == userInfo['email'];
                    return Container(
                      alignment: isSentByCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      margin: const EdgeInsets.only(
                        bottom: AppDimensions.smallSpacing,
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets.all(AppDimensions.mediumSpacing),
                        decoration: BoxDecoration(
                          color: isSentByCurrentUser
                              ? AppColors.primaryColor
                              : AppColors.greyColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e['sender'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSentByCurrentUser
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              e['content'] ?? '',
                              style: TextStyle(
                                color: isSentByCurrentUser
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(
                top: AppDimensions.largeSpacing,
              ),
              child: Form(
                key: formKey,
                child: TextFormField(
                  controller: _contentController,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  decoration: AppStyles.inputDecoration(
                    'Type message...',
                    null,
                  ).copyWith(
                    suffixIcon: IconButton(
                      splashRadius: AppDimensions.splashRadius,
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send),
                    ),
                    suffixIconColor: AppColors.primaryColor,
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Message cannot be empty';
                    } else {
                      return null;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
