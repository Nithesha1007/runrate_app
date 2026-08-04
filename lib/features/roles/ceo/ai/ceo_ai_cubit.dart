import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import '../../../../shared/models/chat_message_model.dart';
import 'ceo_ai_state.dart';

class CeoAiCubit extends Cubit<CeoAiState> {
  final CeoMockRepository _repo;
  CeoAiCubit(this._repo)
      : super(CeoAiState(messages: [
          ChatMessageModel(
            id: 'welcome',
            text:
                "Hi Jordan — I'm your AI Spend Copilot. Ask me about any department, "
                "vendor, or upcoming renewal.",
            fromUser: false,
            sentAt: DateTime.now(),
          ),
        ])) {
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final insights = await _repo.fetchInsights();
    emit(state.copyWith(insights: insights, insightsLoading: false));
  }

  void setView(int index) => emit(state.copyWith(viewIndex: index));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      fromUser: true,
      sentAt: DateTime.now(),
    );
    emit(state
        .copyWith(messages: [...state.messages, userMessage], isTyping: true));
    final reply = await _repo.sendChatMessage(text);
    emit(state.copyWith(messages: [...state.messages, reply], isTyping: false));
  }
}
