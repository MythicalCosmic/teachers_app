import 'package:flutter/material.dart';

import '../chat_screen.dart';

/// Management conversations share the hardened staff chat implementation,
/// while retaining a contextual channel label.
class MgmtChatScreen extends StatelessWidget {
  const MgmtChatScreen({super.key});

  @override
  Widget build(BuildContext context) => const ChatScreen(managementMode: true);
}
