import 'dart:convert';
import 'package:client/services/config.dart';
import 'package:http/http.dart' as http;

class GroupService {
  static Future<http.Response> createGroup(Map<String, dynamic> groupData) async {
    final response = await http.post(
      Uri.parse(createGroupUrl), // Define this in config.dart
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(groupData),
    );
    return response;
  }

  static Future<http.Response> addMember(String groupId, String memberId) async {
    final response = await http.put(
      Uri.parse(addMemberUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"groupId": groupId, 'memberId': memberId}),
    );
    return response;
  }

  static Future<http.Response> removeMember(String groupId, String memberId) async {
    final response = await http.post(
      Uri.parse('$removeMemberUrl/$groupId/$memberId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"groupId": groupId, 'memberId': memberId}),
    );
    return response;
  }

  static Future<http.Response> sendMessage(String groupId, String token, String content) async {
    final response = await http.post(
      Uri.parse(groupMessagesUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({"groupId": groupId, 'content': content}),
    );
    return response;
  }

  static Future<http.Response> fetchUsers() async {
    final response = await http.get(
      Uri.parse(getAllUsersList),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  static Future<http.Response> fetchGroups() async {
    final response = await http.get(
      Uri.parse(groupsListUrl),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  static Future<http.Response> fetchMessages(String groupId) async {
    final response = await http.get(
      Uri.parse('$groupMsgs/$groupId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  static Future<http.Response> fetchMembers(String groupId) async {
    final response = await http.get(
      Uri.parse('$groupMembers/$groupId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response;
  }
}
