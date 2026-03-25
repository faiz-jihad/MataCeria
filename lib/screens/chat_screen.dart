// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indikator.dart';
import '../widgets/quick_chip.dart';
import '../widgets/empty_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final String? refractionResult;

  const ChatScreen({
    super.key,
    this.initialMessage,
    this.refractionResult,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  XFile? _selectedFile;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Load messages from session if exists
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      await chatProvider.loadMessages(args);
    }
    
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? message]) async {
    final text = message ?? _messageController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    _messageController.clear();
    _focusNode.unfocus();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final result = await chatProvider.sendMessage(
      text,
      refractionResult: widget.refractionResult,
      file: _selectedFile,
    );

    if (result['success']) {
      setState(() {
        _selectedFile = null;
      });
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim pesan'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) setState(() => _selectedFile = photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri Foto'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _selectedFile = image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File Dokumen'),
              onTap: () async {
                Navigator.pop(context);
                // Note: File picker might need another package, but XFile from image_picker is fine for media.
                // For general files, usually file_picker is used.
                // I'll stick to images for now as a "Photo/File" combo.
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _selectedFile = image);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('⚠️ Disclaimer Medis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  'PENTING: BACA DENGAN SEKSAMA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Saya adalah asisten virtual berbasis AI, BUKAN dokter atau tenaga medis profesional.\n\n'
                '2. Semua saran dan informasi bersifat informatif and edukatif, bukan diagnosis medis.\n\n'
                '3. Konsultasikan selalu dengan spesialis mata untuk diagnosis dan perawatan yang tepat.\n\n'
                '4. Jika mengalami gejala serius, segera ke fasilitas kesehatan terdekat.\n\n'
                '5. Jangan pernah mengabaikan saran medis profesional hanya karena informasi dari chatbot.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Saya Mengerti'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Kontak Darurat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'Jika Anda mengalami gejala serius seperti nyeri hebat, infeksi meluas, atau demam, SEGERA ke IGD terdekat!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📞 **Nomor Darurat:**',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.emergency, color: Colors.red),
                    title: const Text('Ambulans / IGD'),
                    subtitle: const Text('118 / 119'),
                    trailing: ElevatedButton(
                      onPressed: () => launchUrl(Uri.parse('tel:119')),
                      child: const Text('Hubungi'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.local_hospital, color: Colors.blue),
                    title: const Text('RS Terdekat'),
                    subtitle: const Text('Cek di menu Kontak Darurat'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin/emergency'); // Updated to the new admin-managed list if appropriate or to general list
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/emergency-contacts');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lihat Kontak Darurat'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chatbot AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Konsultasi Mata',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/chat-history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDisclaimerDialog,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.warning, color: Colors.red),
                  title: const Text('Kontak Darurat'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEmergencyDialog();
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: const Text('Sesi Baru'),
                  onTap: () {
                    Navigator.pop(context);
                    chatProvider.newSession();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  QuickChip(
                    label: 'Rekomendasi',
                    icon: Icons.medical_services,
                    color: Colors.blue,
                    onTap: () => _sendMessage('rekomendasi'),
                  ),
                  QuickChip(
                    label: 'Hasil Deteksi',
                    icon: Icons.photo,
                    color: Colors.green,
                    onTap: () => _sendMessage('jelaskan hasil deteksi'),
                  ),
                  QuickChip(
                    label: 'Obat',
                    icon: Icons.medication,
                    color: Colors.purple,
                    onTap: () => _sendMessage('rekomendasi obat'),
                  ),
                  QuickChip(
                    label: 'Makanan',
                    icon: Icons.fastfood,
                    color: Colors.orange,
                    onTap: () => _sendMessage('makanan yang harus dihindari'),
                  ),
                  QuickChip(
                    label: 'Darurat',
                    icon: Icons.warning,
                    color: Colors.red,
                    onTap: () => _sendMessage('darurat'),
                  ),
                ],
              ),
            ),
          ),

          // Chat messages
          Expanded(
            child: chatProvider.messages.isEmpty && !chatProvider.isSending
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length +
                        (chatProvider.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length &&
                          chatProvider.isSending) {
                        return const TypingIndicator();
                      }
                      final message = chatProvider.messages[index];
                      return MessageBubble(
                        message: message,
                        onFeedback: (isHelpful, note) async {
                          await chatProvider.sendFeedback(
                            message.id,
                            isHelpful,
                            note: note,
                          );
                        },
                        onSuggestionTap: (suggestion) => _sendMessage(suggestion),
                      );
                    },
                  ),
          ),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'Mulai Konsultasi',
      message: 'Tanyakan seputar kesehatan mata, rekomendasi, atau hasil deteksi Anda kepada asisten AI kami.',
      icon: Icons.chat_bubble_outline,
      actionLabel: 'Tanya: Apa itu miopi?',
      onAction: () => _sendMessage('Apa itu miopi?'),
    );
  }


  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.grey.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_selectedFile!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickAttachment,
                color: Colors.grey.shade600,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}