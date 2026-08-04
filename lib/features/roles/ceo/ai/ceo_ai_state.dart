import 'package:equatable/equatable.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/models/insight_model.dart';

class CeoAiState extends Equatable {
  final int viewIndex; // 0 = chat, 1 = insights
  final List<ChatMessageModel> messages;
  final bool isTyping;
  final List<InsightModel> insights;
  final bool insightsLoading;

  const CeoAiState({
    this.viewIndex = 0,
    this.messages = const [],
    this.isTyping = false,
    this.insights = const [],
    this.insightsLoading = true,
  });

  CeoAiState copyWith({
    int? viewIndex,
    List<ChatMessageModel>? messages,
    bool? isTyping,
    List<InsightModel>? insights,
    bool? insightsLoading,
  }) {
    return CeoAiState(
      viewIndex: viewIndex ?? this.viewIndex,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      insights: insights ?? this.insights,
      insightsLoading: insightsLoading ?? this.insightsLoading,
    );
  }

  @override
  List<Object?> get props => [viewIndex, messages, isTyping, insights, insightsLoading];
}
