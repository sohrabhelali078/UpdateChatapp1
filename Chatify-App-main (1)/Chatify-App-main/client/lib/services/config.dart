
  // Base URL for your API
const String urlServer = 'http://192.168.12.1:7000/api';
const String urlServer2 = 'http://192.168.12.1:7000';

  // Chat endpoints
const String chatUrl = '$urlServer/chat';
const String fetchChatsUrl = '$urlServer/chat';

  // Message endpoints
String allMessagesUrl(String chatId) => '$urlServer/message/$chatId';
const String messageUrl = '$urlServer/message';
String readMessageUrl(String messageId) => '$urlServer/message/$messageId';

  // User endpoints
const String registerUrl = '$urlServer/user/register';
const String loginUrl = '$urlServer/user/login';
String updateUrl(String userId) => '$urlServer/user/update/$userId';
String deleteUrl(String userId) => '$urlServer/user/delete/$userId';
const String blockUrl = '$urlServer/user/block';
const String CheckIsBlockedUrl = '$urlServer/user/is-blocked';
const String unblockUrl = '$urlServer/user/unblock';
const String userUrl = '$urlServer/user';
const String getAllUsersList = '$urlServer/user/get-all-users';

// Group chat endpoints
const String createGroupUrl = '$urlServer/group-chat/create';
const String addMemberUrl = '$urlServer/group-chat/add-member';
const String removeMemberUrl = '$urlServer/group-chat/remove-member';
const String groupMessagesUrl = '$urlServer/group-chat/messages';
const String fetchGroupsUrl = '$urlServer/group-chat';
const String groupsListUrl = '$urlServer/group-chat/all';
const String groupMsgs = '$urlServer/group-chat/get-one';
const String groupMembers = '$urlServer/group-chat/get-members';

  // Timeout for network requests (in milliseconds)
const int requestTimeout = 30000;

  // Any other configuration settings you need
const String appVersion = '1.0.0';
const bool enableDebugging = true;
