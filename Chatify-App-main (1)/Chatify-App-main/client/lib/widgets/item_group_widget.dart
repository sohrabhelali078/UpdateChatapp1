import 'dart:io';
import 'package:client/constants/app_dimensions.dart';
import 'package:client/helpers/asset_images.dart';
import 'package:client/helpers/helper_function.dart';
import 'package:client/helpers/socket_io.dart';
import 'package:client/screens/home/group_message_screen.dart';
import 'package:client/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async'; // Import for Timer

class ItemGroupWidget extends StatefulWidget {
  const ItemGroupWidget({super.key, required this.data, required this.token});

  final Map data;
  final String token;

  @override
  State<ItemGroupWidget> createState() => _ItemGroupWidgetState();
}

class _ItemGroupWidgetState extends State<ItemGroupWidget> {
  Map<String, dynamic> userInfo = {};
  Timer? _timer; // Timer to periodically fetch messages

  @override
  void initState() {
    super.initState();
    userInfo = JwtDecoder.decode(widget.token);
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      readMessage();
    });
  }

  Future<void> readMessage() async {
    if (widget.data['messages'] != null && widget.data['messages'].isNotEmpty) {
      final latestMessage = widget.data['messages'].last;
      final latestMessageId = latestMessage['_id'];
      await MessageService.readMessage(widget.token, latestMessageId);
      socket.emit('all', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure widget.data['messages'] is a List and handle potential null values
    final messages = widget.data['messages'] ?? [];
    final latestMessage = messages.isNotEmpty ? messages.last : null;

    return GestureDetector(
      onTap: () {
        if (latestMessage != null &&
            latestMessage['readBy'] != null &&
            latestMessage['readBy'].isEmpty &&
            latestMessage['sender'] != userInfo['_id']) {
          readMessage();
        }
        nextScreen(
          context,
          GroupMessageScreen(
            token: widget.token,
            chat: widget.data,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppDimensions.largeSpacing,
        ),
        child: Row(
          children: [
            // Placeholder for group avatar, use a default image for now
            Image.asset(
              AssetImages.avatar,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: AppDimensions.mediumSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.data['name'] ?? 'Group Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        latestMessage != null && latestMessage['createdAt'] != null
                            ? DateFormat('h:mm a').format(DateTime.parse(
                                latestMessage['createdAt']))
                            : '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.smallSpacing),
                  Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      text: latestMessage != null
                          ? latestMessage['sender'] ?? 'Unknown'
                          : 'No messages yet',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: latestMessage != null
                              ? ' : ${latestMessage['content'] ?? 'No content'}'
                              : '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: latestMessage != null &&
                                    latestMessage['sender'] !=
                                        userInfo['_id']
                                ? FontWeight.bold
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
