// lib/providers/chat_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // Load chat sessions
  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getChatSessions();
      _sessions = response;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _sessions = []; // Set ke empty list jika error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load messages for a session
  Future<void> loadMessages(String sessionId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _messages.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getChatHistory(sessionId, page: _currentPage);
      
      if (response.isEmpty) {
        _hasMore = false;
      } else {
        _messages.addAll(response);
        _currentPage++;
        _currentSessionId = sessionId;
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage(String message, {String? refractionResult, XFile? file}) async {
    _isSending = true;
    notifyListeners();

    try {
      final response = await _apiService.sendChatMessage(
        message: message,
        sessionId: _currentSessionId,
        refractionResult: refractionResult,
        file: file,
      );

      if (response['success'] && response['data'] != null) {
        final sessionId = response['data']['session_id'] ?? _currentSessionId;
        final botResponseData = response['data']['bot_response'];
        
        if (botResponseData == null) {
          throw Exception('Backend tidak memberikan respon balasan');
        }

        final botResponse = ChatMessage.fromJson(botResponseData);

        // Add user message manually
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sessionId: sessionId,
          role: 'user',
          content: message,
          timestamp: DateTime.now(),
        ));

        // Add bot response
        _messages.add(botResponse);
        
        _currentSessionId = sessionId;
        _errorMessage = null;
        
        return {'success': true, 'data': response['data']};
      } else {
        _errorMessage = response['message'];
        return {'success': false, 'message': response['message']};
      }
    } catch (e) {
      _errorMessage = e.toString();
      return {'success': false, 'message': e.toString()};
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // Send feedback
  Future<bool> sendFeedback(int messageId, bool isHelpful, {String? note}) async {
    try {
      final success = await _apiService.sendMessageFeedback(
        messageId: messageId,
        isHelpful: isHelpful,
        note: note,
      );

      if (success) {
        // Update local message
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final updatedMessage = ChatMessage(
            id: _messages[index].id,
            sessionId: _messages[index].sessionId,
            role: _messages[index].role,
            content: _messages[index].content,
            timestamp: _messages[index].timestamp,
            isHelpful: isHelpful,
            feedbackNote: note,
            messageType: _messages[index].messageType,
            suggestions: _messages[index].suggestions,
          );
          _messages[index] = updatedMessage;
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error sending feedback: $e');
      return false;
    }
  }

  // Delete session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final success = await _apiService.deleteChatSession(sessionId);
      
      if (success) {
        _sessions.removeWhere((s) => s.sessionId == sessionId);
        if (_currentSessionId == sessionId) {
          _currentSessionId = null;
          _messages.clear();
        }
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Create new session
  void newSession() {
    _currentSessionId = null;
    _messages.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}