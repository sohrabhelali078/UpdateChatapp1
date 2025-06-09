import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Add this import
import 'package:client/constants/app_colors.dart';
import 'package:client/constants/app_dimensions.dart';
import 'package:client/constants/app_styles.dart';
import 'package:client/helpers/asset_images.dart';
import 'package:client/helpers/socket_io.dart';
import 'package:client/services/message_service.dart';
import 'package:client/services/auth_service.dart'; // Import user service
import 'package:client/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import
import 'package:client/services/config.dart';

// Define ButtonAppBarWidget here
class ButtonAppBarWidget extends StatelessWidget {
  final String text;
  final VoidCallback func;

  ButtonAppBarWidget({required this.text, required this.func});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: func,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black, // Set the text color according to your AppBar theme
        ),
      ),
    );
  }
}

class ChatMessageScreen extends StatefulWidget {
  const ChatMessageScreen({
    super.key,
    required this.token,
    required this.chat,
  });

  final String token;
  final Map chat;

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  List messages = [];
  Map<String, dynamic> userInfo = {};
  Timer? _timer;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
    userInfo = JwtDecoder.decode(widget.token);
    socket.emit('join-chat', widget.chat['_id']);
    socket.on(widget.chat['_id'], (message) {
      if (mounted) {
        setState(() {
          messages.add(message);
        });
      }
    });
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchMessages();
    });

    // Check if user is blocked
    _checkIfBlocked();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkIfBlocked() async {
    // Assuming you have an endpoint to check if the user is blocked
    final response = await AuthService.checkIfBlocked(widget.token, widget.chat['user']['_id']);
    if (response.statusCode == 200) {
      setState(() {
        _isBlocked = jsonDecode(response.body)['isBlocked'];
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check block status')),
      );
    }
  }

  Future<void> fetchMessages() async {
    if (_isBlocked) return; // Prevent fetching if blocked

    try {
      final response = await MessageService.fetchMessages(widget.token, widget.chat['_id']);
      setState(() {
        messages = jsonDecode(response.body);
      });
    } catch (e) {
      // Handle fetch error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch messages')),
      );
    }
  }

  Future<void> sendMessage() async {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are blocked from sending messages')),
      );
      return;
    }

    if (formKey.currentState!.validate()) {
      try {
        final reqBody = {
          "chatId": widget.chat['_id'],
          "content": _contentController.text,
        };
        final response = await MessageService.sendMessage(widget.token, reqBody);
        final newMessage = jsonDecode(response.body);
        socket.emit('on-chat', newMessage);
        _contentController.clear();
        setState(() {
          messages.add(newMessage);
        });
      } catch (e) {
        // Handle send error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are blocked from sending files')),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      try {
        final uri = Uri.parse('$urlServer2/upload'); // Update with your server endpoint
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer ${widget.token}'
          ..fields['chatId'] = widget.chat['_id'] ?? 'unknown'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final fileData = jsonDecode(responseBody);

          if (fileData != null && fileData['url'] != null) {
            socket.emit('on-chat', {
              'type': 'file',
              'url': fileData['url'],
              'fileName': fileData['fileName'],
              'chatId': widget.chat['_id']
            });

            final reqBody = {
              "chatId": widget.chat['_id'],
              "content": fileData['url'],
            };
            final response = await MessageService.sendMessage(widget.token, reqBody);
            final newMessage = jsonDecode(response.body);
            socket.emit('on-chat', newMessage);
            _contentController.clear();
            setState(() {
              messages.add(newMessage);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid file data received')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload file')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred while sending file')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<void> blockUser() async {
    final userId = widget.chat['user']['_id'];
    final response = await AuthService.blockUser(widget.token, userId);
    if (response.statusCode == 200) {
      if (_isBlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User Unblocked successfully')),
        );
        setState(() {
          _isBlocked = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User blocked successfully')),
        );
        setState(() {
          _isBlocked = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user')),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBarWidget(
      avatar: AssetImages.avatar,
      text: widget.chat['user']['name'] != null 
          ? widget.chat['user']['name'] 
          : widget.chat['user']['email'].substring(0, widget.chat['user']['email'].indexOf('@')),
      actions: [
        ButtonAppBarWidget(
          text: _isBlocked ? "Unblock user" : "Block user",
          func: blockUser,
        ),
        ButtonAppBarWidget(
          text: "Attach File",
          func: _pickAndSendFile,
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
                  final isSender = e['sender']['_id'] == userInfo['_id'];
                  final content = e['content'];
                  
                  return Container(
                    alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.smallSpacing,
                    ),
                    child: GestureDetector(
                      onTap: content.startsWith('http://') || content.startsWith('https://')
                          ? () async {
                              // if (await canLaunch(content)) {
                                await launch(content);
                              // } else {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(content: Text('Cannot open link')),
                              //   );
                              // }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.mediumSpacing),
                        decoration: BoxDecoration(
                          color: isSender ? AppColors.primaryColor : AppColors.secondColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          content.startsWith('http://') || content.startsWith('https://')
                              ? 'Open File'
                              : content,
                          style: TextStyle(
                            color: isSender ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                  color: AppColors.primaryColor,
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
