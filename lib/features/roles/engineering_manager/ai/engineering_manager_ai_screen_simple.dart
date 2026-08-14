// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:runrate/features/roles/engineering_manager/ai/engineering_manager_aistate.dart';
// import 'engineering_manager_ai_cubit.dart';
// import '../../../../core/constants/app_spacing.dart';
// import '../../../../core/theme/app_colors.dart';

// /// Simple Engineering Manager AI Screen - working version
// class EngineeringManagerAiScreen extends StatelessWidget {
//   const EngineeringManagerAiScreen({super.key, this.userName = 'Priya'});

//   final String userName;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Copilot'),
//       ),
//       body: BlocBuilder<EngineeringManagerAiCubit, EngineeringManagerAiState>(
//         builder: (context, state) {
//           if (state is EngineeringManagerAiInitial) {
//             return Center(
//               child: ElevatedButton(
//                 onPressed: () =>
//                     context.read<EngineeringManagerAiCubit>().loadInsights(),
//                 child: const Text('Load'),
//               ),
//             );
//           }
//           if (state is EngineeringManagerAiLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (state is EngineeringManagerAiError) {
//             return Center(child: Text('Error: ${state.message}'));
//           }
//           if (state is EngineeringManagerAiLoaded) {
//             final data = state.data;
//             return Column(
//               children: [
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: data.messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = data.messages[index];
//                       return Align(
//                         alignment: msg.isFromUser
//                             ? Alignment.centerRight
//                             : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.all(AppSpacing.sm),
//                           padding: const EdgeInsets.all(AppSpacing.md),
//                           decoration: BoxDecoration(
//                             color: msg.isFromUser
//                                 ? AppColors.primary
//                                 : Colors.grey[300],
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             msg.text,
//                             style: TextStyle(
//                               color:
//                                   msg.isFromUser ? Colors.white : Colors.black,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 if (data.isAiTyping)
//                   const Padding(
//                     padding: EdgeInsets.all(AppSpacing.md),
//                     child: Text('AI is typing...'),
//                   ),
//                 _InputBar(onSend: (text) {
//                   context.read<EngineeringManagerAiCubit>().sendMessage(text);
//                 }),
//               ],
//             );
//           }
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
// }

// class _InputBar extends StatefulWidget {
//   const _InputBar({required this.onSend});
//   final Function(String) onSend;

//   @override
//   State<_InputBar> createState() => __InputBarState();
// }

// class __InputBarState extends State<_InputBar> {
//   final _controller = TextEditingController();

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(AppSpacing.md),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _controller,
//               decoration: InputDecoration(
//                 hintText: 'Ask me something...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           ElevatedButton(
//             onPressed: () {
//               if (_controller.text.isNotEmpty) {
//                 widget.onSend(_controller.text);
//                 _controller.clear();
//               }
//             },
//             child: const Icon(Icons.send),
//           ),
//         ],
//       ),
//     );
//   }
// }
