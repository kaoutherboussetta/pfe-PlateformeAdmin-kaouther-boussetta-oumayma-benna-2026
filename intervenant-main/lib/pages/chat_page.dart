import 'dart:convert';
import 'dart:io';
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/pages/profile_page.dart' show displayEquipeLabel;
import 'package:intervenant/services/auth_api_service.dart';
import 'package:intervenant/services/chat_badge_prefs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Clés possibles côté API / Mongo pour le rôle ou le type d’expéditeur.
const List<String> _chatSenderRoleKeys = <String>[
  'senderRole',
  'sender_role',
  'senderType',
  'sender_type',
  'role',
];

bool _truthyFlag(Object? v) {
  if (v == true) return true;
  if (v is num && v != 0) return true;
  if (v is String) {
    final String s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

bool _senderFieldEquals(Map<String, dynamic> map, String expected) {
  final String want = expected.trim().toLowerCase();
  for (final String key in _chatSenderRoleKeys) {
    final Object? v = map[key];
    if (v == null) continue;
    if (v.toString().trim().toLowerCase() == want) return true;
  }
  return false;
}

/// Détecte une image par extension (l’API renvoie souvent `application/octet-stream`).
bool _looksLikeImageFile(String? name, String url) {
  final String n = (name ?? '').toLowerCase();
  final String u = url.toLowerCase();
  final RegExp ext = RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp|heic)(\?|#|$)', caseSensitive: false);
  return ext.hasMatch(n) || ext.hasMatch(u);
}

bool _isChatImageAttachment(ChatAttachment a) =>
    a.kind == 'image' || a.mime.startsWith('image/') || _looksLikeImageFile(a.name, a.url);

/// N’affiche pas une ligne de texte si ce n’est que le nom du fichier image (doublon visuel type « fichier »).
bool _shouldShowMessageBodyText(ChatMessage message) {
  final String t = message.text.trim();
  if (t.isEmpty) return false;
  for (final ChatAttachment a in message.attachments) {
    if (!_isChatImageAttachment(a)) continue;
    if (t == a.name) return false;
    if (a.url.isNotEmpty) {
      final String base = a.url.split('/').last.split('?').first;
      if (base.isNotEmpty && t == base) return false;
    }
  }
  return true;
}

/// Clé API type `author_key`: `e:admin@domaine.com` → message support / admin.
bool _authorKeyLooksLikeAdmin(Map<String, dynamic> map) {
  final String key = (map['author_key'] ?? map['authorKey'] ?? '').toString().toLowerCase();
  if (key.startsWith('e:admin@')) return true;
  if (key.contains(':admin@')) return true;
  return false;
}

/// Expéditeur admin → bulle à gauche (support). Vérifie entre autres `senderRole` et `sender_type` = `"admin"`.
bool _isAdminChatSender(Map<String, dynamic> map) {
  if (_truthyFlag(map['from_admin']) || _truthyFlag(map['fromAdmin'])) return true;
  if (_senderFieldEquals(map, 'admin')) return true;
  if (_authorKeyLooksLikeAdmin(map)) return true;
  return false;
}

/// `true` seulement pour les messages de l’intervenant (droite). Admin / support / inconnu → `false` (gauche).
bool _isChatMessageFromIntervenant(Map<String, dynamic> map) {
  if (_isAdminChatSender(map)) return false;
  return _senderFieldEquals(map, 'intervenant');
}

String _messageBodyFromMap(Map<String, dynamic> map) {
  final String? t = map['text'] as String?;
  if (t != null && t.isNotEmpty) return t;
  final String? m = map['message'] as String?;
  if (m != null && m.isNotEmpty) return m;
  return '';
}

/// Parse `createdAt`, `created_at`, y compris étendu Mongo `{ "\$date": "..." }`.
DateTime? _parseChatDateFromMap(Map<String, dynamic> map) {
  for (final String key in <String>['createdAt', 'created_at', 'updated_at']) {
    final Object? raw = map[key];
    final DateTime? parsed = _parseChatDateValue(raw);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _parseChatDateValue(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is Map) {
    final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
    final Object? d = m[r'$date'];
    if (d is String) return DateTime.tryParse(d);
    if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
  }
  return null;
}

/// En-têtes HTTP pour [Image.network] (ngrok renvoie une page d’avertissement sans ce header).
Map<String, String>? _chatImageRequestHeaders(String url) {
  final String host = (Uri.tryParse(url)?.host ?? '').toLowerCase();
  if (host.contains('ngrok-free.') ||
      host.contains('ngrok.app') ||
      host.contains('ngrok.io') ||
      host.endsWith('.ngrok.app')) {
    return <String, String>{'ngrok-skip-browser-warning': '69420'};
  }
  return null;
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.intervenantName,
    required this.intervenantEmail,
    this.teamLabel,
    this.onUnreadCountChanged,
    super.key,
  });

  final String intervenantName;
  final String intervenantEmail;
  /// Même valeur que le profil (ex. `Équipe 2`, `2`) — affichée sous le titre du chat.
  final String? teamLabel;
  final ValueChanged<int>? onUnreadCountChanged;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  late final AnimationController _typingAnimationController;
  
  final List<dynamic> _messages = [];
  
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAdminTyping = false;
  String? _errorMessage;
  PendingAttachment? _pendingAttachment;

  /// Toujours ordre chronologique (date + heure du [ChatMessage.timestamp]).
  List<ChatMessage> get _safeMessages {
    final List<ChatMessage> list = _messages.map(_coerceMessage).toList(growable: false);
    list.sort((ChatMessage a, ChatMessage b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  ChatMessage _coerceMessage(dynamic value) {
    if (value is ChatMessage) return value;
    if (value is Map) {
      return _fromApi(value);
    }
    return ChatMessage(
      id: '',
      text: value?.toString() ?? '',
      isFromUser: false,
      sender: 'support',
      timestamp: DateTime.now(),
      attachments: const [],
    );
  }

  Future<void> _markAdminMessagesAsOpenedAndNotify() async {
    final List<String> adminIds = _safeMessages
        .where((ChatMessage m) => !m.isFromUser)
        .map((ChatMessage m) => m.id.trim().isNotEmpty ? m.id.trim() : '${m.sender}|${m.text}|${m.timestamp.toIso8601String()}')
        .toList(growable: false);
    await ChatBadgePrefs.ensureBaselineIfNeeded(adminIds);
    await ChatBadgePrefs.markAllOpened(adminIds);
    widget.onUnreadCountChanged?.call(0);
  }

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _sendMessage() {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;
    if (_pendingAttachment != null) {
      _sendAttachmentToServer(text: text);
      return;
    }
    _sendMessageToServer(text);
  }

  String get _intervenantId {
    final String email = widget.intervenantEmail.trim().toLowerCase();
    if (email.isNotEmpty) return email;
    final String normalizedName = widget.intervenantName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');
    if (normalizedName.isNotEmpty) return 'name_$normalizedName';
    return 'anonymous_intervenant';
  }

  String get _baseUrl => AuthApiService.baseUrl.trim();

  Map<String, String> _headersForBase() {
    final Uri? u = Uri.tryParse(_baseUrl);
    final String host = (u?.host ?? '').toLowerCase();
    final bool isNgrok = host.contains('ngrok-free.') ||
        host.contains('ngrok.app') ||
        host.contains('ngrok.io') ||
        host.endsWith('.ngrok.app');
    return <String, String>{
      'Accept': 'application/json',
      if (isNgrok) 'ngrok-skip-browser-warning': '69420',
    };
  }

  Future<void> _loadMessages() async {
    if (_baseUrl.isEmpty) {
      _setStateIfMounted(() {
        _isLoading = false;
        _errorMessage = 'Configuration du serveur requise';
      });
      return;
    }
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final Uri url = Uri.parse('$_baseUrl/api/chat/intervenant').replace(
        queryParameters: <String, String>{'intervenant_id': _intervenantId},
      );
      final http.Response response = await http.get(url, headers: _headersForBase());
      if (!mounted) return;
      final Map<String, dynamic> body = _decodeJsonMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final List<dynamic> items = (body['items'] as List<dynamic>?) ?? <dynamic>[];
        final List<ChatMessage> loaded = items.map((dynamic e) => _fromApi(e)).toList(growable: false);
        _setStateIfMounted(() {
          _messages.clear();
          _messages.addAll(loaded);
          _isLoading = false;
        });
        await _markAdminMessagesAsOpenedAndNotify();
        _scrollToBottom();
        return;
      }
      _setStateIfMounted(() {
        _isLoading = false;
        _errorMessage = (body['message'] as String?) ?? 'Impossible de charger la conversation.';
      });
    } catch (e) {
      _setStateIfMounted(() {
        _isLoading = false;
        _errorMessage = 'Erreur de connexion: $e';
      });
    }
  }

  Future<void> _sendMessageToServer(String text) async {
    if (_baseUrl.isEmpty) {
      _setStateIfMounted(() => _errorMessage = 'Configuration du serveur requise');
      return;
    }
    _setStateIfMounted(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      final Uri url = Uri.parse('$_baseUrl/api/chat/intervenant');
      final Map<String, String> headers = _headersForBase();
      final http.Response response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', ...headers},
        body: jsonEncode({
          'intervenantId': _intervenantId,
          'intervenantName': widget.intervenantName,
          'senderRole': 'intervenant',
          'text': text,
        }),
      );
      if (!mounted) return;
      final Map<String, dynamic> body = _decodeJsonMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final dynamic rawItem = body['item'];
        if (rawItem is Map) {
          _setStateIfMounted(() {
            _messages.add(_fromApi(rawItem));
            _messageController.clear();
            _isSending = false;
          });
          widget.onUnreadCountChanged?.call(0);
          _scrollToBottom();
          return;
        }
      }
      _setStateIfMounted(() {
        _isSending = false;
        _errorMessage = (body['message'] as String?) ?? 'Envoi impossible.';
      });
    } catch (e) {
      _setStateIfMounted(() {
        _isSending = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  ChatMessage _fromApi(dynamic value, {String? attachmentLocalPath}) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(value as Map);
    final List<dynamic> rawAttachments = (map['attachments'] as List<dynamic>?) ?? const <dynamic>[];
    List<ChatAttachment> attachments = rawAttachments
        .whereType<Map>()
        .map((dynamic raw) {
          final Map<String, dynamic> a = Map<String, dynamic>.from(raw as Map);
          final String rawUrl = (a['url'] as String?) ?? '';
          final String mime = (a['mime'] as String?) ?? 'application/octet-stream';
          final String attName = (a['name'] as String?) ?? 'file';
          String kind = (a['kind'] as String?) ?? 'other';
          if (kind == 'other' && (mime.startsWith('image/') || _looksLikeImageFile(attName, rawUrl))) {
            kind = 'image';
          }
          return ChatAttachment(
            kind: kind,
            name: attName,
            mime: mime,
            size: (a['size'] as num?)?.toInt() ?? 0,
            url: _absoluteAttachmentUrl(rawUrl),
          );
        })
        .toList(growable: false);
    if (attachmentLocalPath != null && attachmentLocalPath.isNotEmpty && attachments.isNotEmpty) {
      final int imageIndex = attachments.indexWhere(
        (ChatAttachment a) =>
            a.kind == 'image' || a.mime.startsWith('image/') || _looksLikeImageFile(a.name, a.url),
      );
      final int idx = imageIndex >= 0 ? imageIndex : 0;
      final ChatAttachment u = attachments[idx];
      attachments = <ChatAttachment>[
        ...attachments.take(idx),
        ChatAttachment(
          kind: 'image',
          name: u.name,
          mime: u.mime.startsWith('image/') ? u.mime : 'image/jpeg',
          size: u.size,
          url: u.url,
          localPath: attachmentLocalPath,
        ),
        ...attachments.skip(idx + 1),
      ];
    }
    final bool fromIntervenant = _isChatMessageFromIntervenant(map);
    return ChatMessage(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      text: _messageBodyFromMap(map),
      isFromUser: fromIntervenant,
      sender: fromIntervenant ? 'user' : 'support',
      timestamp: _parseChatDateFromMap(map) ?? DateTime.now(),
      attachments: attachments,
    );
  }

  String _absoluteAttachmentUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '$_baseUrl$raw';
    return '$_baseUrl/$raw';
  }

  Future<void> _openAttachment(ChatAttachment attachment) async {
    final String absolute = _absoluteAttachmentUrl(attachment.url);
    final Uri? uri = Uri.tryParse(absolute);
    if (uri == null || !uri.hasScheme) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _sendAttachmentToServer({required String text}) async {
    if (_baseUrl.isEmpty || _pendingAttachment == null) {
      _setStateIfMounted(() => _errorMessage = 'Fichier non sélectionné');
      return;
    }
    final PendingAttachment file = _pendingAttachment!;
    _setStateIfMounted(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      final Uri url = Uri.parse('$_baseUrl/api/chat/intervenant/attachment');
      final http.MultipartRequest request = http.MultipartRequest('POST', url);
      request.fields['intervenantId'] = _intervenantId;
      request.fields['intervenantName'] = widget.intervenantName;
      request.fields['senderRole'] = 'intervenant';
      request.fields['text'] = text;

      request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: file.name));
      request.headers.addAll(_headersForBase());
      final http.StreamedResponse streamed = await request.send();
      final String bodyText = await streamed.stream.bytesToString();
      if (!mounted) return;
      final Map<String, dynamic> body = _decodeJsonMap(bodyText);
      if (streamed.statusCode >= 200 && streamed.statusCode < 300 && body['success'] == true) {
        final dynamic rawItem = body['item'];
        if (rawItem is Map) {
          final String? localPreview = file.kind == 'image' ? file.path : null;
          _setStateIfMounted(() {
            _messages.add(_fromApi(rawItem, attachmentLocalPath: localPreview));
            _messageController.clear();
            _pendingAttachment = null;
            _isSending = false;
          });
          widget.onUnreadCountChanged?.call(0);
          _scrollToBottom();
          return;
        }
      }
      _setStateIfMounted(() {
        _isSending = false;
        _errorMessage = (body['message'] as String?) ?? 'Envoi impossible.';
      });
    } catch (e) {
      _setStateIfMounted(() {
        _isSending = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    _setStateIfMounted(() {
      _pendingAttachment = PendingAttachment(
        path: picked.path,
        name: picked.name,
        kind: 'image',
      );
    });
  }

  Future<void> _pickFromCamera() async {
    final XFile? picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    _setStateIfMounted(() {
      _pendingAttachment = PendingAttachment(
        path: picked.path,
        name: picked.name,
        kind: 'image',
      );
    });
  }

  Future<void> _pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty || !mounted) return;
    final PlatformFile file = result.files.first;
    if (file.path == null || file.path!.isEmpty) {
      _setStateIfMounted(() => _errorMessage = 'Impossible de lire le document');
      return;
    }
    _setStateIfMounted(() {
      _pendingAttachment = PendingAttachment(
        path: file.path!,
        name: file.name,
        kind: 'document',
      );
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  /// Libellé « Équipe 1 » / « Team 2 » aligné sur le profil ; `null` si aucune équipe en session.
  String? _equipeSubtitleLine(BuildContext context) {
    final String raw = widget.teamLabel?.trim() ?? '';
    if (raw.isEmpty) return null;
    final String lang = Localizations.localeOf(context).languageCode;
    return displayEquipeLabel(raw, lang);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          _ModernChatAppBar(
            onMenuTap: _showMenuOptions,
            equipeSubtitle: _equipeSubtitleLine(context),
          ),
          if (_errorMessage != null && _safeMessages.isNotEmpty)
            _ErrorBanner(error: _errorMessage!),
          Expanded(child: _buildMessageList(theme)),
          if (_isAdminTyping) _TypingIndicator(animationController: _typingAnimationController),
          _ModernMessageInput(
            messageController: _messageController,
            isSending: _isSending,
            pendingAttachment: _pendingAttachment,
            onSend: _sendMessage,
            onClearAttachment: () => setState(() => _pendingAttachment = null),
            onAttach: _showAttachmentOptions,
            onEmoji: _showEmojiPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    final messages = _safeMessages;
    if (_isLoading) return const _LoadingIndicator();
    if (_errorMessage != null && messages.isEmpty) {
      return _ErrorState(errorMessage: _errorMessage!, onRetry: _loadMessages);
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDate = index == 0 || !_isSameDay(message.timestamp, messages[index - 1].timestamp);
        return Column(
          children: [
            if (showDate) _DateSeparator(date: message.timestamp),
            _ModernMessageBubble(
              message: message,
              theme: theme,
              onOpenAttachment: _openAttachment,
            ),
          ],
        );
      },
    );
  }

  void _showMenuOptions() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _MenuTile(icon: Icons.delete_outline_rounded, title: l10n.chatClearConversation, onTap: () {
              Navigator.pop(sheetContext);
              _clearConversation();
            }, isDestructive: true),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _MenuTile(icon: Icons.photo_library_rounded, title: l10n.chatAttachmentGallery, onTap: () async {
              Navigator.pop(sheetContext);
              await _pickFromGallery();
            }),
            _MenuTile(icon: Icons.camera_alt_rounded, title: l10n.chatAttachmentCamera, onTap: () async {
              Navigator.pop(sheetContext);
              await _pickFromCamera();
            }),
            _MenuTile(icon: Icons.description_rounded, title: l10n.chatAttachmentDocument, onTap: () async {
              Navigator.pop(sheetContext);
              await _pickDocument();
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {}
  void _clearConversation() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.chatClearConfirmTitle),
        content: Text(l10n.chatClearConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () {
              setState(() => _messages.clear());
              widget.onUnreadCountChanged?.call(0);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.chatClearAction),
          ),
        ],
      ),
    );
  }
}

// ==================== APP BAR ====================

class _ModernChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ModernChatAppBar({
    required this.onMenuTap,
    this.equipeSubtitle,
  });

  final VoidCallback onMenuTap;
  final String? equipeSubtitle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String statusLine = (equipeSubtitle != null && equipeSubtitle!.trim().isNotEmpty)
        ? '${equipeSubtitle!.trim()} · ${l10n.chatOnline}'
        : l10n.chatOnline;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE8EEF9),
                child: Icon(Icons.admin_panel_settings_rounded, size: 22, color: Color(0xFF2F5AA8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chatAdmin,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusLine,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: onMenuTap),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

// ==================== DATE SEPARATOR ====================

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String localeName = locale.languageCode == 'ar'
        ? 'ar'
        : locale.languageCode == 'en'
            ? 'en'
            : 'fr_FR';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormat('EEEE d MMMM', localeName).format(date),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// ==================== MESSAGE BUBBLE ====================

class _ModernMessageBubble extends StatelessWidget {
  const _ModernMessageBubble({
    required this.message,
    required this.theme,
    required this.onOpenAttachment,
  });
  final ChatMessage message;
  final ThemeData theme;
  final Future<void> Function(ChatAttachment) onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isFromUser = message.isFromUser;
    final Color bubbleColor = isFromUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final Color textColor = isFromUser ? Colors.white : theme.colorScheme.onSurface;
    final String senderLabel =
        isFromUser ? l10n.chatSenderMe : (message.sender == 'support' ? l10n.chatAdmin : message.sender);

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isFromUser ? 0 : 12, right: isFromUser ? 12 : 0, bottom: 4),
              child: isFromUser
                  ? Text(
                      '${l10n.chatMessageQuestion} · ${l10n.chatSenderMe}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.chatMessageAnswer,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        Text(' · ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        Flexible(
                          child: Text(
                            senderLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isFromUser ? 20 : 4),
                  bottomRight: Radius.circular(isFromUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (_shouldShowMessageBodyText(message))
                    Text(message.text, style: TextStyle(color: textColor, fontSize: 15)),
                  if (message.attachments.isNotEmpty) ...[
                    if (_shouldShowMessageBodyText(message)) const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.attachments
                          .map(
                            (ChatAttachment a) => _AttachmentTile(
                              attachment: a,
                              isFromUser: isFromUser,
                              onOpen: () {
                                onOpenAttachment(a);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(_formatTime(message.timestamp), style: TextStyle(fontSize: 10, color: isFromUser ? Colors.white70 : Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.isFromUser,
    required this.onOpen,
  });
  final ChatAttachment attachment;
  final bool isFromUser;
  final VoidCallback onOpen;

  bool get _isImage =>
      attachment.kind == 'image' ||
      attachment.mime.startsWith('image/') ||
      _looksLikeImageFile(attachment.name, attachment.url);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: _isImage ? _buildImagePreview() : _buildDocumentTile(),
      ),
    );
  }

  Widget _buildImagePreview() {
    final String? local = attachment.localPath;
    if (local != null && local.isNotEmpty) {
      final File f = File(local);
      if (f.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            f,
            height: 120,
            width: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildImageErrorPlaceholder(),
          ),
        );
      }
    }
    final String url = attachment.url;
    if (url.isEmpty) {
      return _buildImageErrorPlaceholder();
    }
    final Map<String, String>? headers = _chatImageRequestHeaders(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 120,
        width: 150,
        fit: BoxFit.cover,
        headers: headers,
        errorBuilder: (_, __, ___) => _buildImageErrorPlaceholder(),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 120,
      width: 150,
      decoration: BoxDecoration(
        color: isFromUser ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: 40,
        color: isFromUser ? Colors.white54 : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildDocumentTile() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFromUser ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, size: 18, color: isFromUser ? Colors.white70 : Colors.grey.shade700),
          const SizedBox(width: 8),
          Flexible(child: Text(attachment.name, style: TextStyle(color: isFromUser ? Colors.white70 : null))),
          Icon(Icons.open_in_new_rounded, size: 16, color: isFromUser ? Colors.white54 : Colors.grey.shade600),
        ],
      ),
    );
  }
}

// ==================== TYPING INDICATOR ====================

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.animationController});
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) => AnimatedBuilder(
                animation: animationController,
                builder: (context, _) {
                  final double value =
                      sin(animationController.value * 2 * pi + index);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6.0 + value * 2,
                    height: 6.0 + value * 2,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              )),
            ),
          ),
          const SizedBox(width: 8),
          const Text("L'administrateur écrit...", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ==================== MESSAGE INPUT ====================

class _ModernMessageInput extends StatelessWidget {
  const _ModernMessageInput({
    required this.messageController,
    required this.isSending,
    required this.pendingAttachment,
    required this.onSend,
    required this.onClearAttachment,
    required this.onAttach,
    required this.onEmoji,
  });

  final TextEditingController messageController;
  final bool isSending;
  final PendingAttachment? pendingAttachment;
  final VoidCallback onSend;
  final VoidCallback onClearAttachment;
  final VoidCallback onAttach;
  final VoidCallback onEmoji;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingAttachment != null)
              _AttachmentPreview(
                attachment: pendingAttachment!,
                onClear: onClearAttachment,
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: isSending ? null : onAttach,
                  color: theme.colorScheme.primary,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: messageController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        hintText: pendingAttachment == null ? 'Écrivez un message...' : 'Ajoutez un message (optionnel)...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: isSending ? null : onEmoji,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(isSending: isSending, onSend: onSend),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment, required this.onClear});
  final PendingAttachment attachment;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (attachment.kind == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(attachment.path), width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => 
                Icon(Icons.image_rounded, color: Theme.of(context).colorScheme.primary)),
            )
          else
            Icon(Icons.insert_drive_file_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(attachment.name, overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClear, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onSend});
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer]),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: isSending
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, color: Colors.white),
        onPressed: isSending ? null : onSend,
      ),
    );
  }
}

// ==================== MENU TILE ====================

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap, this.isDestructive = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
    );
  }
}

// ==================== LOADING & ERROR STATES ====================

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.errorMessage, required this.onRetry});
  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: TextStyle(fontSize: 12, color: Colors.red.shade800))),
        ],
      ),
    );
  }
}

// ==================== DATA MODELS ====================

class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final String sender;
  final DateTime timestamp;
  final List<ChatAttachment> attachments;

  ChatMessage({
    this.id = '',
    required this.text,
    required this.isFromUser,
    required this.sender,
    required this.timestamp,
    this.attachments = const [],
  });
}

class ChatAttachment {
  final String kind;
  final String name;
  final String mime;
  final int size;
  final String url;

  /// Fichier local (aperçu juste après envoi depuis la galerie / l’appareil photo).
  final String? localPath;

  const ChatAttachment({
    required this.kind,
    required this.name,
    required this.mime,
    required this.size,
    required this.url,
    this.localPath,
  });
}

class PendingAttachment {
  final String path;
  final String name;
  final String kind;

  const PendingAttachment({
    required this.path,
    required this.name,
    required this.kind,
  });
}